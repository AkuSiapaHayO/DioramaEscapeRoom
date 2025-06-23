import SwiftUI
import SceneKit

struct FocusObjectView: View {
    let sceneFile: String
    let nodeName: String
    @Binding var inventory: [String]
    
    @State private var hasInsertedKey = false
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var scene = SCNScene()
    @State private var cameraNode = SCNNode()
    @State private var objectNode = SCNNode()
    @State private var rotationX: Float = 0.0
    @State private var rotationY: Float = 0.0
    @State private var rotationZ: Float = .pi
    @State private var lastDragTranslation = CGSize.zero
    @State private var zoom: Float = 5.0
    
    @State private var hasBookOpened = false
    @State private var openedFlasks: Set<String> = []
    @State private var isUVLightOn = false
    @State private var isTurningKey = false
    
    @State private var passcodeInput: String = ""
  
    @EnvironmentObject var gameManager: GameManager
    var body: some View {
        ZStack {
            Color.black
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
            InteractiveSceneView(scene: scene, enableDefaultLighting: true) { tappedNode in
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
                
                guard let target = targetNode, let tappedName = target.name else { return }
                
                print("🖱️ Tapped node: \(tappedName)")
                
                if tappedName.starts(with: "Numpad_") ||
                    tappedName.starts(with: "Key_") || tappedName.starts(with: "Codepad_") || tappedName.starts(with: "Num_"){
                    if let digit = tappedName.components(separatedBy: "_").last {
                        passcodeInput.append(digit)
                        print("🔢 Passcode so far: \(passcodeInput)")
                    }
                } else {
                    // fallback behavior like opening book/flask
                    switch nodeName {
                    case "Orange_Book":
                        toggleOrangeBook()
                    case "Flask_1", "Flask_2", "Flask_3", "Flask_4", "Hint_1", "Hint_2", "Hint_3", "Hint_4":
                        toggleFlask(flaskName: nodeName)
                    default:
                        break
                    }
                }
                
                if nodeName == "Passcode_Machine" {
                    if passcodeInput == "1268"{
                        gameManager.currentState = .gameFinished
                        dismiss()
                    }
                }
                
                if nodeName == "Lock_2" {
                    if passcodeInput == "2586"{
                        gameManager.currentState = .puzzle3_done
                        dismiss()
                    }
                }
                
                if nodeName == "Lock_1" {
                    if passcodeInput == "CoFFe"{
                        gameManager.currentState = .puzzle1_done
                        dismiss()
                    }
                }
                
                if nodeName == "Passcode_1" {
                    if passcodeInput == "357759"{
                        gameManager.currentState = .puzzle4_done
                        dismiss()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onChange(of: isUVLightOn) { _ in
                updateFlashlight()
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        guard !["Flask_1", "Flask_2", "Flask_3", "Flask_4"].contains(nodeName) else { return }
                        // Delta from last frame
                        let deltaX = Float(value.translation.width - lastDragTranslation.width)
                        let deltaY = Float(value.translation.height - lastDragTranslation.height)
                        
                        rotationY += deltaX * 0.01   // Try a slightly larger multiplier for smoother control
                        rotationX += deltaY * 0.01
                        
                        lastDragTranslation = value.translation
                        updateTransform()
                    }
                    .onEnded{_ in
                        lastDragTranslation = .zero
                    }
                
            )
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        zoom = max(0.1, min(zoom / Float(value), 3.0))
                        updateCamera()
                    }
            )
            .onTapGesture {
                switch nodeName {
                case "Orange_Book":
                    toggleOrangeBook()
                case "Flask_1", "Flask_2", "Flask_3", "Flask_4":
                    toggleFlask(flaskName: nodeName)
                default:
                    break
                }
            }
            .onAppear {
                setupScene()
            }
            .ignoresSafeArea()
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
            if let text = instructionText {
                HStack {
                    Text(text)
                        .multilineTextAlignment(.center)
                        .frame(width: 200)
                        .padding()
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .transition(.opacity)
                        .animation(.easeInOut, value: text)
                    Spacer()
                }
            }
            if nodeName.contains("Passcode") || nodeName.contains("Lock") {
                HStack {
                    Spacer()
                    VStack {
                        VStack{
                            Text("Passcode:")
                                .font(.system(size:17, weight: .bold))
                                .foregroundColor(.white)
                            ZStack {
                                // Centered passcode input text
                                Text(passcodeInput)
                                    .font(.system(size: 23, weight: .regular))
                                    .foregroundColor(.black)
                                
                                // Align the delete button to the right
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        if !passcodeInput.isEmpty {
                                            passcodeInput.removeLast()
                                        }
                                    }) {
                                        Image(systemName: "delete.left")
                                            .tint(Color.red)
                                    }
                                    
                                }
                            }
                            .padding(.horizontal, 8)
                            .frame(width: 180, height: 40)
                            .background(Color.white)
                            .cornerRadius(8)
                            .padding(.bottom, 6)
                            
                            Button(action: {
                                passcodeInput = ""
                            }) {
                                Text("Clear")
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 8)
                                    .font(.system(size:14, weight: .bold))
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            } else if nodeName == "Golden_Keyhole" || nodeName.contains("Flask") {
                HStack {
                    Spacer()
                    VStack{
                        ForEach(inventory, id: \.self) { item in
                            Inventory(
                                level: sceneFile,
                                nodeName: item,
                                isFlashlightOn: $isUVLightOn,
                                onTapAction: {
                                    if item == "Golden_Key" && nodeName == "Golden_Keyhole" {
                                        useGoldenKey()
                                    }
                                }
                            )
                        }
                    }
                }
                .padding(24)
            }
        }
    }
    
    
    func printAllNodeNames(node: SCNNode, indent: String = "") {
        if let name = node.name {
            print("\(indent)\(name)")
        }
        for child in node.childNodes {
            printAllNodeNames(node: child, indent: indent + "  ")
        }
    }
    
