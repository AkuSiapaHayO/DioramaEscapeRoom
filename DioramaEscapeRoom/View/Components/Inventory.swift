//
//  Inventory.swift
//  DioramaEscapeRoom
//
//  Created by Derend Marvel Hanson Prionggo on 22/06/25.
//

import SwiftUI
import SceneKit

struct Inventory: View {
    let level: String
    let nodeName: String
    @Binding var isFlashlightOn: Bool
    var onTapAction: (() -> Void)? = nil
    
    var scale: CGFloat {
        switch nodeName {
        case "UV_Flashlight": return 0.3
        case "Golden_Key": return 0.3
        case "Clue_color": return 0.3
        default: return 0.3
        }
    }

    let baseWidth: CGFloat = 200
    let baseHeight: CGFloat = 200
    
    var body: some View {
        let scaledWidth = baseWidth * scale
        let scaledHeight = baseHeight * scale
        let paddingAmount = 24 * scale

        VStack {
            TransparentSceneView(scene: {
                // Load the source scene
                guard let sourceScene = SCNScene(named: level) else {
                    print("Failed to load scene: \(level)")
                    return SCNScene()
                }
                
                // Find the target node
                guard let targetNode = sourceScene.rootNode.childNode(withName: nodeName, recursively: true) else {
                    print("Could not find node: \(nodeName)")
                    return SCNScene()
                }
                
                // New scene for isolated object
                let scene = SCNScene()
                scene.background.contents = UIColor.clear
                
                let objectNode = targetNode.clone()
                objectNode.position = SCNVector3Zero
                
                // Apply rotation
                if nodeName == "Golden_Key"  {
                    objectNode.eulerAngles = SCNVector3Zero
                } else if nodeName == "UV_Flashlight" {
                    objectNode.eulerAngles = SCNVector3(x: .pi/4, y: 0, z: .pi*3/4)
                } else if nodeName == "Clue_color" {
                    objectNode.eulerAngles = SCNVector3(x: 0, y: -.pi, z: 0)
                }else {
                    objectNode.eulerAngles = SCNVector3(x: .pi/2, y: 0, z: .pi)
                }
                
                // Center pivot
                let (minVec, maxVec) = objectNode.boundingBox
                let size = SCNVector3(
                    x: maxVec.x - minVec.x,
                    y: maxVec.y - minVec.y,
                    z: maxVec.z - minVec.z
                )
                let center = SCNVector3(
                    x: (minVec.x + maxVec.x) / 2,
                    y: (minVec.y + maxVec.y) / 2,
                    z: (minVec.z + maxVec.z) / 2
                )
                objectNode.pivot = SCNMatrix4MakeTranslation(center.x, center.y, center.z)
                objectNode.scale = SCNVector3(1, 1, 1) // ← scale down here

                let maxDim = max(size.x, size.y, size.z)

                scene.rootNode.addChildNode(objectNode)

                // Camera
                let cameraNode = SCNNode()
                let camera = SCNCamera()
                camera.zNear = 0.01
                camera.zFar = 1000
                camera.fieldOfView = 55
                camera.focalLength = 80
                cameraNode.camera = camera
                
                // Calculate zoom distance
                let fovRadians = camera.fieldOfView * .pi / 180.0
                let baseDistance = maxDim / (2 * Float(tan(fovRadians / 2)))
                let zoomDistance = baseDistance + maxDim
                
                cameraNode.position = SCNVector3(0, 0, zoomDistance)
                cameraNode.look(at: SCNVector3Zero)
                scene.rootNode.addChildNode(cameraNode)

                return scene
            }(), enableDefaultLighting: true)
            .frame(width: scaledWidth, height: scaledHeight)
            .cornerRadius(12)
        }
        .padding(paddingAmount)
        .background(Color.gray.opacity(0.4))
        .cornerRadius(12)
        .onTapGesture {
            if nodeName == "UV_Flashlight" {
                isFlashlightOn.toggle()
                print("🔦 UV Flashlight toggled: \(isFlashlightOn)")
            } else if nodeName == "Golden_Key"{
                onTapAction?()
            } else if nodeName == "Clue_color" {
                onTapAction?()
            }
        }
    }
}

#Preview {
    Inventory(level: "Science Lab Updated.scn", nodeName: "Golden_Key", isFlashlightOn: .constant(false))
}

