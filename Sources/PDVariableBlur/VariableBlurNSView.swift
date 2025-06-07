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
    public var maxBlurRadius: CGFloat = 20
    public var edge: VariableBlurEdge = .top
    public var startOffset: CGFloat = 0
    public var tintColor: NSColor?
    public var tintStartOpacity: CGFloat?

    public init(
        maxBlurRadius: CGFloat = 20,
        edge: VariableBlurEdge = .top,
        startOffset: CGFloat = 0,
        tintColor: NSColor? = nil,
        tintStartOpacity: CGFloat? = nil
    ) {
        self.maxBlurRadius = maxBlurRadius
        self.edge = edge
        self.startOffset = startOffset
        self.tintColor = tintColor
        self.tintStartOpacity = tintStartOpacity
    }

    public init(
        maxBlurRadius: CGFloat = 20,
        edge: VariableBlurEdge = .top,
        startOffset: CGFloat = 0,
        tintColor: Color?,
        tintStartOpacity: CGFloat? = nil
    ) {
        self.init(
            maxBlurRadius: maxBlurRadius,
            edge: edge,
            startOffset: startOffset,
            tintColor: tintColor.map { NSColor($0) },
            tintStartOpacity: tintStartOpacity)
    }

    public func makeNSView(context: Context) -> VariableBlurNSView {
        VariableBlurNSView(
            maxBlurRadius: maxBlurRadius,
            edge: edge,
            startOffset: startOffset,
            tintColor: tintColor,
            tintStartOpacity: tintStartOpacity
        )
    }

    public func updateNSView(_ nsView: VariableBlurNSView, context: Context) {
    }
}

open class VariableBlurNSView: NSView {

    // MARK: Public Stored Properties
    public var maxBlurRadius: CGFloat { didSet { refresh() } }
    public var edge: VariableBlurEdge { didSet { refresh() } }
    public var startOffset: CGFloat { didSet { refresh() } }
    public var bluredTintColor: NSColor? { didSet { refresh() } }

    // MARK: Private
    private let containerLayer = CALayer()
    private let backdropLayer : CALayer
    private var gradientLayer : CAGradientLayer?
    public  var tintStartOpacity: CGFloat? { didSet { refresh() } }

    // MARK: Init ---------------------------------------------------------
    public init(
        maxBlurRadius: CGFloat = 20,
        edge: VariableBlurEdge = .top,
        startOffset: CGFloat = 0,
        tintColor: NSColor? = nil,
        tintStartOpacity: CGFloat? = nil
    ) {
        self.maxBlurRadius = maxBlurRadius
        self.edge = edge
        self.startOffset = startOffset
        self.bluredTintColor = tintColor
        self.tintStartOpacity = tintStartOpacity

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

        variableBlur.setValue(maxBlurRadius, forKey: "inputRadius")
        variableBlur.setValue(makeGradientImage(), forKey: "inputMaskImage")
        variableBlur.setValue(true, forKey: "inputNormalizeEdges")

        backdropLayer.filters = [variableBlur]
    }

    // MARK: Tint Gradient -----------------------------------------------
    private func applyTintGradientIfNeeded() {
        guard let tint = bluredTintColor else { return }

        let startAlpha = tintStartOpacity ?? tint.cgColor.alpha
        let layer = CAGradientLayer()
        layer.frame = bounds
        layer.colors = [
            tint.withAlphaComponent(startAlpha).cgColor,
            tint.withAlphaComponent(0).cgColor
        ]
        setGradientPoints(for: layer)
        layer.locations = [0, NSNumber(value: 1 - Float(startOffset))]

        containerLayer.addSublayer(layer)
        gradientLayer = layer
    }

    private func updateTintGradient() {
        guard let layer = gradientLayer, let tint = bluredTintColor else { return }
        let startAlpha = tintStartOpacity ?? tint.cgColor.alpha
        layer.colors = [
            tint.withAlphaComponent(startAlpha).cgColor,
            tint.withAlphaComponent(0).cgColor
        ]
        setGradientPoints(for: layer)
        layer.locations = [0, NSNumber(value: 1 - Float(startOffset))]
    }
    
    private func setGradientPoints(for layer: CAGradientLayer) {
        switch edge {
        case .top:
            layer.startPoint = CGPoint(x: 0.5, y: 1.0)
            layer.endPoint   = CGPoint(x: 0.5, y: 0.0)
        case .bottom:
            layer.startPoint = CGPoint(x: 0.5, y: 0.0)
            layer.endPoint   = CGPoint(x: 0.5, y: 1.0)
        case .trailing:
            layer.startPoint = CGPoint(x: 1.0, y: 0.5)
            layer.endPoint   = CGPoint(x: 0.0, y: 0.5)
        case .leading:
            layer.startPoint = CGPoint(x: 0.0, y: 0.5)
            layer.endPoint   = CGPoint(x: 1.0, y: 0.5)
        }
    }
    
    // MARK: - Gradient Mask Image for CAFilter
    private func makeGradientImage(
        width: CGFloat = 100,
        height: CGFloat = 100
    ) -> CGImage {
        let filter = CIFilter.linearGradient()
        filter.color0 = CIColor.black
        filter.color1 = CIColor.clear
        
        switch edge {
        case .top:
            filter.point0 = CGPoint(x: 0, y: height)
            filter.point1 = CGPoint(x: 0, y: startOffset * height)
        case .bottom:
            filter.point0 = CGPoint(x: 0, y: 0)
            filter.point1 = CGPoint(x: 0, y: height - startOffset * height)
        case .trailing:
            filter.point0 = CGPoint(x: width, y: 0)
            filter.point1 = CGPoint(x: startOffset * width, y: 0)
        case .leading:
            filter.point0 = CGPoint(x: 0, y: 0)
            filter.point1 = CGPoint(x: width - startOffset * width, y: 0)
        }
        
        let ciImage = filter.outputImage!
        return CIContext().createCGImage(ciImage, from: CGRect(x: 0, y: 0, width: width, height: height))!
    }
}

#endif
