//
//  MicroscopeView.swift
//  DioramaEscapeRoom
//
//  Created by Derend Marvel Hanson Prionggo on 22/06/25.
//

import SwiftUI
import SceneKit

struct MicroscopeView: View {
    let sceneFile: String
    let nodeName: String = "Clue_color"
    @Binding var inventory: [String]
    
    @AppStorage("microscopeEffectStrength") private var effectStrength: Double = 0.8
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        var blurRadius: Double {
            effectStrength * 20.0 // max blur
        }

        var saturationAmount: Double {
            1.0 - effectStrength   // 0 when strong effect, 1 when no effect
        }

        ZStack {
            Color.black
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
            
            ZStack {
                VStack {
                    HStack {
                        Button(action: {
                            dismiss()  // 👈 This will close the fullScreenCover
                        }) {
                            Text("Back")
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .foregroundColor(.black)
                                .cornerRadius(10)
                        }
                        .padding()
                        Spacer()
                    }
                    Spacer()
                }
                HStack {
                    VStack {
                        Slider(value: $effectStrength, in: 0...1)
                            .rotationEffect(.degrees(-90))
                            .frame(width: 200, height: 40) // applied after rotation
                            .accentColor(.blue) // control the active track color
                    }
                    .frame(width: 40) // set desired slider width
                    .padding(.leading, 10) // reduce leading space
                    .padding(.top, 40)
                    
                    Spacer()
                }
            }

            
            ZStack{
                ZStack {
                    // Background: Blurred image
                    Image("Microscope")
                        .resizable()
                        .scaledToFit()
                        .blur(radius: 10)
                    
                    // Foreground: Sharp center with fade-out mask
                    Image("Microscope")
                        .resizable()
                        .scaledToFit()
                        .mask(
                            RadialGradient(
                                gradient: Gradient(colors: [.white, .white, .clear]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 200
                            )
                        )
                }
                
                TransparentSceneView(scene: {
                    // Load the source scene
                    guard let sourceScene = SCNScene(named: sceneFile) else {
                        print("Failed to load scene: \(sceneFile)")
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
                    objectNode.eulerAngles = SCNVector3Zero
                    
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
                .frame(width: 300, height: 300)
                .cornerRadius(12)
                .blur(radius: blurRadius)
                .saturation(saturationAmount)
            }
            HStack {
                Spacer()
                VStack{
                    ForEach(inventory, id: \.self) { item in
                        Inventory(level: sceneFile, nodeName: item, isFlashlightOn: .constant(false))
                    }
                }
            }
            .padding(24)
        }
    }
}

#Preview {
    MicroscopeView(sceneFile: "Science Lab Updated.scn", inventory: .constant(["UV_Flashlight", "Clue_color"]))
}