    private func setupScene() {
        guard let sourceScene = SCNScene(named: sceneFile) else {
            print("Failed to load scene: \(sceneFile)")
            return
        }
        
        guard let targetNode = sourceScene.rootNode.childNode(withName: nodeName, recursively: true) else {
            print("Could not find node: \(nodeName)")
            return
        }
        
        let rotation1: Set<String> = [
            "Willas___Hayya",
            "Paper_2",
            "Paper_1",
            "Window",
        ]
        let rotation2: Set<String> = [
            "Periodic_Table",
            "Blue_Book_1",
            "Blue_Book_3",
            "Green_Book_1",
            "Green_Book_2",
            "Green_Book_3",
            "Red_Book",
            "Red_Book_1",
            "Red_Book_3",
            "Photo_2",
        ]
        let rotation3: Set<String> = [
            "Calendar",
        ]
        let rotation4: Set<String> = [
            "Locker_1",
            "Locker_2",
            "Locker_3",
            "Lock_1",
            "Lock_2",
            "Lock_3",
        ]
        let rotation5: Set<String> = [
            "Science_Poster",
            "Photo_1",
        ]
        
        let rotation6: Set<String> = [
            "Flask_1",
            "Flask_2",
            "Flask_3",
            "Flask_4",
            "Passcode_1",
        ]
        
        let rotation7: Set<String> = [
            "Riddle_2",
            "Riddle_3"
        ]
        
        let rotation8: Set<String> = [
            "Riddle_1",
        ]
        
        let rotation9: Set<String> = [
            "Photo_4",
        ]
        
        scene = SCNScene()
        scene.background.contents = UIColor.clear
        
        // Prepare the object
        objectNode = targetNode.clone()
        //        objectNode.name = "FocusObject"
        objectNode.position = SCNVector3Zero
        
        if rotation1.contains(nodeName) {
            objectNode.eulerAngles = SCNVector3Zero
        } else if rotation2.contains(nodeName) {
            objectNode.eulerAngles = SCNVector3(x: .pi/2, y: 4.6, z: .pi)
        } else if rotation3.contains(nodeName){ objectNode.eulerAngles = SCNVector3(x: .pi, y: 0, z: .pi)
        } else if rotation4.contains(nodeName) {
            objectNode.eulerAngles = SCNVector3(x: .pi/2, y: .pi, z: .pi)
        } else if rotation5.contains(nodeName) {
            objectNode.eulerAngles = SCNVector3(x: .pi/2, y: -4.6, z: .pi)
        } else if rotation6.contains(nodeName) {
            objectNode.eulerAngles = SCNVector3(x: .pi/2, y: .pi, z: .pi)
        } else if rotation7.contains(nodeName) {
            objectNode.eulerAngles = SCNVector3(x: .pi/2, y: 0, z: .pi)
        } else if rotation8.contains(nodeName) {
            objectNode.eulerAngles = SCNVector3(x: -.pi/2, y: 4.6, z: 0)
        } else if rotation9.contains(nodeName) {
            objectNode.eulerAngles = SCNVector3(x: 0, y: 0, z: .pi/2)
        } else {
            objectNode.eulerAngles = SCNVector3(x: .pi/2, y: 0, z: .pi)
        }
        
        objectNode.scale = SCNVector3(x: 1, y: 1, z: 1)
        
        objectNode.enumerateChildNodes { child, _ in
            if let name = child.name, name.starts(with: "Hint_") {
                child.isHidden = true
                print("🙈 Recursively hiding \(name) on setup")
            }
        }
        
        // Calculate bounding box and pivot
        let (minBox, maxBox) = objectNode.boundingBox
        let size = SCNVector3(
            x: maxBox.x - minBox.x,
            y: maxBox.y - minBox.y,
            z: maxBox.z - minBox.z
        )
        let center = SCNVector3(
            x: (minBox.x + maxBox.x) / 2,
            y: (minBox.y + maxBox.y) / 2,
            z: (minBox.z + maxBox.z) / 2
        )
        objectNode.pivot = SCNMatrix4MakeTranslation(center.x, center.y, center.z)
        
        // Add object to scene
        scene.rootNode.addChildNode(objectNode)
        
        // Setup camera FIRST
        cameraNode = SCNNode()
        cameraNode.camera = {
            let cam = SCNCamera()
            cam.zNear = 0.01
            cam.zFar = 1000
            cam.fieldOfView = 55
            cam.focalLength = 80
            return cam
        }()
        scene.rootNode.addChildNode(cameraNode)
        
        // Now calculate zoom based on actual camera field of view
        let fovInRadians = (cameraNode.camera?.fieldOfView ?? 60) * .pi / 180.0
        let halfFOV = fovInRadians / 2
        let maxDimension = max(size.x, size.y, size.z)
        let tanHalfFOV = Float(tan(halfFOV))
        let baseDistance = maxDimension / (2 * tanHalfFOV)
        let distance = baseDistance + maxDimension
        zoom = distance
        
        // Apply zoom
        updateCamera()
        
        // Set initial rotation values
        rotationX = objectNode.eulerAngles.x
        rotationY = objectNode.eulerAngles.y
        rotationZ = objectNode.eulerAngles.z
    }
    
