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
    @Binding  var hasDisplayedClue: Bool
    @State private var displayedScene: SCNScene? = nil
    @State private var isSceneLoaded: Bool = false
    @State private var isClueSelected: Bool = false
    
    @AppStorage("microscopeEffectStrength") private var effectStrength: Double = 0.8
    
    @Environment(\.dismiss) private var dismiss
//    @EnvironmentObject var gameManager: GameManager
    
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
                if isClueSelected {
                    if isClueSelected, let scene = displayedScene {
                        TransparentSceneView(scene: scene, enableDefaultLighting: true)
                            .frame(width: 300, height: 300)
                            .cornerRadius(12)
                            .blur(radius: blurRadius)
                            .saturation(saturationAmount)
                            .offset(x: isClueSelected ? 0 : -400)
                            .animation(.easeOut(duration: 0.8), value: isClueSelected)
                    }
                }
            }
            HStack {
                Spacer()
                VStack{
                    ForEach(inventory, id: \.self) { item in
                        Inventory(
                            level: sceneFile,
                            nodeName: item,
                            isFlashlightOn: .constant(false),
                            onTapAction: {
                                if item == "Clue_color" && isSceneLoaded {
                                    withAnimation {
                                        isClueSelected = true
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        if let scene = displayedScene {
                                            SoundPlayer.shared.playSound(named: "paper.mp3", on: scene.rootNode, volume: 2.0)
                                        }
                                    }
                                    hasDisplayedClue = true
                                    inventory.removeAll { $0 == "Clue_color" }
                                }
                            }
                        )
                    }
                }
            }
            .padding(24)
        }
        .onAppear {
            preloadScene()
            
            // Automatically show clue if already obtained
            if hasDisplayedClue {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    if isSceneLoaded {
                        withAnimation {
                            isClueSelected = true
                        }
                        if let scene = displayedScene {
                            SoundPlayer.shared.playSound(named: "paper.mp3", on: scene.rootNode, volume: 2.0)
                        }
                    } else {
                        // Wait until the scene is actually loaded
                        waitForSceneToLoadAndShowClue()
                    }
                }
            }
        }
    }
    
    // Preload the scene when the view appears
    private func preloadScene() {
        DispatchQueue.global(qos: .userInitiated).async {
            guard let sourceScene = SCNScene(named: sceneFile),
                  let targetNode = sourceScene.rootNode.childNode(withName: nodeName, recursively: true) else {
                print("Failed to load scene or node")
                return
            }

            let scene = SCNScene()
            scene.background.contents = UIColor.clear

            let objectNode = targetNode.clone()
            objectNode.position = SCNVector3Zero
            objectNode.eulerAngles = SCNVector3(0, 0, Float.pi)

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
            objectNode.scale = SCNVector3(1, 1, 1)

            let maxDim = max(size.x, size.y, size.z)

            scene.rootNode.addChildNode(objectNode)

            let cameraNode = SCNNode()
            let camera = SCNCamera()
            camera.zNear = 0.01
            camera.zFar = 1000
            camera.fieldOfView = 55
            camera.focalLength = 80
            cameraNode.camera = camera

            let fovRadians = camera.fieldOfView * .pi / 180.0
            let baseDistance = maxDim / (2 * Float(tan(fovRadians / 2)))
            let zoomDistance = baseDistance + maxDim

            cameraNode.position = SCNVector3(0, 0, zoomDistance)
            cameraNode.look(at: SCNVector3Zero)
            scene.rootNode.addChildNode(cameraNode)

            DispatchQueue.main.async {
                self.displayedScene = scene
                self.isSceneLoaded = true
            }
        }
    }
    
    private func waitForSceneToLoadAndShowClue() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if isSceneLoaded {
                withAnimation {
                    isClueSelected = true
                }
                if let scene = displayedScene {
                    SoundPlayer.shared.playSound(named: "paper.mp3", on: scene.rootNode, volume: 2.0)
                }
            } else {
                waitForSceneToLoadAndShowClue()
            }
        }
    }

}


#Preview {
    MicroscopeView(sceneFile: "Science Lab Updated.scn", inventory: .constant(["UV_Flashlight", "Clue_color"]), hasDisplayedClue: .constant(false))
}
