#if canImport(UIKit)
import UIKit
public typealias BlurViewBase = UIVisualEffectView
public typealias BlurColor = UIColor
#elseif canImport(AppKit)
import AppKit
public typealias BlurViewBase = NSView
public typealias BlurColor = NSColor
#endif
import SwiftUI
import QuartzCore
import CoreImage.CIFilterBuiltins

open class VariableBlurEffectView: BlurViewBase {
    private var radius: CGFloat
    private var edge: VariableBlurEdge
    private var offset: CGFloat
    private var bluredTintColor: BlurColor?
    private var tintOpacity: CGFloat?

#if canImport(AppKit)
    private let containerLayer = CALayer()
    private let backdropLayer: CALayer
    private var cachedScale: CGFloat?
#endif
    private var gradientLayer: CAGradientLayer?

    // MARK: Init
    public init(
        radius: CGFloat = 20,
        edge: VariableBlurEdge,
        offset: CGFloat = 0,
        tint: BlurColor? = nil,
        tintOpacity: CGFloat? = nil
    ) {
        self.radius = radius
        self.edge = edge
        self.offset = offset
        self.bluredTintColor = tint
        self.tintOpacity = tintOpacity
#if canImport(UIKit)
        super.init(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        isUserInteractionEnabled = false
#else
        if let BackdropLayerClass = NSClassFromString("CABackdropLayer") as? CALayer.Type {
            backdropLayer = BackdropLayerClass.init()
        } else {
            backdropLayer = CALayer()
        }
        super.init(frame: .zero)
        wantsLayer = true
        layerUsesCoreImageFilters = true
        containerLayer.frame = bounds
        containerLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        layer = containerLayer
        backdropLayer.frame = bounds
        backdropLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        containerLayer.addSublayer(backdropLayer)
#endif
        applyVariableBlur()
        applyTintGradientIfNeeded()
    }

    public convenience init(
        radius: CGFloat = 20,
        edge: VariableBlurEdge,
        offset: CGFloat = 0,
        tint: Color?,
        tintOpacity: CGFloat? = nil
    ) {
#if canImport(UIKit)
        self.init(
            radius: radius,
            edge: edge,
            offset: offset,
            tint: tint.map { UIColor($0) },
            tintOpacity: tintOpacity
        )
#else
        self.init(
            radius: radius,
            edge: edge,
            offset: offset,
            tint: tint.map { NSColor($0) },
            tintOpacity: tintOpacity
        )
#endif
    }

    @available(*, unavailable)
    required public init?(coder: NSCoder) { fatalError() }

#if canImport(UIKit)
    open override func layoutSubviews() {
        super.layoutSubviews()
        layoutUpdate()
    }

    open override func didMoveToWindow() {
        super.didMoveToWindow()
        guard let window, let layer = targetLayer else { return }
        layer.setValue(window.screen.scale, forKey: "scale")
    }
#else
    open override func layout() {
        super.layout()
        layoutUpdate()
    }

    open override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let window else { return }
        let windowScale = window.backingScaleFactor
        backdropLayer.setValue(windowScale, forKey: "scale")
        cachedScale = windowScale
    }

    open override func viewDidChangeBackingProperties() {
        super.viewDidChangeBackingProperties()
        guard let window else { return }
        let windowScale = window.backingScaleFactor
        if cachedScale == windowScale { return }
        backdropLayer.setValue(windowScale, forKey: "scale")
        cachedScale = windowScale
    }
#endif

    // MARK: - Updates
    public func update(
        radius: CGFloat? = nil,
        edge: VariableBlurEdge? = nil,
        offset: CGFloat? = nil,
        tint: BlurColor? = nil,
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

    // MARK: - Public
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

    // MARK: - Layout Helpers
    private func layoutUpdate() {
#if canImport(AppKit)
        backdropLayer.frame = bounds
#endif
        gradientLayer?.frame = bounds
    }

    // MARK: - Variable Blur
    private func applyVariableBlur() {
        guard
            let CAFilter = NSClassFromString("CAFilter") as? NSObject.Type,
            let variableBlur = CAFilter.perform(NSSelectorFromString("filterWithType:"), with: "variableBlur")?.takeUnretainedValue() as? NSObject
        else { return }

        variableBlur.setValue(radius, forKey: "inputRadius")
        variableBlur.setValue(edge.gradientMaskImage(offset: offset), forKey: "inputMaskImage")
        variableBlur.setValue(true, forKey: "inputNormalizeEdges")

        targetLayer?.filters = [variableBlur]
    }

    // MARK: - Tint Gradient
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

        gradientContainer.addSublayer(layer)
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

#if canImport(UIKit)
    private var targetLayer: CALayer? { subviews.first?.layer }
    private var gradientContainer: CALayer { contentView.layer }
#else
    private var targetLayer: CALayer? { backdropLayer }
    private var gradientContainer: CALayer { containerLayer }
#endif
}
