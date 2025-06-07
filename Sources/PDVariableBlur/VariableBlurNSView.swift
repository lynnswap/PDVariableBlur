//
//  VariableBlurNSView.swift
//  PDVariableBlur
//
//  Created by lynnswap on 2025/06/07.
//

#if canImport(AppKit)
import AppKit
import CoreImage.CIFilterBuiltins
import SwiftUI

public struct VariableBlurView: NSViewRepresentable {
    public var radius: CGFloat = 20
    public var edge: VariableBlurEdge = .top
    public var offset: CGFloat = 0
    public var tint: NSColor?
    public var tintOpacity: CGFloat?

    public init(
        radius: CGFloat = 20,
        edge: VariableBlurEdge = .top,
        offset: CGFloat = 0,
        tint: NSColor? = nil,
        tintOpacity: CGFloat? = nil
    ) {
        self.radius = radius
        self.edge = edge
        self.offset = offset
        self.tint = tint
        self.tintOpacity = tintOpacity
    }

    public init(
        radius: CGFloat = 20,
        edge: VariableBlurEdge = .top,
        offset: CGFloat = 0,
        tint: Color?,
        tintOpacity: CGFloat? = nil
    ) {
        self.init(
            radius: radius,
            edge: edge,
            offset: offset,
            tint: tint.map { NSColor($0) },
            tintOpacity: tintOpacity)
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(
            radius: radius,
            edge: edge,
            offset: offset,
            tint: tint,
            tintOpacity: tintOpacity
        )
    }

    public func makeNSView(context: Context) -> VariableBlurNSView {
        VariableBlurNSView(
            radius: radius,
            edge: edge,
            offset: offset,
            tint: tint,
            tintOpacity: tintOpacity
        )
    }

    public func updateNSView(_ nsView: VariableBlurNSView, context: Context) {
        context.coordinator.applyChanges(
            to: nsView,
            radius: radius,
            edge: edge,
            offset: offset,
            tint: tint,
            tintOpacity: tintOpacity
        )
    }

    public class Coordinator {
        private var radius: CGFloat
        private var edge: VariableBlurEdge
        private var offset: CGFloat
        private var tint: NSColor?
        private var tintOpacity: CGFloat?

        init(radius: CGFloat, edge: VariableBlurEdge, offset: CGFloat, tint: NSColor?, tintOpacity: CGFloat?) {
            self.radius = radius
            self.edge = edge
            self.offset = offset
            self.tint = tint
            self.tintOpacity = tintOpacity
        }

        func applyChanges(to view: VariableBlurNSView, radius: CGFloat, edge: VariableBlurEdge, offset: CGFloat, tint: NSColor?, tintOpacity: CGFloat?) {
            view.isBatchUpdating = true
            var changed = false
            if self.radius != radius {
                self.radius = radius
                view.radius = radius
                changed = true
            }
            if self.edge != edge {
                self.edge = edge
                view.edge = edge
                changed = true
            }
            if self.offset != offset {
                self.offset = offset
                view.offset = offset
                changed = true
            }
            if self.tint != tint {
                self.tint = tint
                view.bluredTintColor = tint
                changed = true
            }
            if self.tintOpacity != tintOpacity {
                self.tintOpacity = tintOpacity
                view.tintOpacity = tintOpacity
                changed = true
            }
            view.isBatchUpdating = false
            if changed {
                view.refresh()
            }
        }
    }
}

open class VariableBlurNSView: NSView {

    // MARK: Public Stored Properties
    public var radius: CGFloat { didSet { if !isBatchUpdating { refresh() } } }
    public var edge: VariableBlurEdge { didSet { if !isBatchUpdating { refresh() } } }
    public var offset: CGFloat { didSet { if !isBatchUpdating { refresh() } } }
    public var bluredTintColor: NSColor? { didSet { if !isBatchUpdating { refresh() } } }

