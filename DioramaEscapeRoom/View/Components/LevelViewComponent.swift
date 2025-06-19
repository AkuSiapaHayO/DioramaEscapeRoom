//
//  LevelScenePreviewComponent.swift
//  DioramaEscapeRoom
//
//  Created by Louis Mario Wijaya on 18/06/25.
//

import SwiftUI
import SceneKit

struct LevelViewComponent: View {
    
    let level: Level
    
    var body: some View {
        
        VStack {
            Text("Level \(level.id)")
                .foregroundStyle(.black)
            
            Text(level.name)
                .foregroundStyle(.black)
            
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
                    cameraNode.position = SCNVector3(x: 2.2, y: 1, z: 2.2)
                    cameraNode.look(at: SCNVector3(0, 0.6, 0))
                    scene.rootNode.addChildNode(cameraNode)
                    
                    return scene
                }(),
                options: [.autoenablesDefaultLighting]
            )
            .scaledToFit()
        }
    }
}

//#Preview {
//    LevelScenePreviewComponent()
//}
