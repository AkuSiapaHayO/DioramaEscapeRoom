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

    var body: some Scene {
        WindowGroup {
            MainMenuView()
                .onAppear {
                    UIDevice.current.setValue(UIInterfaceOrientation.landscapeLeft.rawValue, forKey: "orientation")
                    AppDelegate.orientationLock = .landscape
                }
        }
    }
}

