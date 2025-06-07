//
//  ContentView.swift
//  PDVariableBlur
//
//  Created by lynnswap on 2025/06/07.
//
#if DEBUG
import SwiftUI

#Preview{
    ZStack{
        Color.black
        Rectangle()
            .fill(.white)
            .frame(width: 20)
    }
    .variableBlur(
        radius: 60,
        edge: .top,
        length: 200,
        tint: .indigo
    )
    .variableBlur(
        edge: .bottom,
        length: 150,
        tint: .blue
    )
    .ignoresSafeArea()
#if os(macOS)
    .frame(width:400,height:600)
#endif
}

#endif
