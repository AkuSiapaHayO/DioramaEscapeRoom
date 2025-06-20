//
//  DioramaEscapeRoomApp.swift
//  DioramaEscapeRoom
//
//  Created by Louis Mario Wijaya on 16/06/25.
//

import SwiftUI

@main
struct DioramaEscapeRoomApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var showLaunchScreen = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                // MainMenu fades in
                MainMenuView()
                    .opacity(showLaunchScreen ? 0 : 1)
                    .animation(.easeInOut(duration: 2), value: showLaunchScreen)

                // LaunchScreen fades out
                if showLaunchScreen {
                    LaunchScreen()
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 2), value: showLaunchScreen)
                }
            }
            .onAppear {
                UIDevice.current.setValue(UIInterfaceOrientation.landscapeLeft.rawValue, forKey: "orientation")
                AppDelegate.orientationLock = .landscape

                // Force 3-second display of launch screen
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showLaunchScreen = false
                }
            }
        }
    }
}
