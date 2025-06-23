import SwiftUI

struct GameCompletionPopUp: View {
    let onBackToMenu: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "00D4DF"), Color(hex: "044948")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(0.75)
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Level Completed!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Button("Back to Main Menu") {
                    onBackToMenu()  // 👈 This tells InGameView to dismiss itself
                }
                .padding()
                .background(Color.cyan)
                .foregroundColor(.black)
                .cornerRadius(12)
                .fontWeight(.regular)
            }
        }
    }
}


