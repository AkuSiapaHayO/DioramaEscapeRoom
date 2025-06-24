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
            Color.clear // Invisible filler to allow full frame usage

            // Top-left Exit Button
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
                            .tint(Color.cyan)
                    }
                    Spacer()
                }
                .padding()
                Spacer()
            }
            .padding()

            // Dimmed background + popup
            if showPopup {
                // 🛠 This now fills everything correctly on device
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .transition(.opacity)

                VStack(spacing: 4) {
                    Text("Exit to main menu?")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.bottom, 4)

                    Text("Your progress will be lost")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.bottom, 16)

                    HStack(spacing: 24) {
                        Button("Exit") {
                            withAnimation {
                                BackgroundMusicPlayer.shared.stop()
                                BackgroundMusicPlayer.shared.play(filename: "tensemusic")
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
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // ✅ Ensures full expansion
        .ignoresSafeArea() // ✅ Needed at root level
        .animation(.easeInOut(duration: 0.3), value: showPopup)
    }
}

#Preview {
    ExitButtonComponent()
}
