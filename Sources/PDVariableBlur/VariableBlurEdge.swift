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
