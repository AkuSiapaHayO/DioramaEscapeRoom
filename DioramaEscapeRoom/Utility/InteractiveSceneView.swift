//
//  InteractiveSceneView.swift
//  DioramaEscapeRoom
//
//  Created by Derend Marvel Hanson Prionggo on 20/06/25.
//

import Foundation
import SwiftUI
import SceneKit

struct InteractiveSceneView: UIViewRepresentable {
    let scene: SCNScene?
    let enableDefaultLighting: Bool
    let onNodeTapped: (SCNNode) -> Void

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = scene
        scnView.allowsCameraControl = false
        scnView.autoenablesDefaultLighting = enableDefaultLighting
        scnView.antialiasingMode = .multisampling4X
        scnView.backgroundColor = .clear
        scnView.isOpaque = false

        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)

        context.coordinator.scnView = scnView
        return scnView
    }

    func updateUIView(_ scnView: SCNView, context: Context) {
        scnView.scene = scene
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onNodeTapped: onNodeTapped)
    }

    class Coordinator: NSObject {
        var onNodeTapped: (SCNNode) -> Void
        weak var scnView: SCNView?

        init(onNodeTapped: @escaping (SCNNode) -> Void) {
            self.onNodeTapped = onNodeTapped
        }

        @objc func handleTap(_ gestureRecognizer: UIGestureRecognizer) {
            guard let scnView = scnView else { return }
            let location = gestureRecognizer.location(in: scnView)
            let hitResults = scnView.hitTest(location, options: nil)

            if let hit = hitResults.first {
                onNodeTapped(hit.node)
            }
        }
    }
}
