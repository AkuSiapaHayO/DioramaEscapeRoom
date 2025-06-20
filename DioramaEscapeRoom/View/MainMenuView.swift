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
            ZStack {
                GradientBackground()
                    .ignoresSafeArea()
                Image("BG 1")
                    .resizable()
                    .scaledToFill()
                    .opacity(0.3)
                    .blur(radius: 5)
                    .ignoresSafeArea()
                VStack {
                    HStack{
                        Image("LockedIn Logo")
                            .resizable()
                            .frame(width: 100, height: 40)
                        Spacer()
                    }
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(levels) { level in
                                HStack {
                                    LevelViewComponent(level: level)
                                    VStack(alignment: .leading) {
                                        Text("Level \(level.id)")
                                            .foregroundStyle(.white)
                                            .font(.system(size: 20, weight: .light, design: .default))
                                        
                                        Text(level.name)
                                            .foregroundStyle(.white)
                                            .font(.system(size: 36, weight: .bold, design: .default))
                                        
                                        if let focused = focusedLevel {
                                            NavigationLink(value: focused) {
                                                Text("Play")
                                                    .font(.system(size: 14))
                                                    .padding(.vertical, 8)
                                                    .padding(.horizontal, 44)
                                                    .background(Color.white)
                                                    .foregroundColor(Color(hex: "044948"))
                                                    .cornerRadius(20)
                                            }
                                            .padding(.top, -12)
                                        }
                                    }
                                    .padding(.leading, 24)
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
                    
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    let loaded = LevelLoader.loadLevels()
                    self.levels = loaded
                    DispatchQueue.main.async {
                        self.focusedLevel = loaded.first
                    }
                }
                .navigationDestination(for: Level.self) { level in
                    InGameView(level: level)
                }
            }
        }
    }
}

#Preview {
    MainMenuView()
}
