//
//  GameCompletionPopUp.swift
//  DioramaEscapeRoom
//
//  Created by Louis Mario Wijaya on 23/06/25.
//

import SwiftUI

struct GameCompletionPopUp: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.white
                .opacity(0.75)
                .ignoresSafeArea()
            
            VStack {
                Text("Level Completed!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                
                Button(action: {
                    dismiss()
                }) {
                    Text("Back to Main Menu")
                        .fontWeight(.bold)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.cyan)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
        .ignoresSafeArea(.all)
    }
}

#Preview {
    GameCompletionPopUp()
}
