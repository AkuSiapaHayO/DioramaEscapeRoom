//
//  InGameView.swift
//  DioramaEscapeRoom
//
//  Created by Louis Mario Wijaya on 18/06/25.
//

import SwiftUI
import SceneKit

struct InGameView: View {
    let level: Level
    
    var body: some View {        
        SceneView(
            scene: {
                let scene = SCNScene(named: level.sceneFile) ?? SCNScene()
                if let roomNode = scene.rootNode.childNode(withName: "root", recursively: true) {
                    roomNode.eulerAngles = SCNVector3(x: -Float.pi / 2, y: 0, z: 0)
                }
                
                if let hiddenItems = level.mainMenuHiddenItems {
                    for name in hiddenItems {
                        if let nodeToHide = scene.rootNode.childNode(withName: name, recursively: true) {
                            nodeToHide.isHidden = true
                        }
                    }
                }
                
                let camera = SCNCamera()
                let cameraNode = SCNNode()
                cameraNode.camera = camera
                cameraNode.position = SCNVector3(x: 4.5, y: 2, z: 4.5)
                cameraNode.look(at: SCNVector3(0, 0.6, 0))
                scene.rootNode.addChildNode(cameraNode)
                
                return scene
            }(),
            options: [.autoenablesDefaultLighting]
        )
        .ignoresSafeArea(.all)
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    if let level = LevelLoader.loadLevels().first {
        InGameView(level: level)
    } else {
        Text("Failed to load level")
    }
}
