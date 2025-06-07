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
        Rectangle()
            .fill(.white)
            .frame(width: 20)
            .ignoresSafeArea()
        VStack{
            VariableBlurView(
                maxBlurRadius:60,
                edge: .top,
                tintColor: Color.indigo
            )
            .frame(height:200)
            Spacer()
            VariableBlurView(
                edge: .bottom,
                tintColor: Color.blue
            )
            .frame(height:150)
        }
    }
    .background(.black)
    .ignoresSafeArea()
    #if os(macOS)
    .frame(width:400,height:600)
    #endif
}

#endif
