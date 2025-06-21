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
        
        HStack {
            TransparentSceneView(scene: {
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
                camera.usesOrthographicProjection = true
                camera.orthographicScale = 2.1
                camera.zNear = 1
                camera.zFar = 100

                let cameraNode = SCNNode()
                cameraNode.camera = camera
                cameraNode.position = SCNVector3(x: 2, y: 2.5, z: 2)
                cameraNode.look(at: SCNVector3(0, 1, 0))
                scene.rootNode.addChildNode(cameraNode)

                scene.background.contents = UIColor.clear
                scene.lightingEnvironment.contents = nil
                
                return scene
            }())
            .frame(width: 300, height: 200)
            .cornerRadius(12)

        }
    }
}

#Preview {
    LevelViewComponent(level: Level(id: 1, name: "Test Level", sceneFile: "Science Lab Updated.scn"))
}
