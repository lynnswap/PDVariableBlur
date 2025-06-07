//
//  PDVariableBlur.swift
//  PDVariableBlur
//
//  Created by lynnswap on 2025/05/05.
//

#if canImport(UIKit)
import UIKit
import CoreImage.CIFilterBuiltins
import QuartzCore
import SwiftUI

public struct VariableBlurViewRepresentable: UIViewRepresentable {
    public var radius: CGFloat = 20
    public var edge: VariableBlurEdge = .top
    public var offset: CGFloat = 0
    public var tint: UIColor?
    public var tintOpacity: CGFloat?

    public init(
        radius: CGFloat = 20,
        edge: VariableBlurEdge,
        offset: CGFloat = 0,
        tint: UIColor? = nil,
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
            tint: tint.map { UIColor($0)},
            tintOpacity: tintOpacity
        )
    }
    
    public func makeUIView(context: Context) -> VariableBlurView {
        VariableBlurView(
            radius: radius,
            edge: edge,
            offset: offset,
            tint: tint,
            tintOpacity: tintOpacity
        )
    }

    public func updateUIView(_ uiView: VariableBlurView, context: Context) {
        uiView.update(
            radius: radius,
            edge: edge,
            offset: offset,
            tint: tint,
            tintOpacity: tintOpacity
        )
    }
}

open class VariableBlurView: UIVisualEffectView {

    // MARK: - Public Stored Properties
    private var radius: CGFloat
    private var edge: VariableBlurEdge
    private var offset: CGFloat
    private var bluredTintColor: UIColor?

    // MARK: - Private
    private var gradientLayer: CAGradientLayer?
    private var tintOpacity: CGFloat?

    // MARK: - Init
    public init(
        radius: CGFloat = 20,
        edge: VariableBlurEdge,
        offset: CGFloat = 0,
        tint: UIColor? = nil,
        tintOpacity: CGFloat? = nil
    ) {
        self.radius = radius
        self.edge          = edge
        self.offset   = offset
        self.bluredTintColor     = tint
        self.tintOpacity    = tintOpacity
        super.init(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        isUserInteractionEnabled = false
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
        self.init(
            radius: radius,
            edge: edge,
            offset: offset,
            tint: tint.map { UIColor($0) },
            tintOpacity: tintOpacity
        )
    }

    @available(*, unavailable) required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout Updates
    open override func layoutSubviews() {
        super.layoutSubviews()
        // 端末回転やサイズ変更に追従
        gradientLayer?.frame = bounds
    }

    open override func didMoveToWindow() {
        guard
            let window,
            let backdropLayer = subviews.first?.layer
        else { return }
        backdropLayer.setValue(window.screen.scale, forKey: "scale")
    }

    /// Updates multiple parameters at once and refreshes the view when needed.
    public func update(
        radius: CGFloat? = nil,
        edge: VariableBlurEdge? = nil,
        offset: CGFloat? = nil,
        tint: UIColor? = nil,
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

    // MARK: - Public: 手動更新用
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

    // MARK: - Variable-blur
    private func applyVariableBlur() {
        guard
            let CAFilter = NSClassFromString("CAFilter") as? NSObject.Type,
            let variableBlur = CAFilter.perform(NSSelectorFromString("filterWithType:"), with: "variableBlur")
                  .takeUnretainedValue() as? NSObject
        else { return }

        variableBlur.setValue(radius, forKey: "inputRadius")
        variableBlur.setValue(edge.gradientMaskImage(offset: offset), forKey: "inputMaskImage")
        variableBlur.setValue(true,           forKey: "inputNormalizeEdges")

        // UIVisualEffectView の一番下にある backdrop layer にフィルタを設定
        subviews.first?.layer.filters = [variableBlur]
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
        contentView.layer.addSublayer(layer)
        gradientLayer = layer
    }

    private func updateTintGradient() {
        guard let layer = gradientLayer, let tint = bluredTintColor else { return }
        let startAlpha = tintOpacity ?? tint.cgColor.alpha
        layer.colors   = [
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

