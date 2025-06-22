//
//  TransparentSceneView.swift
//  DioramaEscapeRoom
//
//  Created by Derend Marvel Hanson Prionggo on 19/06/25.
//

import Foundation
import SwiftUI
import SceneKit

struct TransparentSceneView: UIViewRepresentable {
    let scene: SCNScene
    let enableDefaultLighting: Bool

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.scene = scene
        view.allowsCameraControl = false
        view.autoenablesDefaultLighting = enableDefaultLighting
        view.backgroundColor = .clear    // ✅ Transparent
        view.isOpaque = false            // ✅ Required for transparency
        return view
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        // Optional: Update logic if needed
    }
}
