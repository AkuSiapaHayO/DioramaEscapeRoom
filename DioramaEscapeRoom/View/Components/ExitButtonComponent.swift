//
//  SwiftUIView.swift
//  DioramaEscapeRoom
//
//  Created by Louis Mario Wijaya on 20/06/25.
//

import SwiftUI

struct ExitButtonComponent: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showPopup = false

    var body: some View {
        ZStack {
            // 👇 1. Full screen area to allow popup centering
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // 👆 Without this, the ZStack collapses to the button size

            // 🟢 2. The actual exit button (top-left)
            VStack {
                HStack {
                    Button(action: {
                        withAnimation {
                            showPopup = true
                        }
                    }) {
                        Image("ExitButton")
                            .resizable()
                            .frame(width: 48, height: 48)
                    }
                    Spacer()
                }
                Spacer()
            }
            .padding()

            // 🔴 3. The popup centered
            if showPopup {
                VStack(spacing: 4) {
                    Text("Exit to main menu?")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Your progress will be lost")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.bottom, 12)

                    HStack(spacing: 24) {
                        Button("Exit") {
                            withAnimation {
                                dismiss()
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .foregroundColor(Color(hex: "044948"))
                        .cornerRadius(12)
                        .fontWeight(.bold)

                        Button("Stay") {
                            withAnimation {
                                showPopup = false
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.2))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .fontWeight(.bold)
                    }
                }
                .padding(.all, 24)
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
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showPopup)
    }
}

#Preview {
    ExitButtonComponent()
}
