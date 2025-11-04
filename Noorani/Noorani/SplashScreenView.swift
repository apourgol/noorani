//
//  SplashScreenView.swift
//  Noorani
//
//  Created by Amin Pourgol on 11/4/25.
//  Copyright © 2025 AP Bros. All rights reserved.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var opacity = 0.0

    var body: some View {
        if isActive {
            ContentView()
                .transition(.opacity)
        } else {
            ZStack {
                // App's signature gradient background
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color(hex: "#fab555"), location: 0.0),
                        .init(color: Color(hex: "#feecd3"), location: 0.55),
                        .init(color: Color.white, location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 16) {
                    // Logo
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)

                    // App name
                    Text("Noorani")
                        .font(.system(size: 32, weight: .light, design: .serif))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(hex: "#d4892e"),
                                    Color(hex: "#fab555")
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                .opacity(opacity)
            }
            .onAppear {
                // Fade in
                withAnimation(.easeIn(duration: 0.4)) {
                    opacity = 1.0
                }

                // Fade out before transitioning
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        opacity = 0.0
                    }
                }

                // Transition to main app
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                    isActive = true
                }
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