    private func updateTransform() {
        objectNode.eulerAngles = SCNVector3(rotationX, rotationY, rotationZ)
    }
    
    private func updateCamera() {
        cameraNode.position = SCNVector3(0, 0, zoom)
    }
    
    func degreesToRadians(_ degrees: Float) -> Float {
        return degrees * .pi / 180
    }
    
    private func toggleOrangeBook() {
        let half1 = objectNode.childNode(withName: "Orange_Book_Half_1", recursively: true)
        let half2 = objectNode.childNode(withName: "Orange_Book_Half_2", recursively: true)
        
        let duration: TimeInterval = 0.6
        
        if let leftHalf = half1, let rightHalf = half2 {
            if hasBookOpened {
                // 🔒 CLOSE book
                let closeLeft = SCNAction.rotateBy(x: 0, y: 0, z: .pi / 2, duration: duration)
                let closeRight = SCNAction.rotateBy(x: 0, y: 0, z: -.pi / 2, duration: duration)
                closeLeft.timingMode = .easeInEaseOut
                closeRight.timingMode = .easeInEaseOut
                
                leftHalf.runAction(closeLeft)
                rightHalf.runAction(closeRight)
                
                print("📕 Orange_Book closed")
            } else {
                // 📖 OPEN book
                let openLeft = SCNAction.rotateBy(x: 0, y: 0, z: -.pi / 2, duration: duration)
                let openRight = SCNAction.rotateBy(x: 0, y: 0, z: .pi / 2, duration: duration)
                openLeft.timingMode = .easeInEaseOut
                openRight.timingMode = .easeInEaseOut
                
                leftHalf.runAction(openLeft)
                rightHalf.runAction(openRight)
                
                print("📖 Orange_Book opened")
            }
            hasBookOpened.toggle()
        }
    }
    
    private func toggleFlask(flaskName: String) {
        let duration: TimeInterval = 0.5
        let rotateAngle: CGFloat = .pi / 2
        
        guard flaskName == objectNode.name else {
            print("⚠️ Object name mismatch: expected \(flaskName), got \(objectNode.name ?? "nil")")
            return
        }
        
        let flaskNode = objectNode
        
        // Pause user gestures while animating
        withAnimation(.easeInOut(duration: duration)) {
            if openedFlasks.contains(flaskName) {
                let rotateBack = SCNAction.rotateBy(x: rotateAngle, y: 0, z: 0, duration: duration)
                rotateBack.timingMode = .easeInEaseOut
                flaskNode.runAction(rotateBack)
                
                openedFlasks.remove(flaskName)
                print("🧪 \(flaskName) closed")
            } else {
                let rotateForward = SCNAction.rotateBy(x: -rotateAngle, y: 0, z: 0, duration: duration)
                rotateForward.timingMode = .easeInEaseOut
                flaskNode.runAction(rotateForward)
                
                openedFlasks.insert(flaskName)
                print("🧪 \(flaskName) opened")
            }
        }
    }
    
