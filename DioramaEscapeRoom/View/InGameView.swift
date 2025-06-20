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
    @State private var rotationManager: RoomRotationManager? = nil
    @State private var scene: SCNScene? = nil
    @State private var cameraNode: SCNNode? = nil
    @State private var originalCameraPosition: SCNVector3 = SCNVector3(x: 10, y: 7, z: 10)
    @State private var originalCameraEulerAngles: SCNVector3 = SCNVector3()
    @State private var isZoomedIn: Bool = false
    @State private var interactionZones: [InteractionZone] = []
    
    var body: some View {
        ZStack {
            Color.white // ✅ White background
                .ignoresSafeArea()
            
            InteractiveSceneView(scene: scene) { tappedNode in
                guard !isZoomedIn else { return }
                print("Tapped node: \(tappedNode.name ?? "Unnamed")")
                handleNodeTap(tappedNode)
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
                        .background(Color.black.opacity(0.2))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        Spacer()
                    }
                    Spacer()
                }
                .padding()
            }
            
            VStack {
                HStack {
                    ExitButtonComponent()
                    Spacer()
                }
                Spacer()
            }
            .padding()
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
        
        // Setup interaction zones after scene is loaded
        setupInteractionZones(for: loadedScene)
    }
    
    private func setupInteractionZones(for scene: SCNScene) {
        var zones: [InteractionZone] = []
        
        // Method 1: Find zones by parent node names (empties/groups)
        let zoneNames = ["PeriodicTableZone", "CabinetZone", "DeskZone", "BookshelfZone"] // Add your zone names here
        
        for zoneName in zoneNames {
            if let zoneNode = scene.rootNode.childNode(withName: zoneName, recursively: true) {
                let zone = InteractionZone(
                    name: zoneName,
                    centerPosition: zoneNode.worldPosition,
                    radius: 2.0, // Adjust based on your needs
                    zoomDistance: getZoomDistanceForZone(zoneName),
                    heightOffset: getHeightOffsetForZone(zoneName)
                )
                zones.append(zone)
                print("Found interaction zone: \(zoneName) at position: \(zoneNode.worldPosition)")
            }
        }
        
        // Method 2: Manually define zones if you don't have empty nodes
        // Uncomment and customize these if you want to manually define zones
        /*
         zones.append(InteractionZone(
         name: "Cabinet Area",
         centerPosition: SCNVector3(x: 2, y: 0, z: 2),
         radius: 2.5,
         zoomDistance: 4.0,
         heightOffset: 1.0
         ))
         
         zones.append(InteractionZone(
         name: "Periodic Table Area",
         centerPosition: SCNVector3(x: -2, y: 0, z: -2),
         radius: 2.0,
         zoomDistance: 3.0,
         heightOffset: 0.5
         ))
         */
        
        self.interactionZones = zones
        print("Setup \(zones.count) interaction zones")
    }
    
    private func getZoomDistanceForZone(_ zoneName: String) -> Float {
        switch zoneName {
        case "CabinetZone":
            return 4.0
        case "PeriodicTableZone":
            return 3.0
        case "DeskZone":
            return 3.5
        default:
            return 3.0
        }
    }
    
    private func getHeightOffsetForZone(_ zoneName: String) -> Float {
        switch zoneName {
        case "CabinetZone":
            return 1.0
        case "PeriodicTableZone":
            return 0.5
        default:
            return 0.0
        }
    }
    
    private func handleNodeTap(_ tappedNode: SCNNode) {
        // First, check if the tapped node or its ancestors belong to an interaction zone
        if let zone = findInteractionZoneForNode(tappedNode) {
            print("Node belongs to interaction zone: \(zone.name)")
            zoomToZone(zone)
            return
        }
        
        // Fallback: Check if tapped position is within any interaction zone
        let tappedPosition = tappedNode.worldPosition
        if let nearestZone = findNearestInteractionZone(to: tappedPosition) {
            print("Tapped near interaction zone: \(nearestZone.name)")
            zoomToZone(nearestZone)
            return
        }
        
        // If no interaction zone found, you can either:
        // 1. Do nothing (ignore taps outside zones)
        print("Tap ignored - not in any interaction zone")
        
        // 2. Or fallback to original behavior (zoom to specific node)
        // zoomToNode(tappedNode)
    }
    
    private func findInteractionZoneForNode(_ node: SCNNode) -> InteractionZone? {
        guard let scene = scene else { return nil }
        
        // Check if the node or any of its ancestors is a child of a zone
        var currentNode: SCNNode? = node
        
        while let node = currentNode {
            // Check if this node's parent is a zone node
            if let parentName = node.parent?.name {
                for zone in interactionZones {
                    if parentName.contains(zone.name.replacingOccurrences(of: "Zone", with: "")) {
                        return zone
                    }
                }
            }
            currentNode = node.parent
        }
        
        return nil
    }
    
    private func findNearestInteractionZone(to position: SCNVector3) -> InteractionZone? {
        var nearestZone: InteractionZone? = nil
        var nearestDistance: Float = Float.greatestFiniteMagnitude
        
        for zone in interactionZones {
            let distance = distanceBetween(position, zone.centerPosition)
            if distance <= zone.radius && distance < nearestDistance {
                nearestDistance = distance
                nearestZone = zone
            }
        }
        
        return nearestZone
    }
    
    private func distanceBetween(_ pos1: SCNVector3, _ pos2: SCNVector3) -> Float {
        let dx = pos1.x - pos2.x
        let dy = pos1.y - pos2.y
        let dz = pos1.z - pos2.z
        return sqrt(dx*dx + dy*dy + dz*dz)
    }
    
    private func zoomToZone(_ zone: InteractionZone) {
        var zoomPosition = zone.centerPosition
        zoomPosition.y += zone.heightOffset
        
        zoomToPoint(zoomPosition, distance: zone.zoomDistance, nodeName: zone.name)
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
    
    // Updated zoomToPoint to accept node name for special handling
    private func zoomToPoint(_ point: SCNVector3, distance: Float = 3.0, nodeName: String? = nil) {
        guard let cameraNode = cameraNode else { return }
        
        print("Zooming to point: \(point)")
        
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
        
        print("Moving camera from \(cameraNode.position) to \(newCameraPosition)")
        
        // Create smooth animations
        let moveAction = SCNAction.move(to: newCameraPosition, duration: 1.0)
        moveAction.timingMode = .easeInEaseOut
        
        // Execute the animation
        cameraNode.runAction(moveAction) {
            // After movement, ensure we're looking at the target
            cameraNode.look(at: point)
            DispatchQueue.main.async {
                print("Zoom completed")
                self.isZoomedIn = true
            }
        }
    }
    
    private func zoomOut() {
        guard let cameraNode = cameraNode else { return }
        
        print("Zooming out to original position: \(originalCameraPosition)")
        
        // Create smooth move animation
        let moveAction = SCNAction.move(to: originalCameraPosition, duration: 1.0)
        moveAction.timingMode = .easeInEaseOut
        
        // Alternative: Use the stored original euler angles
        let restoreOrientationAction = SCNAction.run { _ in
            cameraNode.eulerAngles = self.originalCameraEulerAngles
        }
        
        let zoomOutSequence = SCNAction.sequence([
            SCNAction.group([moveAction]),
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
