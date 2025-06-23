//
//  LaunchScreen.swift
//  DioramaEscapeRoom
//
//  Created by Derend Marvel Hanson Prionggo on 19/06/25.
//

import SwiftUI

struct LaunchScreen: View {
    
    var body: some View {
        ZStack {
            GradientBackground()
            VStack{
                Image("LockedIn Logo")
                    .resizable()
                    .frame(width: 507, height: 180)
                Text("One Room. One Exit. Infinite Possibilites")
                    .foregroundColor(Color.white)
                    .font(.system(size: 20, weight: .light, design: .default))
            }
        }
        .onAppear {
            BackgroundMusicPlayer.shared.play(filename: "tensemusic")
        }
    }
}

#Preview {
    LaunchScreen()
}