    private var instructionText: String? {
        switch nodeName {
        case "Orange_Book":
            return hasBookOpened ? "Tap to fold" : "Tap to unfold"
        case "Flask_1", "Flask_2", "Flask_3", "Flask_4":
            return openedFlasks.contains(nodeName) ? "Tap to rotate back" : "Tap to rotate flask"
        case "Microscope_1", "Microscope_2", "Microscope_3":
            return "Find a blank paper to view in the microscope"
        default:
            return nil
        }
    }
    
    private func updateFlashlight() {
        // Remove any existing spotlight
        scene.rootNode.childNodes.filter { $0.name == "UVSpotlight" }.forEach { $0.removeFromParentNode() }
        
        objectNode.enumerateChildNodes { child, _ in
            if let name = child.name, name.starts(with: "Hint_") {
                child.isHidden = !isUVLightOn
                print("🙈 Showing \(name)")
            }
        }
        
        guard isUVLightOn else { return }
        
        let spotlightNode = SCNNode()
        spotlightNode.name = "UVSpotlight"
        
        let spotlight = SCNLight()
        spotlight.type = .spot
        spotlight.color = UIColor.purple
        spotlight.intensity = 1000
        spotlight.spotInnerAngle = 0
        spotlight.spotOuterAngle = 23
        spotlight.castsShadow = true
        spotlightNode.light = spotlight
        
        spotlightNode.position = SCNVector3(x: 0, y: 0, z: zoom / 1.5)
        spotlightNode.look(at: SCNVector3Zero)
        
        scene.rootNode.addChildNode(spotlightNode)
    }
    
    private func useGoldenKey() {
        guard nodeName == "Golden_Keyhole", !hasInsertedKey else { return }
        gameManager.hasInsertedKey = true
        gameManager.advanceTo(.puzzle5_done)
        
        guard let sourceScene = SCNScene(named: sceneFile),
              let goldenKey = sourceScene.rootNode.childNode(withName: "Golden_Key", recursively: true),
              let keyholeNode = scene.rootNode.childNode(withName: "Golden_Keyhole", recursively: true) else {
            print("❌ Failed to load Golden_Key or Keyhole.")
            return
        }
        
        let clonedKey = goldenKey.clone()
        clonedKey.name = "InsertedGoldenKey"
        
        // Center the pivot based on bounding box
        let (minVec, maxVec) = clonedKey.boundingBox
        let center = SCNVector3(
            x: (minVec.x + maxVec.x) / 2,
            y: (minVec.y + maxVec.y) / 2,
            z: (minVec.z + maxVec.z) / 2
        )
        clonedKey.pivot = SCNMatrix4MakeTranslation(center.x, center.y, center.z)
        
        // Initial transform
        clonedKey.scale = SCNVector3(1, 1, 1)
        clonedKey.eulerAngles = SCNVector3(0, Float.pi, 0)
        
        // Start position: 5 units in front of keyhole
        let frontOfKeyholeWorld = keyholeNode.convertPosition(SCNVector3(5, 5, -5), to: nil)
        let frontOfKeyholeLocal = keyholeNode.convertPosition(frontOfKeyholeWorld, from: nil)
        clonedKey.position = frontOfKeyholeLocal
        
        keyholeNode.addChildNode(clonedKey)
        
        // 🔑 Animate move into keyhole, rotate, then rotate both key & keyhole
        let move = SCNAction.move(to: SCNVector3Zero, duration: 0.6)
        let rotate = SCNAction.rotateBy(x: .pi, y: .pi / 2, z: 0, duration: 0.6)
        
        let finishInsertion = SCNAction.run { _ in
            let rotate90 = SCNAction.rotateBy(x: 0, y: -CGFloat.pi / 2, z: 0, duration: 0.5)
            rotate90.timingMode = .easeInEaseOut
            
            clonedKey.runAction(rotate90)
            keyholeNode.runAction(rotate90)
        }
        
        let sequence = SCNAction.sequence([move, rotate, finishInsertion])
        sequence.timingMode = .easeInEaseOut
        let dismissAction = SCNAction.run { _ in
            print("🎬 Animation finished, dismissing view.")
            dismiss()
        }

        let fullSequence = SCNAction.sequence([move, rotate, finishInsertion, dismissAction])
        fullSequence.timingMode = .easeInEaseOut
        clonedKey.runAction(fullSequence)

    }
}

#Preview {
    FocusObjectView(sceneFile: "Science Lab Updated.scn", nodeName: "Passcode_Machine", inventory: .constant(["UV_Flashlight", "Golden_Key"]))
        .environmentObject(GameManager())
}
