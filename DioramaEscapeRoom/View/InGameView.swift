//
//  InGameView.swift
//  DioramaEscapeRoom
//
//  Created by Louis Mario Wijaya on 18/06/25.
//

import SwiftUI
import SceneKit

struct InGameView: View {
    @State private var focusedObject: FocusedObject? = nil
    @State private var showFocusObjectView = false
    @State private var showMicroscope = false
    @State private var openedCabinets: Set<String> = []
    @State private var openedLockers: Set<String> = []
    @State var inventory: [String] = []
    
    let level: Level
    @State private var lastDragTranslationX: CGFloat = 0.0
    @State private var lastDragTranslationY: CGFloat = 0.0
    @State private var lastDragTranslationZ: CGFloat = 0.0
    @State private var rotationManager: RoomRotationManager? = nil
    @State private var scene: SCNScene? = nil
    @State private var cameraNode: SCNNode? = nil
    @State private var originalCameraPosition: SCNVector3 = SCNVector3(x: 12, y: 8, z: 12)
    @State private var originalCameraEulerAngles: SCNVector3 = SCNVector3()
    @State private var isZoomedIn: Bool = false
    @State private var isZooming: Bool = false
    
    @State private var showLockMessage: Bool = false
    @State private var lockMessageText: String = ""
    
    // Orbital camera properties
    @State private var orbitalRadius: Float = 3.0
    @State private var orbitalAngleHorizontal: Float = 0.0
    @State private var orbitalAngleVertical: Float = 0.0
    @State private var orbitalTarget: SCNVector3 = SCNVector3(0, 0, 0)
    
    // New state to store the initial horizontal angle when zoomed in
    @State private var initialOrbitalAngleHorizontal: Float = 0.0
    
    // Game State
    @StateObject private var gameManager = GameManager()
    
    @Environment(\.dismiss) private var dismiss  // allow InGameView to pop itself
    
    @State private var doorHasOpened = false
    @State private var showGameCompletedPopup = false
    
    // Constants for limiting rotation
    let horizontalRotationLimit: Float = 30.0 * (.pi / 180.0)
    
