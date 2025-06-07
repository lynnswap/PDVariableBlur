//
//  ContentView.swift
//  PDVariableBlur
//
//  Created by lynnswap on 2025/06/07.
//
#if canImport(SwiftUI) && DEBUG
import SwiftUI

#Preview{
    ZStack{
        Rectangle()
            .fill(.white)
            .frame(width: 20)
            .ignoresSafeArea()
        VStack{
            Color.clear
                .frame(height: 200)
                .variableBlur(radius: 60,
                               edge: .top,
                               length: 200,
                               tint: Color.indigo)
            Spacer()
            Color.clear
                .frame(height: 150)
                .variableBlur(edge: .bottom,
                               length: 150,
                               tint: Color.blue)
        }
    }
    .background(.black)
    .ignoresSafeArea()
    #if os(macOS)
    .frame(width:400,height:600)
    #endif
}

#endif
