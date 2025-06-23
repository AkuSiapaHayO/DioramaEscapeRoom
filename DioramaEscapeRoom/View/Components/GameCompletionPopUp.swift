import SwiftUI

struct GameCompletionPopUp: View {
    let onBackToMenu: () -> Void

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Text("Level Completed!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.black)

                HStack{
                    Button("Return to Main Menu") {
                        onBackToMenu()  // 👈 This tells InGameView to dismiss itself
                    }
                    .padding()
                    .background(Color.cyan)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .fontWeight(.regular)
                }
            }
        }
    }
}

#Preview {
    GameCompletionPopUp(onBackToMenu: { })
}


