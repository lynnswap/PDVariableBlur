#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
import SwiftUI

public struct VariableBlurView {
    public var radius: CGFloat = 20
    public var edge: VariableBlurEdge = .top
    public var offset: CGFloat = 0
    public var tint: BlurColor?
    public var tintOpacity: CGFloat?

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
            tint: tint.map { BlurColor($0) },
            tintOpacity: tintOpacity
        )
    }
}

#if canImport(UIKit)
extension VariableBlurView: UIViewRepresentable {
    public func makeUIView(context: Context) -> VariableBlurEffectView {
        VariableBlurEffectView(
            radius: radius,
            edge: edge,
            offset: offset,
            tint: tint,
            tintOpacity: tintOpacity
        )
    }

    public func updateUIView(_ uiView: VariableBlurEffectView, context: Context) {
        uiView.update(
            radius: radius,
            edge: edge,
            offset: offset,
            tint: tint,
            tintOpacity: tintOpacity
        )
    }
}
#elseif canImport(AppKit)
extension VariableBlurView: NSViewRepresentable {
    public func makeNSView(context: Context) -> VariableBlurEffectView {
        VariableBlurEffectView(
            radius: radius,
            edge: edge,
            offset: offset,
            tint: tint,
            tintOpacity: tintOpacity
        )
    }

    public func updateNSView(_ nsView: VariableBlurEffectView, context: Context) {
        nsView.update(
            radius: radius,
            edge: edge,
            offset: offset,
            tint: tint,
            tintOpacity: tintOpacity
        )
    }
}
#endif
