//
//  GradientBackground.swift
//  DioramaEscapeRoom
//
//  Created by Derend Marvel Hanson Prionggo on 19/06/25.
//

import SwiftUI

struct GradientBackground: View {
    @State private var animate = false
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [Color(hex: "00D4DF"), Color(hex: "044948")]),
            startPoint: animate ? .topLeading : .bottomLeading,
            endPoint: animate ? .bottomTrailing  : .bottomTrailing
        )
        .ignoresSafeArea()
        .animation(
            Animation.easeInOut(duration: 1.0)
                .repeatForever(autoreverses: true),
            value: animate
        )
        .onAppear {
            animate = true
        }
        
    }
}

#Preview {
    GradientBackground()
}
