//
//  PDVariableBlur.swift
//  PDVariableBlur
//
//  Created by lynnswap on 2025/05/05.
//


import SwiftUI
public enum VariableBlurEdge {
    /// Blur starts from the top edge and gradually clears toward the bottom.
    case top
    /// Blur starts from the bottom edge and gradually clears toward the top.
    case bottom
    /// Blur starts from the trailing edge and gradually clears toward the leading edge.
    case trailing
    /// Blur starts from the leading edge and gradually clears toward the trailing edge.
    case leading
}

#if canImport(UIKit)
import UIKit
import CoreImage.CIFilterBuiltins
import QuartzCore



public struct VariableBlurView: UIViewRepresentable {
    
    public var maxBlurRadius: CGFloat = 20
    
    public var edge: VariableBlurEdge = .top
    
    public var startOffset: CGFloat = 0
    
    public var tintColor: UIColor?
    public var tintStartOpacity: CGFloat?

    public init(maxBlurRadius: CGFloat = 20,
                edge: VariableBlurEdge = .top,
                startOffset: CGFloat = 0,
                tintColor: UIColor? = nil,
                tintStartOpacity: CGFloat? = nil) {
        self.maxBlurRadius      = maxBlurRadius
        self.edge               = edge
        self.startOffset        = startOffset
        self.tintColor          = tintColor
        self.tintStartOpacity   = tintStartOpacity
    }

    public init(maxBlurRadius: CGFloat = 20,
                edge: VariableBlurEdge = .top,
                startOffset: CGFloat = 0,
                tintColor: Color?,
                tintStartOpacity: CGFloat? = nil) {
        self.init(maxBlurRadius: maxBlurRadius,
                  edge: edge,
                  startOffset: startOffset,
                  tintColor: tintColor.map { UIColor($0) },
                  tintStartOpacity: tintStartOpacity)
    }
    
    public func makeUIView(context: Context) -> VariableBlurUIView {
        VariableBlurUIView(maxBlurRadius: maxBlurRadius,
                           edge: edge,
                           startOffset: startOffset,
                           tintColor: tintColor,
                           tintStartOpacity: tintStartOpacity)
    }
    
    public func updateUIView(_ uiView: VariableBlurUIView, context: Context) {
    }
}

open class VariableBlurUIView: UIVisualEffectView {

    // MARK: - Public Stored Properties
    public var maxBlurRadius: CGFloat          { didSet { refresh() } }
    public var edge:           VariableBlurEdge { didSet { refresh() } }
    /// 0.0〜1.0  (0 = 端から徐々にクリア、1 = ほぼ全域がブラー)
    public var startOffset:    CGFloat         { didSet { refresh() } }
    /// nil ならブラーのみ。色を指定すると同勾配でカラーオーバーレイを追加
    public var bluredTintColor:      UIColor?        { didSet { refresh() } }

    // MARK: - Private
    private var gradientLayer: CAGradientLayer?
    public var tintStartOpacity: CGFloat? { didSet { refresh() } }

    // MARK: - Init
    public init(maxBlurRadius: CGFloat = 20,
                edge: VariableBlurEdge = .top,
                startOffset: CGFloat = 0,
                tintColor: UIColor? = nil,
                tintStartOpacity: CGFloat? = nil) {
        self.maxBlurRadius = maxBlurRadius
        self.edge          = edge
        self.startOffset   = startOffset
        self.bluredTintColor     = tintColor
        self.tintStartOpacity    = tintStartOpacity
        super.init(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        isUserInteractionEnabled = false
        applyVariableBlur()
        applyTintGradientIfNeeded()
    }

    public convenience init(maxBlurRadius: CGFloat = 20,
                            edge: VariableBlurEdge = .top,
                            startOffset: CGFloat = 0,
                            tintColor: Color?,
                            tintStartOpacity: CGFloat? = nil) {
        self.init(maxBlurRadius: maxBlurRadius,
                  edge: edge,
                  startOffset: startOffset,
                  tintColor: tintColor.map { UIColor($0) },
                  tintStartOpacity: tintStartOpacity)
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
    /// 外部から変更後に自動で呼ばれる
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

        variableBlur.setValue(maxBlurRadius, forKey: "inputRadius")
        variableBlur.setValue(makeGradientImage(), forKey: "inputMaskImage")
        variableBlur.setValue(true,           forKey: "inputNormalizeEdges")

        // UIVisualEffectView の一番下にある backdrop layer にフィルタを設定
        subviews.first?.layer.filters = [variableBlur]
    }

    // MARK: - Tint Gradient
    private func applyTintGradientIfNeeded() {
        guard let tint = bluredTintColor else { return }
        
        let startAlpha = tintStartOpacity ?? tint.cgColor.alpha
        let layer      = CAGradientLayer()
        layer.frame    = bounds
        layer.colors   = [
            tint.withAlphaComponent(startAlpha).cgColor,
            tint.withAlphaComponent(0).cgColor
        ]
        setGradientPoints(for: layer)
        layer.locations = [0, NSNumber(value: 1 - Float(startOffset))]
        contentView.layer.addSublayer(layer)
        gradientLayer = layer
    }

    private func updateTintGradient() {
        guard let layer = gradientLayer, let tint = bluredTintColor else { return }
        let startAlpha = tintStartOpacity ?? tint.cgColor.alpha
        layer.colors   = [
            tint.withAlphaComponent(startAlpha).cgColor,
            tint.withAlphaComponent(0).cgColor
        ]
        setGradientPoints(for: layer)
        layer.locations = [0, NSNumber(value: 1 - Float(startOffset))]
    }

    private func setGradientPoints(for layer: CAGradientLayer) {
        switch edge {
        case .top:
            layer.startPoint = CGPoint(x: 0.5, y: 0.0)
            layer.endPoint   = CGPoint(x: 0.5, y: 1.0)
        case .bottom:
            layer.startPoint = CGPoint(x: 0.5, y: 1.0)
            layer.endPoint   = CGPoint(x: 0.5, y: 0.0)
        case .trailing:
            layer.startPoint = CGPoint(x: 1.0, y: 0.5)
            layer.endPoint   = CGPoint(x: 0.0, y: 0.5)
        case .leading:
            layer.startPoint = CGPoint(x: 0.0, y: 0.5)
            layer.endPoint   = CGPoint(x: 1.0, y: 0.5)
        }
    }

    // MARK: - Gradient Mask Image for CAFilter
    private func makeGradientImage(width: CGFloat = 100,
                                   height: CGFloat = 100) -> CGImage
    {
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
        return CIContext().createCGImage(ciImage,
                                         from: CGRect(x: 0, y: 0,
                                                      width: width,
                                                      height: height))!
    }
}

#endif

