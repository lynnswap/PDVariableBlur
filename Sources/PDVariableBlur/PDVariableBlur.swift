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



public struct VariableBlurView: UIViewRepresentable {
    public var radius: CGFloat = 20
    public var edge: VariableBlurEdge = .top
    public var offset: CGFloat = 0
    public var tint: UIColor?
    public var tintOpacity: CGFloat?

    public init(
        radius: CGFloat = 20,
        edge: VariableBlurEdge = .top,
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
        edge: VariableBlurEdge = .top,
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
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(
            radius: radius,
            edge: edge,
            offset: offset,
            tint: tint,
            tintOpacity: tintOpacity
        )
    }

    public func makeUIView(context: Context) -> VariableBlurUIView {
        VariableBlurUIView(
            radius: radius,
            edge: edge,
            offset: offset,
            tint: tint,
            tintOpacity: tintOpacity
        )
    }

    public func updateUIView(_ uiView: VariableBlurUIView, context: Context) {
        context.coordinator.applyChanges(
            to: uiView,
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
        private var tint: UIColor?
        private var tintOpacity: CGFloat?

        init(radius: CGFloat, edge: VariableBlurEdge, offset: CGFloat, tint: UIColor?, tintOpacity: CGFloat?) {
            self.radius = radius
            self.edge = edge
            self.offset = offset
            self.tint = tint
            self.tintOpacity = tintOpacity
        }

        func applyChanges(to view: VariableBlurUIView, radius: CGFloat, edge: VariableBlurEdge, offset: CGFloat, tint: UIColor?, tintOpacity: CGFloat?) {
            if self.radius != radius {
                self.radius = radius
                view.radius = radius
            }
            if self.edge != edge {
                self.edge = edge
                view.edge = edge
            }
            if self.offset != offset {
                self.offset = offset
                view.offset = offset
            }
            if self.tint != tint {
                self.tint = tint
                view.bluredTintColor = tint
            }
            if self.tintOpacity != tintOpacity {
                self.tintOpacity = tintOpacity
                view.tintOpacity = tintOpacity
            }
        }
    }
}

open class VariableBlurUIView: UIVisualEffectView {

    // MARK: - Public Stored Properties
    public var radius: CGFloat { didSet { refresh() } }
    public var edge: VariableBlurEdge { didSet { refresh() } }
    public var offset: CGFloat { didSet { refresh() } }
    public var bluredTintColor: UIColor? { didSet { refresh() } }

    // MARK: - Private
    private var gradientLayer: CAGradientLayer?
    public var tintOpacity: CGFloat? { didSet { refresh() } }

    // MARK: - Init
    public init(
        radius: CGFloat = 20,
        edge: VariableBlurEdge = .top,
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
        edge: VariableBlurEdge = .top,
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

