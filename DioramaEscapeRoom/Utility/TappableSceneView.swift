//
//  TappableSceneView.swift
//  DioramaEscapeRoom
//
//  Created by Derend Marvel Hanson Prionggo on 22/06/25.
//

import Foundation
import SwiftUI
import SceneKit

struct TappableSceneView: UIViewRepresentable {
    var scene: SCNScene
    var pointOfView: SCNNode
    var onNodeTapped: (SCNNode) -> Void

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.scene = scene
        scnView.pointOfView = pointOfView
        scnView.allowsCameraControl = false
        scnView.autoenablesDefaultLighting = true
        scnView.antialiasingMode = .multisampling4X
        scnView.backgroundColor = UIColor.black

        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)

        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onNodeTapped: onNodeTapped)
    }

    class Coordinator: NSObject {
        var onNodeTapped: (SCNNode) -> Void

        init(onNodeTapped: @escaping (SCNNode) -> Void) {
            self.onNodeTapped = onNodeTapped
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let scnView = gesture.view as? SCNView else { return }
            let location = gesture.location(in: scnView)
            let hitResults = scnView.hitTest(location, options: nil)

            if let tappedNode = hitResults.first?.node {
                onNodeTapped(tappedNode)
            }
        }
    }
}