    var body: some View {
        ZStack {
            GradientBackground()
            
            InteractiveSceneView(scene: scene, enableDefaultLighting: false) { tappedNode in
                // ALWAYS print debug info first, regardless of zoom state
                
                if isZooming {
                    print("⏳ Ignoring tap - currently zooming")
                    return
                } else {
                    if isZoomedIn {
                        print("🔍 Processing tap while ZOOMED IN")
                        
                        // Prefer parent node if it exists and has a name
                        let targetNode: SCNNode? = {
                            if let parent = tappedNode.parent, let parentName = parent.name, !parentName.isEmpty {
                                return parent
                            } else if let name = tappedNode.name, !name.isEmpty {
                                return tappedNode
                            } else {
                                return nil
                            }
                        }()
                        
                        if let targetNode = targetNode {
                            var nodeName = targetNode.name ?? ""
                            
                            if(nodeName.starts(with: "Numpad_")){
                                nodeName = "Passcode_Machine"
                            } else if(nodeName.starts(with: "Codepad_")){
                                nodeName = "Lock_1"
                            } else if(nodeName.starts(with: "Key_")){
                                nodeName = "Lock_2"
                            }  else if (nodeName.starts(with: "Num_")){
                                nodeName = "Passcode_1"
                            } else if (nodeName == "Drawer"){
                                nodeName = "Golden_Keyhole"
                            } else if(nodeName == "Orange_Book_Half_2" || nodeName == "Orange_Book_Half_1"){
                                nodeName = "Orange_Book"
                            }
                            
                            if nodeName == "Paper_1" || nodeName == "Paper_2"  {
                                SoundPlayer.shared.playSound(named: "paper.mp3", on: targetNode, volume: 1.5)
                            }
                            
                            print("🎯 Using node: \(nodeName)")
                            
                            let cabinetNames = ["Cabinet_1", "Cabinet_2", "Cabinet_3"]
                            
                            let lockerNames = ["Locker_1", "Locker_2", "Locker_3"]
                            let lockerDoorNames = ["Locker_Door_1", "Locker_Door_2", "Locker_Door_3"]
                            
                            let RotatingObjectNames = ["Big_Plant_1", "Big_Plant_2", "Big_Plant_3", "Small_Plant_1", "Small_Plant_2", "Chair_Red", "Chair_Green", "Chair_Red_001", "Tubes_1"]
                            
                            let untappableObjectNames = [
                                "Window","Floor", "Tiles", "Table_1", "Table_2", "Small_Table"
                            ]
                            
                            if untappableObjectNames.contains(nodeName) || nodeName.contains("Wall") || nodeName.contains("Vents") || nodeName.contains("Copy") || nodeName.contains("Tube"){
                                return
                            }
                            
                            if nodeName == "Golden_Key" || nodeName == "UV_Flashlight" || nodeName == "Clue_color" {
                                if gameManager.currentState == .puzzle3_done {
                                    if nodeName == "Clue_color" {
                                        SoundPlayer.shared.playSound(named: "paper.mp3", on: targetNode, volume: 1.5)
                                    } else if nodeName == "UV_Flashlight" {
                                        SoundPlayer.shared.playSound(named: "rotatemove.mp3", on: targetNode, volume: 2.5)
                                    }
                                    inventory.append(nodeName)
                                    if let scene = scene, // unwrap the optional scene
                                       let targetNode = scene.rootNode.childNode(withName: nodeName, recursively: true) {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                            targetNode.isHidden = true
                                        }
                                    }
                                    return
                                }  else if gameManager.currentState == .puzzle4_done  {
                                    SoundPlayer.shared.playSound(named: "rotatemove.mp3", on: targetNode, volume: 2.5)
                                    inventory.append(nodeName)
                                    if let scene = scene, // unwrap the optional scene
                                       let targetNode = scene.rootNode.childNode(withName: nodeName, recursively: true) {
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            targetNode.isHidden = true
                                        }
                                    }
                                    return
                                } else {
                                    return
                                }
                            }
                            
                            if RotatingObjectNames.contains(nodeName) {
                                let rotateAction = SCNAction.rotateBy(x: 0, y: 0, z: -.pi / 2, duration: 0.5)
                                rotateAction.timingMode = .easeInEaseOut
                                targetNode.runAction(rotateAction)
                                SoundPlayer.shared.playSound(named: "rotatemove.mp3", on: targetNode, volume: 2.5)
                                return
                            }
                            
                            // Normalize to locker node
                            var lockerNode: SCNNode? = nil
                            
                            if lockerNames.contains(nodeName) {
                                lockerNode = targetNode
                            } else if lockerDoorNames.contains(nodeName), let parent = targetNode.parent {
                                lockerNode = parent
                            }
                            
                            if let locker = lockerNode, let lockerName = locker.name {
                                
                                if (lockerName == "Locker_1" && !gameManager.isPuzzleUnlocked(for: .puzzle1_done)) ||
                                    (lockerName == "Locker_2" && !gameManager.isPuzzleUnlocked(for: .puzzle3_done)) ||
                                    (lockerName == "Locker_3" && !gameManager.isPuzzleUnlocked(for: .puzzle4_done)) {
                                    print("🔒 \(lockerName) masih terkunci")
                                    SoundPlayer.shared.playSound(named: "locked.mp3", on: targetNode, volume: 0.8)
                                    
                                    // Trigger Lock Message
                                    lockMessageText = "\(lockerName.replacingOccurrences(of: "_", with: " ")) is locked"
                                    showLockMessage = true
                                    
                                    // Auto-dismiss after 2 seconds
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                        showLockMessage = false
                                    }
                                    
                                    return
                                }
                                
                                let doorName = "Locker_Door_\(lockerName.last!)"
                                
                                if let doorNode = locker.childNode(withName: doorName, recursively: true) {
                                    if openedLockers.contains(lockerName) {
                                        print("🔁 Closing locker \(lockerName)")
                                        let rotateAction = SCNAction.rotateBy(x: 0, y: 0, z: -.pi / 2, duration: 0.5)
                                        rotateAction.timingMode = .easeInEaseOut
                                        doorNode.runAction(rotateAction)
                                        SoundPlayer.shared.playSound(named: "locker.mp3", on: targetNode, volume: 0.7)
                                        openedLockers.remove(lockerName)
                                    } else {
                                        print("🚪 Opening locker \(lockerName)")
                                        let rotateAction = SCNAction.rotateBy(x: 0, y: 0, z: .pi / 2, duration: 0.5)
                                        rotateAction.timingMode = .easeInEaseOut
                                        doorNode.runAction(rotateAction)
                                        SoundPlayer.shared.playSound(named: "locker.mp3", on: targetNode, volume: 0.7)
                                        openedLockers.insert(lockerName)
                                    }
                                    return
                                }
                            }
                            
                            if nodeName == "Door" {
                                if gameManager.currentState == .gameFinished && !doorHasOpened {
                                    let rotateAction = SCNAction.rotateBy(x: 0, y: 0, z: -.pi / 4, duration: 0.5)
                                    rotateAction.timingMode = .easeInEaseOut
                                    targetNode.runAction(rotateAction)
                                    doorHasOpened = true

                                    SoundPlayer.shared.playSound(named: "door.mp3", on: targetNode, volume: 0.7)

                                    // Wait 3 seconds before showing the popup
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        showGameCompletedPopup = true
                                    }

                                    return
                                } else {
                                    // 🔒 Door is still locked
                                    SoundPlayer.shared.playSound(named: "locked.mp3", on: targetNode, volume: 0.7)
                                    lockMessageText = "\(nodeName.replacingOccurrences(of: "_", with: " ")) is locked"
                                    showLockMessage = true

                                    // Auto-dismiss after 2 seconds
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                        showLockMessage = false
                                    }

                                    return
                                }
                            }
                            
                            if nodeName.contains("Microscope") {
                                if inventory.contains(where: { $0.contains("Clue_color") }) {
                                    SoundPlayer.shared.playSound(named: "whoosh.mp3", on: targetNode, volume: 0.7)
                                    showMicroscope = true
                                    return
                                }
                            }
                            
                            if cabinetNames.contains(nodeName) {
                                if gameManager.currentState != .puzzle5_done && gameManager.currentState != .gameFinished {
                                    print("🔒 Drawer masih terkunci")
                                    SoundPlayer.shared.playSound(named: "locked.mp3", on: targetNode, volume: 0.7)
                                    lockMessageText = "\(nodeName.replacingOccurrences(of: "_", with: " ")) is locked"
                                    showLockMessage = true
                                    
                                    // Automatically hide the message after 2 seconds
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                        showLockMessage = false
                                    }
                                    return
                                }
                                if openedCabinets.contains(nodeName) {
                                    // 🔁 Cabinet is already open — close it
                                    print("🔁 Closing cabinet \(nodeName)")
                                    let moveAction = SCNAction.moveBy(x: 0.0, y: -0.2, z: 0.0, duration: 0.5)
                                    moveAction.timingMode = .easeInEaseOut
                                    targetNode.runAction(moveAction)
                                    SoundPlayer.shared.playSound(named: "cabinet.mp3", on: targetNode, volume: 0.7)
                                    openedCabinets.remove(nodeName)
                                } else {
                                    // 🚪 Cabinet is closed — open it
                                    print("🚪 Opening cabinet \(nodeName)")
                                    let moveAction = SCNAction.moveBy(x: 0.0, y: 0.2, z: 0.0, duration: 0.5)
                                    moveAction.timingMode = .easeInEaseOut
                                    targetNode.runAction(moveAction)
                                    SoundPlayer.shared.playSound(named: "cabinet.mp3", on: targetNode, volume: 0.7)
                                    openedCabinets.insert(nodeName)
                                }
                                return
                            }
                            gameManager.handleNodeTapped(nodeName)
                            
