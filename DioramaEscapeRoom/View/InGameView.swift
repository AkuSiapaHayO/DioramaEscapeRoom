//
//  InGameView.swift
//  DioramaEscapeRoom
//
//  Created by Louis Mario Wijaya on 18/06/25.
//

import SwiftUI
import SceneKit

extension Dictionary {
    func compactMapKeys<T: Hashable>(_ transform: (Key) -> T?) -> [T: Value] {
        var result: [T: Value] = [:]
        for (key, value) in self {
            if let newKey = transform(key) {
                result[newKey] = value
            }
        }
        return result
    }
}

struct InGameView: View {
    let level: Level
    @State private var lastDragTranslationX: CGFloat = 0.0
    @State private var rotationManager: RoomRotationManager? = nil
    @State private var scene: SCNScene? = nil

    var body: some View {
        SceneView(
            scene: scene,
            options: [.autoenablesDefaultLighting]
        )
        .gesture(
            DragGesture()
                .onChanged { value in
                    let delta = Float(value.translation.width - lastDragTranslationX) * 0.005
                    rotationManager?.rotate(by: delta)
                    lastDragTranslationX = value.translation.width
                }
                .onEnded { _ in
                    rotationManager?.snapToNearestCorner()
                    lastDragTranslationX = 0
                }
        )
        .onAppear {
            //Room Setting
            if scene == nil {
                let loadedScene = SCNScene(named: level.sceneFile) ?? SCNScene()

                if let roomNode = loadedScene.rootNode.childNode(withName: "root", recursively: true) {
                    roomNode.eulerAngles = SCNVector3(x: -Float.pi / 2, y: 0, z: 0)
                }

                //Camera setting
                let camera = SCNCamera()
                camera.usesOrthographicProjection = true
                camera.orthographicScale = 2.1  // makin besar, makin zoom out
                camera.zNear = 1
                camera.zFar = 100

                let cameraNode = SCNNode()
                cameraNode.camera = camera
                cameraNode.position = SCNVector3(x: 2, y: 2.5, z: 2)
                cameraNode.look(at: SCNVector3(0, 1, 0))
                loadedScene.rootNode.addChildNode(cameraNode)

                let intHiddenConfig = level.inGameHiddenItems?.compactMapKeys { Int($0) } ?? [:]

                self.scene = loadedScene
                self.rotationManager = RoomRotationManager(scene: loadedScene, hiddenWallConfig: intHiddenConfig)
                self.rotationManager?.updateWallsVisibility()

            }
        }
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
