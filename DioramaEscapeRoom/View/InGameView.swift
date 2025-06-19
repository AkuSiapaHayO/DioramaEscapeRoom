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
    @State private var cameraNode: SCNNode? = nil
    @State private var originalCameraPosition: SCNVector3 = SCNVector3(x: 10, y: 3, z: 10)
    @State private var originalCameraEulerAngles: SCNVector3 = SCNVector3()
    @State private var isZoomedIn: Bool = false

    var body: some View {
        ZStack {
            InteractiveSceneView(scene: scene) { tappedNode in
                guard !isZoomedIn else { return }
                print("Tapped node: \(tappedNode.name ?? "Unnamed")")
                zoomToNode(tappedNode)
            }
            .simultaneousGesture(
                // Drag gesture for rotation
                DragGesture()
                    .onChanged { value in
                        guard !isZoomedIn else { return } // Disable rotation when zoomed in
                        let delta = Float(value.translation.width - lastDragTranslationX) * 0.005
                        rotationManager?.rotate(by: delta)
                        lastDragTranslationX = value.translation.width
                    }
                    .onEnded { _ in
                        guard !isZoomedIn else { return }
                        rotationManager?.snapToNearestCorner()
                        lastDragTranslationX = 0
                    }
            )
            
            // Overlay for back button when zoomed in
            if isZoomedIn {
                VStack {
                    HStack {
                        Button("Back") {
                            zoomOut()
                        }
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        Spacer()
                    }
                    Spacer()
                }
                .padding()
            }
        }
        .onAppear {
            setupScene()
        }
        .ignoresSafeArea(.all)
        .navigationBarBackButtonHidden(true)
    }
    
    private func setupScene() {
        guard scene == nil else { return }
        
        let loadedScene = SCNScene(named: level.sceneFile) ?? SCNScene()

        if let roomNode = loadedScene.rootNode.childNode(withName: "root", recursively: true) {
            roomNode.eulerAngles = SCNVector3(x: -Float.pi / 2, y: 0, z: 0)
        }

        // Camera setting
        let camera = SCNCamera()
        camera.zNear = 1
        camera.zFar = 100
        camera.focalLength = 100
        camera.fStop = 1.8
        camera.focusDistance = 3

        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = originalCameraPosition
        cameraNode.look(at: SCNVector3(0, 0.9, 0))
        
        // Store original camera euler angles (better than rotation for restoration)
        originalCameraEulerAngles = cameraNode.eulerAngles
        
        loadedScene.rootNode.addChildNode(cameraNode)

        let intHiddenConfig = level.inGameHiddenItems?.compactMapKeys { Int($0) } ?? [:]

        self.scene = loadedScene
        self.cameraNode = cameraNode
        self.rotationManager = RoomRotationManager(scene: loadedScene, hiddenWallConfig: intHiddenConfig)
        self.rotationManager?.updateWallsVisibility()
        
        // Debug: Print all node names to help identify the correct name
        printAllNodeNames(node: loadedScene.rootNode, level: 0)
    }
    
    private func printAllNodeNames(node: SCNNode, level: Int) {
        let indent = String(repeating: "  ", count: level)
        if let name = node.name {
            print("\(indent)Node: \(name)")
        } else {
            print("\(indent)Node: <unnamed>")
        }
        
        for child in node.childNodes {
            printAllNodeNames(node: child, level: level + 1)
        }
    }
    
    private func handleTap() {
        guard let scene = scene else { return }
        
        if isZoomedIn {
            zoomOut()
            return
        }
        
        // For now, let's try to find any node that might be the Periodic Table
        // We'll check multiple possible names
        let possibleNames = ["Periodic_Table", "periodic_table", "PeriodicTable", "Table", "table"]
        
        for name in possibleNames {
            if let periodicTableNode = scene.rootNode.childNode(withName: name, recursively: true) {
                print("Found node with name: \(name)")
                zoomToNode(periodicTableNode)
                return
            }
        }
        
        // If we can't find by name, let's try to find any node that contains relevant keywords
        if let foundNode = findNodeContaining(keywords: ["periodic", "table", "Periodic", "Table"], in: scene.rootNode) {
            print("Found node containing keyword: \(foundNode.name ?? "unnamed")")
            zoomToNode(foundNode)
            return
        }
        
        // If still nothing found, let's just zoom to the center for testing
        print("No Periodic Table found, zooming to center")
        let centerPoint = SCNVector3(0, 0, 0)
        zoomToPoint(centerPoint)
    }
    
    private func findNodeContaining(keywords: [String], in node: SCNNode) -> SCNNode? {
        // Check current node
        if let nodeName = node.name {
            for keyword in keywords {
                if nodeName.lowercased().contains(keyword.lowercased()) {
                    return node
                }
            }
        }
        
        // Check children recursively
        for child in node.childNodes {
            if let found = findNodeContaining(keywords: keywords, in: child) {
                return found
            }
        }
        
        return nil
    }
    
    private func zoomToNode(_ node: SCNNode) {
        let nodePosition = node.worldPosition
        zoomToPoint(nodePosition)
    }
    
    private func zoomToPoint(_ point: SCNVector3) {
        guard let cameraNode = cameraNode else { return }
        
        print("Zooming to point: \(point)")
        
        // Calculate a good camera position relative to the target point
        let offset = SCNVector3(x: 0, y: 1, z: 3) // Move camera back and slightly up
        let newCameraPosition = SCNVector3(
            x: point.x + offset.x,
            y: point.y + offset.y,
            z: point.z + offset.z
        )
        
        print("Moving camera from \(cameraNode.position) to \(newCameraPosition)")
        
        // Animate camera to new position
        let moveAction = SCNAction.move(to: newCameraPosition, duration: 1.0)
        moveAction.timingMode = .easeInEaseOut
        
        // Create look-at action
        let lookAtAction = SCNAction.run { _ in
            cameraNode.look(at: point)
        }
        
        let zoomSequence = SCNAction.sequence([
            SCNAction.group([moveAction]),
            lookAtAction
        ])
        
        cameraNode.runAction(zoomSequence) {
            DispatchQueue.main.async {
                print("Zoom completed")
                self.isZoomedIn = true
            }
        }
    }
    
    private func zoomOut() {
        guard let cameraNode = cameraNode else { return }
        
        print("Zooming out to original position: \(originalCameraPosition)")
        
        // Animate back to original position
        let moveAction = SCNAction.move(to: originalCameraPosition, duration: 1.0)
        moveAction.timingMode = .easeInEaseOut
        
        // Restore original euler angles (more reliable than rotation)
        let rotateAction = SCNAction.run { _ in
            cameraNode.eulerAngles = self.originalCameraEulerAngles
        }
        
        let zoomOutSequence = SCNAction.sequence([
            SCNAction.group([moveAction]),
            rotateAction
        ])
        
        cameraNode.runAction(zoomOutSequence) {
            DispatchQueue.main.async {
                print("Zoom out completed")
                self.isZoomedIn = false
            }
        }
    }
}

#Preview {
    if let level = LevelLoader.loadLevels().first {
        InGameView(level: level)
    } else {
        Text("Failed to load level")
    }
}
