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
    @State private var lastDragTranslationX: CGFloat = 0.0
    @State private var lastDragTranslationY: CGFloat = 0.0
    @State private var rotationManager: RoomRotationManager? = nil
    @State private var scene: SCNScene? = nil
    @State private var cameraNode: SCNNode? = nil
    @State private var originalCameraPosition: SCNVector3 = SCNVector3(x: 12, y: 8, z: 12)
    @State private var originalCameraEulerAngles: SCNVector3 = SCNVector3()
    @State private var isZoomedIn: Bool = false
    
    // Orbital camera properties
    @State private var orbitalRadius: Float = 3.0
    @State private var orbitalAngleHorizontal: Float = 0.0
    @State private var orbitalAngleVertical: Float = 0.0
    @State private var orbitalTarget: SCNVector3 = SCNVector3(0, 0, 0)
    
    // New state to store the initial horizontal angle when zoomed in
    @State private var initialOrbitalAngleHorizontal: Float = 0.0
    
    // Constants for limiting rotation
    let horizontalRotationLimit: Float = 25.0 * (.pi / 180.0) // 25 degrees in radians
    
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
                        if isZoomedIn {
                            // Orbital rotation when zoomed in
                            let deltaX = Float(value.translation.width - lastDragTranslationX) * 0.01
                            let deltaY = Float(value.translation.height - lastDragTranslationY) * 0.01
                            
                            // Apply horizontal rotation and clamp it
                            orbitalAngleHorizontal += deltaX
                            orbitalAngleHorizontal = max(initialOrbitalAngleHorizontal - horizontalRotationLimit,
                                                         min(initialOrbitalAngleHorizontal + horizontalRotationLimit, orbitalAngleHorizontal))

                            // Apply vertical rotation and clamp it
                            let verticalLimit: Float = .pi / 6 // Still 30 degrees for vertical
                            orbitalAngleVertical += deltaY
                            orbitalAngleVertical = max(-verticalLimit, min(verticalLimit, orbitalAngleVertical))

                            updateOrbitalCamera()

                            lastDragTranslationX = value.translation.width
                            lastDragTranslationY = value.translation.height
                        } else {
                            // Room rotation when zoomed out
                            let delta = Float(value.translation.width - lastDragTranslationX) * 0.005
                            rotationManager?.rotate(by: delta)
                            lastDragTranslationX = value.translation.width
                        }
                    }
                    .onEnded { _ in
                        if isZoomedIn {
                            lastDragTranslationX = 0
                            lastDragTranslationY = 0
                        } else {
                            rotationManager?.snapToNearestCorner()
                            lastDragTranslationX = 0
                        }
                    }
            )
            .simultaneousGesture(
                // Pinch gesture for zoom in/out when zoomed in
                MagnificationGesture()
                    .onChanged { value in
                        guard isZoomedIn else { return }
                        
                        // Adjust orbital radius based on pinch
                        // Note: Value is typically 1.0 for no change, >1.0 for zoom in, <1.0 for zoom out.
                        // You might want to adjust the multiplier based on desired sensitivity.
                        let newRadius = orbitalRadius / Float(value)
                        orbitalRadius = max(1.0, min(10.0, newRadius)) // Clamp between 1 and 10
                        
                        updateOrbitalCamera()
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
                        .background(Color.black.opacity(0.2))
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
        camera.zFar = 200
        camera.focalLength = 120
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
    }
    
    private func updateOrbitalCamera() {
        guard let cameraNode = cameraNode else { return }
        
        // Calculate new camera position based on orbital angles and radius
        let x = orbitalTarget.x + orbitalRadius * cos(orbitalAngleVertical) * sin(orbitalAngleHorizontal)
        let y = orbitalTarget.y + orbitalRadius * sin(orbitalAngleVertical)
        let z = orbitalTarget.z + orbitalRadius * cos(orbitalAngleVertical) * cos(orbitalAngleHorizontal)
        
        let newPosition = SCNVector3(x: x, y: y, z: z)
        
        // Smoothly update camera position and look at target
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.1
        cameraNode.position = newPosition
        cameraNode.look(at: orbitalTarget) // This handles the orientation, preventing roll and undesired pitch/yaw
        SCNTransaction.commit()
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
        
        // Get the bounding box to understand the object's size
        let (min, max) = node.boundingBox
        let size = SCNVector3(
            x: max.x - min.x,
            y: max.y - min.y,
            z: max.z - min.z
        )
        
        // Calculate appropriate distance based on object size
        let maxDimension = Swift.max(Swift.max(size.x, size.y), size.z)
        let distance = Swift.max(maxDimension * 2.5, 3.0) // Minimum distance of 3 units
        
        // Special case for Cabinet_1 - move camera up by 1 unit on Y-axis
        var adjustedPosition = nodePosition
        if node.name == "Cabinet_1" {
            adjustedPosition.y += 1.0
            print("Special handling for Cabinet_1: Moving camera up by 1 unit")
        }
        
        zoomToPoint(adjustedPosition, distance: distance, nodeName: node.name)
    }

    // Updated zoomToPoint to set up orbital camera
    private func zoomToPoint(_ point: SCNVector3, distance: Float = 3.0, nodeName: String? = nil) {
        guard let cameraNode = cameraNode else { return }
        
        print("Zooming to point: \(point)")
        
        // Set up orbital camera parameters
        orbitalTarget = point
        orbitalRadius = distance
        
        // Calculate initial orbital angles based on current camera position
        let currentPos = cameraNode.position
        let directionToTarget = SCNVector3(
            x: point.x - currentPos.x,
            y: point.y - currentPos.y,
            z: point.z - currentPos.z
        )
        
        // Calculate initial angles
        let horizontalDistance = sqrt(directionToTarget.x * directionToTarget.x + directionToTarget.z * directionToTarget.z)
        
        // Store the initial horizontal angle when zooming in
        initialOrbitalAngleHorizontal = atan2(directionToTarget.x, directionToTarget.z)
        orbitalAngleHorizontal = initialOrbitalAngleHorizontal // Set current to initial
        orbitalAngleVertical = atan2(directionToTarget.y, horizontalDistance)
        
        // Calculate camera position in front of the object
        let currentPosition = cameraNode.position
        let currentTarget = SCNVector3(0, 0.9, 0) // Current look-at point
        
        // Calculate direction from current camera to current target
        var direction = SCNVector3(
            x: currentTarget.x - currentPosition.x,
            y: currentTarget.y - currentPosition.y,
            z: currentTarget.z - currentPosition.z
        )
        
        // Normalize the direction
        let length = sqrt(direction.x * direction.x + direction.y * direction.y + direction.z * direction.z)
        if length > 0 {
            direction.x /= length
            direction.y /= length
            direction.z /= length
        }
        
        // Position camera in front of the target object
        var newCameraPosition = SCNVector3(
            x: point.x - direction.x * distance,
            y: point.y - direction.y * distance,
            z: point.z - direction.z * distance
        )
        
        // Special adjustment for Cabinet_1
        if nodeName == "Cabinet_1" {
            newCameraPosition.y += 0.0
            print("Additional camera height adjustment for Cabinet_1")
        }
        
        print("Moving camera from \(cameraNode.position) to \(newCameraPosition)")
        
        // Create smooth animations
        let moveAction = SCNAction.move(to: newCameraPosition, duration: 1.0)
        moveAction.timingMode = .easeInEaseOut
        
        // Execute the animation
        cameraNode.runAction(moveAction) {
            // After movement, ensure we're looking at the target
            cameraNode.look(at: point)
            
            // Update orbital angles based on final position
            let finalPos = cameraNode.position
            let finalDirection = SCNVector3(
                x: point.x - finalPos.x,
                y: point.y - finalPos.y,
                z: point.z - finalPos.z
            )
            
            let finalHorizontalDistance = sqrt(finalDirection.x * finalDirection.x + finalDirection.z * finalDirection.z)
            
            // Re-calculate and store the initial horizontal angle after the animation settles
            self.initialOrbitalAngleHorizontal = atan2(-finalDirection.x, -finalDirection.z)
            self.orbitalAngleHorizontal = self.initialOrbitalAngleHorizontal
            self.orbitalAngleVertical = atan2(finalDirection.y, finalHorizontalDistance)
            
            DispatchQueue.main.async {
                print("Zoom completed - Orbital camera ready")
                self.isZoomedIn = true
            }
        }
    }

    private func zoomOut() {
        guard let cameraNode = cameraNode else { return }
        
        print("Zooming out to original position: \(originalCameraPosition)")
        
        // Reset orbital parameters
        orbitalRadius = 3.0
        orbitalAngleHorizontal = 0.0
        orbitalAngleVertical = 0.0
        
        // Create smooth move animation
        let moveAction = SCNAction.move(to: originalCameraPosition, duration: 1.0)
        moveAction.timingMode = .easeInEaseOut
        
        // Alternative: Use the stored original euler angles
        let restoreOrientationAction = SCNAction.run { _ in
            cameraNode.eulerAngles = self.originalCameraEulerAngles
        }
        
        let zoomOutSequence = SCNAction.sequence([
            SCNAction.group([moveAction]), // Group can be used if you want to run other animations concurrently
            restoreOrientationAction
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
