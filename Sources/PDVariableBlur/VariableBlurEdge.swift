//
//  VariableBlurEdge.swift
//  PDVariableBlur
//
//  Created by lynnswap on 2025/06/07.
//

import Foundation

/// Specifies from which edge the blur effect starts.
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

#if canImport(QuartzCore) && canImport(CoreImage)
import QuartzCore
import CoreImage.CIFilterBuiltins

extension VariableBlurEdge {
    /// Gradient start and end points for `CAGradientLayer`.
    /// Coordinates differ between platforms.
    var gradientPoints: (start: CGPoint, end: CGPoint) {
        #if os(macOS)
        switch self {
        case .top:      return (CGPoint(x: 0.5, y: 1.0), CGPoint(x: 0.5, y: 0.0))
        case .bottom:   return (CGPoint(x: 0.5, y: 0.0), CGPoint(x: 0.5, y: 1.0))
        case .trailing: return (CGPoint(x: 1.0, y: 0.5), CGPoint(x: 0.0, y: 0.5))
        case .leading:  return (CGPoint(x: 0.0, y: 0.5), CGPoint(x: 1.0, y: 0.5))
        }
        #else
        switch self {
        case .top:      return (CGPoint(x: 0.5, y: 0.0), CGPoint(x: 0.5, y: 1.0))
        case .bottom:   return (CGPoint(x: 0.5, y: 1.0), CGPoint(x: 0.5, y: 0.0))
        case .trailing: return (CGPoint(x: 1.0, y: 0.5), CGPoint(x: 0.0, y: 0.5))
        case .leading:  return (CGPoint(x: 0.0, y: 0.5), CGPoint(x: 1.0, y: 0.5))
        }
        #endif
    }

    /// Generates a mask image for the variable blur filter.
    func gradientMaskImage(width: CGFloat = 100, height: CGFloat = 100, offset: CGFloat) -> CGImage {
        let filter = CIFilter.linearGradient()
        filter.color0 = CIColor.black
        filter.color1 = CIColor.clear

        switch self {
        case .top:
            filter.point0 = CGPoint(x: 0, y: height)
            filter.point1 = CGPoint(x: 0, y: offset * height)
        case .bottom:
            filter.point0 = CGPoint(x: 0, y: 0)
            filter.point1 = CGPoint(x: 0, y: height - offset * height)
        case .trailing:
            filter.point0 = CGPoint(x: width, y: 0)
            filter.point1 = CGPoint(x: offset * width, y: 0)
        case .leading:
            filter.point0 = CGPoint(x: 0, y: 0)
            filter.point1 = CGPoint(x: width - offset * width, y: 0)
        }

        let context = CIContext()
        let ciImage = filter.outputImage!
        return context.createCGImage(ciImage, from: CGRect(x: 0, y: 0, width: width, height: height))!
    }
}
#endif