    // MARK: Private
    private let containerLayer = CALayer()
    private let backdropLayer : CALayer
    private var gradientLayer : CAGradientLayer?
    var isBatchUpdating = false
    public  var tintOpacity: CGFloat? { didSet { if !isBatchUpdating { refresh() } } }

    // MARK: Init ---------------------------------------------------------
    public init(
        radius: CGFloat = 20,
        edge: VariableBlurEdge = .top,
        offset: CGFloat = 0,
        tint: NSColor? = nil,
        tintOpacity: CGFloat? = nil
    ) {
        self.radius = radius
        self.edge = edge
        self.offset = offset
        self.bluredTintColor = tint
        self.tintOpacity = tintOpacity

        if let BackdropLayerClass = NSClassFromString("CABackdropLayer") as? CALayer.Type {
            backdropLayer = BackdropLayerClass.init()
        } else {
            backdropLayer = CALayer()
        }

        super.init(frame: .zero)

        wantsLayer               = true
        layerUsesCoreImageFilters = true

        // containerLayer をルートにしてフィルタから隔離 ------------------
        containerLayer.frame = bounds
        containerLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        layer = containerLayer

        // variableBlur を掛けるターゲットは backdropLayer ---------------
        backdropLayer.frame = bounds
        backdropLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        containerLayer.addSublayer(backdropLayer)

        applyVariableBlur()
        applyTintGradientIfNeeded()
    }

    @available(*, unavailable)
    required public init?(coder: NSCoder) { fatalError() }

    // MARK: Layout -------------------------------------------------------
    open override func layout() {
        super.layout()
        backdropLayer.frame = bounds
        gradientLayer?.frame = bounds
    }

    open override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let window else { return }
        backdropLayer.setValue(window.backingScaleFactor, forKey: "scale")
    }

    // MARK: Public
    public func refresh() {
        applyVariableBlur()
        if bluredTintColor == nil {
            gradientLayer?.removeFromSuperlayer()
            gradientLayer = nil
        } else {
            if gradientLayer == nil {
                applyTintGradientIfNeeded()
            } else {
                updateTintGradient()
            }
        }
    }

    // MARK: Variable-blur -----------------------------------------------
    private func applyVariableBlur() {
        guard let CAFilter = NSClassFromString("CAFilter") as? NSObject.Type,
              let variableBlur  = CAFilter.perform(NSSelectorFromString("filterWithType:"),with: "variableBlur")?.takeUnretainedValue() as? NSObject else {
            return
        }

        variableBlur.setValue(radius, forKey: "inputRadius")
        variableBlur.setValue(edge.gradientMaskImage(offset: offset), forKey: "inputMaskImage")
        variableBlur.setValue(true, forKey: "inputNormalizeEdges")

        backdropLayer.filters = [variableBlur]
    }

    // MARK: Tint Gradient -----------------------------------------------
    private func applyTintGradientIfNeeded() {
        guard let tint = bluredTintColor else { return }

        let startAlpha = tintOpacity ?? tint.cgColor.alpha
        let layer = CAGradientLayer()
        layer.frame = bounds
        layer.colors = [
            tint.withAlphaComponent(startAlpha).cgColor,
            tint.withAlphaComponent(0).cgColor
        ]
        let points = edge.gradientPoints
        layer.startPoint = points.start
        layer.endPoint   = points.end
        layer.locations = [0, NSNumber(value: 1 - Float(offset))]

        containerLayer.addSublayer(layer)
        gradientLayer = layer
    }

    private func updateTintGradient() {
        guard let layer = gradientLayer, let tint = bluredTintColor else { return }
        let startAlpha = tintOpacity ?? tint.cgColor.alpha
        layer.colors = [
            tint.withAlphaComponent(startAlpha).cgColor,
            tint.withAlphaComponent(0).cgColor
        ]
        let points = edge.gradientPoints
        layer.startPoint = points.start
        layer.endPoint   = points.end
        layer.locations = [0, NSNumber(value: 1 - Float(offset))]
    }
    
}

#endif