                            DispatchQueue.main.async {
                                focusedObject = FocusedObject(name: nodeName)
                                showFocusObjectView = true
                            }
                        } else {
                            print("❌ No suitable node found to focus")
                        }
                        
                    } else {
                        print("🔎 Processing tap while ZOOMED OUT - will zoom to node")
                        zoomToNode(tappedNode)
                    }
                }
            }
            .simultaneousGesture(
                // Drag gesture for rotation
                isZooming ? nil : DragGesture()
                    .onChanged { value in
                        if isZoomedIn {
                            // Orbital rotation when zoomed in
                            //                            let deltaX = Float(value.translation.width - lastDragTranslationX) * 0.005
                            //                            let deltaY = Float(value.translation.height - lastDragTranslationY) * 0.005
                            //
                            //                            // Apply horizontal rotation and clamp it
                            //                            orbitalAngleHorizontal += deltaX
                            //                            orbitalAngleHorizontal = max(initialOrbitalAngleHorizontal - horizontalRotationLimit,
                            //                                                         min(initialOrbitalAngleHorizontal + horizontalRotationLimit, orbitalAngleHorizontal))
                            //
                            //                            // Apply vertical rotation and clamp it
                            //                            let verticalLimit: Float = .pi // Still 30 degrees for vertical
                            //                            orbitalAngleVertical += deltaY
                            //                            orbitalAngleVertical = max(-verticalLimit, min(verticalLimit, orbitalAngleVertical))
                            //
                            //                            updateOrbitalCamera()
                            //
                            //                            lastDragTranslationX = value.translation.width
                            //                            lastDragTranslationY = value.translation.height
                            return
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
            //            .simultaneousGesture(
            //                isZooming ? nil : MagnificationGesture()
            //                    .onChanged { value in
            //                        guard isZoomedIn else { return }
            //                        let zoomSensitivity: Float = 0.1
            //                        let scaleChange = Float(value - 1.0) * zoomSensitivity
            //                        let newRadius = orbitalRadius * (1.0 - scaleChange)
            //                        orbitalRadius = max(1.0, min(5.0, newRadius))
            //                        updateOrbitalCamera()
            //                    }
            //            )
            if showLockMessage {
                VStack{
                    Text(lockMessageText)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(10)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.3), value: showLockMessage)
                    Spacer()
                }
                .padding(24)
            }
            
            HStack {
                Spacer()
                VStack{
                    ForEach(inventory, id: \.self) { item in
                        Inventory(level: level.sceneFile, nodeName: item, isFlashlightOn: .constant(false))
                    }
                }
            }
            .padding(24)
            
            if isZoomedIn {
                VStack {
                    Spacer()
                    HStack {
                        Button(action: {
                            zoomOut()
                        }) {
                            Text("Back")
                                .padding(.horizontal, 120)
                                .padding(.vertical, 12)
                                .background(Color.black.opacity(0.4))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            
            VStack {
                HStack(spacing: 16) {
                    HintButtonComponent(currentState: gameManager.currentState)
                }
            }
            
            VStack {
                HStack {
                    ExitButtonComponent()
                }
            }
        }
        .onAppear {
            setupScene()
            BackgroundMusicPlayer.shared.stop()
            BackgroundMusicPlayer.shared.play(filename: "mystery")
        }
        .ignoresSafeArea(.all)
        .navigationBarBackButtonHidden(true)
        .fullScreenCover(item: $focusedObject) { object in
            FocusObjectView(sceneFile: level.sceneFile, nodeName: object.name, inventory: $inventory)
                .environmentObject(gameManager)
        }
        .fullScreenCover(isPresented: $showMicroscope) {
            MicroscopeView(sceneFile: level.sceneFile, inventory: $inventory)
        }
        .fullScreenCover(isPresented: $showGameCompletedPopup) {
            GameCompletionPopUp(onBackToMenu: exitToMainMenu)
        }
    }
    
    func exitToMainMenu() {
        BackgroundMusicPlayer.shared.stop()
        BackgroundMusicPlayer.shared.play(filename: "mystery")
        dismiss()  // 👈 This will actually pop InGameView
    }
    
    // Locked
    private func isLocked(_ name: String) -> Bool {
        switch name {
        case "Locker_1": return false
        case "Locker_2": return gameManager.currentState != .puzzle1_done
        case "Locker_3": return gameManager.currentState != .puzzle3_done
        case "Cabinet_1": return gameManager.currentState != .puzzle4_done
        case "Cabinet_2": return gameManager.currentState != .puzzle4_done
        case "Cabinet_3": return gameManager.currentState != .puzzle4_done
        case "Door": return gameManager.currentState != .puzzle5_done
        default: return true
        }
    }
    
    
    private func setupScene() {
        guard scene == nil else { return }
        
        let loadedScene = SCNScene(named: level.sceneFile) ?? SCNScene()
        
        if let roomNode = loadedScene.rootNode.childNode(withName: "root", recursively: true) {
            roomNode.eulerAngles = SCNVector3(x: -Float.pi / 2, y: 0, z: 0)
        }
        
        // Camera setting
        let camera = SCNCamera()
        camera.zNear = 0.01
        camera.zFar = 100
        camera.focalLength = 120
        camera.fStop = 1.8
        camera.focusDistance = 3
        
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = originalCameraPosition
        cameraNode.look(at: SCNVector3(0, 0.9, 0))
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
        
        let x = orbitalTarget.x + orbitalRadius * cos(orbitalAngleVertical) * sin(orbitalAngleHorizontal)
        let y = orbitalTarget.y + orbitalRadius * sin(orbitalAngleVertical)
        let z = orbitalTarget.z + orbitalRadius * cos(orbitalAngleVertical) * cos(orbitalAngleHorizontal)
        
        let newPosition = SCNVector3(x: x, y: y, z: z)
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.1
        cameraNode.position = newPosition
        cameraNode.look(at: orbitalTarget)
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
        let distance = Swift.max(maxDimension * 2.5, 5.0) // Minimum distance of 3 units
        
        // Special case for Cabinet_1 - move camera up by 1 unit on Y-axis
        var adjustedPosition = nodePosition
        if node.name == "Cabinet_1" {
            adjustedPosition.y += 1.0
            print("Special handling for Cabinet_1: Moving camera up by 1 unit")
        }
        
        zoomToPoint(adjustedPosition, distance: distance, nodeName: node.name)
    }
    
    private func zoomToPoint(_ point: SCNVector3, distance: Float = 3.0, nodeName: String? = nil) {
        guard let cameraNode = cameraNode else { return }
        
        isZooming = true
        
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
        let newCameraPosition = SCNVector3(
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
                self.isZooming = false
                
                self.lastDragTranslationX = 0
                self.lastDragTranslationY = 0
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
        
        isZooming = true
        
        // Begin smooth camera transition
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 1.0
        
        // Set the final position and rotation smoothly
        cameraNode.position = originalCameraPosition
        cameraNode.eulerAngles = originalCameraEulerAngles
        
        print("Camera position during zoom out: \(cameraNode.position)")
        print("Camera eulerAngles during zoom out: \(cameraNode.eulerAngles)")
        
        SCNTransaction.completionBlock = {
            DispatchQueue.main.async {
                print("Zoom out completed")
                self.isZoomedIn = false
                isZooming = false
            }
        }
        
        SCNTransaction.commit()
        
    }
}

#Preview {
    if let level = LevelLoader.loadLevels().first {
        InGameView(level: level)
    } else {
        Text("Failed to load level")
    }
}
