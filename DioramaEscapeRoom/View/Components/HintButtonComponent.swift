//
//  HintButtonComponent.swift
//  DioramaEscapeRoom
//
//  Created by Louis Mario Wijaya on 23/06/25.
//

import SwiftUI

struct HintButtonComponent: View {
    let currentState: GameProgressState?
    @State private var showHint = false

    var body: some View {
        ZStack {
            VStack {
                HStack {
                    // Hint button
                    Button(action: {
                        withAnimation {
                            showHint = true
                        }
                    }) {
                        Image("hint")
                            .resizable()
                            .frame(width: 48, height: 48)
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding()
                Spacer()
            }
            .padding(.leading, 84)
            .padding(.top, 12)
            

            // Hint popup
            if showHint {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .transition(.opacity)

                VStack(spacing: 20) {
                    Text("Hint")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text(hint(for: currentState))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white)
                        .padding(.horizontal)

                    Button("Close") {
                        withAnimation {
                            showHint = false
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.white)
                    .foregroundColor(Color(hex: "044948"))
                    .cornerRadius(12)
                    .fontWeight(.bold)
                }
                .padding(24)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color(hex: "00D4DF"), Color(hex: "044948")]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(20)
                .padding(.horizontal, 40)
                .transition(.scale)
                .shadow(radius: 10)
                .zIndex(10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // ✅ Ensures full expansion
        .ignoresSafeArea() // ✅ Needed at root level
        .animation(.easeInOut(duration: 0.3), value: showHint)
    }

    func hint(for state: GameProgressState?) -> String {
        switch state {
        case nil:
            return "“🧪 Important Dates. Some elements on that day might be something... aromatic.”"
        case .puzzle1_done:
            return "“You found the cup. Great. Now mix what’s under it with some light reading — preferably the kind that hides secrets between pages. ☕️📙”"
        case .puzzle3_done:
            return "“📄🔬🍷 Paper to scope. Light to flasks. Let there be numbers — just not in the wrong order.”"
        case .puzzle4_done:
            return "The Key might open something.. something Shiny ✨"
        case .puzzle5_done:
            return "“Your key opened shelves, not answers. Solve the riddles, find the elements, then just do some basic chemistry math. 🔑🧪💧”"
        case .gameFinished:
            return "Are you dumb? The Door is OPEN!!"
        }
    }
}

#Preview {
    HintButtonComponent(currentState: .puzzle3_done)
}
