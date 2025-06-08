#if canImport(UIKit)
import UIKit
import SwiftUI

public struct VariableBlurView: UIViewRepresentable {
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
            tint: tint.map { UIColor($0) },
            tintOpacity: tintOpacity
        )
    }

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
import AppKit
import SwiftUI

public struct VariableBlurView: NSViewRepresentable {
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
            tintOpacity: tintOpacity
        )
    }

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
