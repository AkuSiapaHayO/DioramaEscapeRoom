//
//  MainMenuView.swift
//  DioramaEscapeRoom
//
//  Created by Louis Mario Wijaya on 18/06/25.
//

import SwiftUI
import SceneKit

struct MainMenuView: View {
    
    @State private var levels: [Level] = []
    @State private var focusedLevel: Level?
    
    var body: some View {
        NavigationStack() {
            
            VStack {
                Text("Diorama")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(.black)
                Text("Escape Room")
                    .font(.title)
                    .foregroundStyle(.gray)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(levels) { level in
                            VStack {
                                LevelViewComponent(level: level)
                                
                            }
                            .padding()
                            .containerRelativeFrame(.horizontal, count: 1, spacing: 16)
                            .id(level)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $focusedLevel)
                
                
                if let focused = focusedLevel {
                    NavigationLink(value: focused) {
                        Text("Play")
                            .font(.headline)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 32)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .padding(.top, 16)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
            .onAppear {
                let loaded = LevelLoader.loadLevels()
                self.levels = loaded
                self.focusedLevel = loaded.first
            }
            .navigationDestination(for: Level.self) { level in
                InGameView(level: level)
            }
        }
    }
}

#Preview {
    MainMenuView()
}
