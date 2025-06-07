#if canImport(SwiftUI)
import SwiftUI

public extension VariableBlurEdge {
    /// Alignment used for overlay when applying `variableBlur` modifier.
    var overlayAlignment: Alignment {
        switch self {
        case .top:      return .top
        case .bottom:   return .bottom
        case .leading:  return .leading
        case .trailing: return .trailing
        }
    }

    /// Indicates whether the blur runs vertically.
    var isVertical: Bool {
        switch self {
        case .top, .bottom:
            return true
        case .leading, .trailing:
            return false
        }
    }
}

public extension View {
    /// Applies a variable blur effect as an overlay.
    func variableBlur(
        radius: CGFloat = 20,
        edge: VariableBlurEdge = .top,
        length: CGFloat,
        offset: CGFloat = 0,
        tint: Color? = nil,
        tintOpacity: CGFloat? = nil
    ) -> some View {
        overlay(alignment: edge.overlayAlignment) {
            VariableBlurView(
                radius: radius,
                edge: edge,
                offset: offset,
                tint: tint,
                tintOpacity: tintOpacity
            )
            .frame(
                width: edge.isVertical ? nil : length,
                height: edge.isVertical ? length : nil
            )
        }
    }
}

#endif
