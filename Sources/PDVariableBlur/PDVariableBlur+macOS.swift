//
//  VariableBlurView.swift
//  PDVariableBlur
//
//  Created by lynnswap on 2025/06/07.
//

#if canImport(AppKit)
import AppKit
import CoreImage.CIFilterBuiltins
import SwiftUI

public struct VariableBlurViewRepresentable: NSViewRepresentable {
    public var radius: CGFloat = 20
    public var edge: VariableBlurEdge = .top
    public var offset: CGFloat = 0
    public var tint: NSColor?
    public var tintOpacity: CGFloat?

    public init(
        radius: CGFloat = 20,
        edge: VariableBlurEdge,
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
        edge: VariableBlurEdge,
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

    public func makeNSView(context: Context) -> VariableBlurView {
        VariableBlurView(
            radius: radius,
            edge: edge,
            offset: offset,
            tint: tint,
            tintOpacity: tintOpacity
        )
    }

    public func updateNSView(_ nsView: VariableBlurView, context: Context) {
        nsView.update(
            radius: radius,
            edge: edge,
            offset: offset,
            tint: tint,
            tintOpacity: tintOpacity
        )
    }
}

open class VariableBlurView: NSView {

    private var radius: CGFloat
    private var edge: VariableBlurEdge
    private var offset: CGFloat
    private var bluredTintColor: NSColor?
    private var tintOpacity: CGFloat?

    private let containerLayer = CALayer()
    private let backdropLayer : CALayer
    private var gradientLayer : CAGradientLayer?

    // MARK: Init ---------------------------------------------------------
    public init(
        radius: CGFloat = 20,
        edge: VariableBlurEdge,
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

    /// Updates multiple parameters at once and refreshes the view when needed.
    public func update(
        radius: CGFloat? = nil,
        edge: VariableBlurEdge? = nil,
        offset: CGFloat? = nil,
        tint: NSColor? = nil,
        tintOpacity: CGFloat? = nil
    ) {
        var changed = false
        if let radius, self.radius != radius { self.radius = radius; changed = true }
        if let edge, self.edge != edge { self.edge = edge; changed = true }
        if let offset, self.offset != offset { self.offset = offset; changed = true }
        if let tint, self.bluredTintColor != tint { self.bluredTintColor = tint; changed = true }
        if let tintOpacity, self.tintOpacity != tintOpacity { self.tintOpacity = tintOpacity; changed = true }
        if changed { refresh() }
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
