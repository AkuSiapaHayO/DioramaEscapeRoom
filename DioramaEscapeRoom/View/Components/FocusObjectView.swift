import SwiftUI
import SceneKit

struct FocusObjectView: View {
    let sceneFile: String
    let nodeName: String
    
    @Environment(\.dismiss) private var dismiss

    @State private var scene = SCNScene()
    @State private var cameraNode = SCNNode()
    @State private var objectNode = SCNNode()
    @State private var rotationX: Float = 0.0
    @State private var rotationY: Float = 0.0
    @State private var rotationZ: Float = .pi
    @State private var zoom: Float = 5.0
    

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
            SceneView(
                scene: scene,
                pointOfView: cameraNode,
                options: [.autoenablesDefaultLighting],
                preferredFramesPerSecond: 60,
                antialiasingMode: .multisampling4X
            )
            .background(Color.black)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        rotationY += Float(value.translation.width) * 0.001
                        rotationX += Float(value.translation.height) * 0.001
                        updateTransform()
                    }
            )
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        zoom = max(1.0, min(zoom / Float(value), 20.0))
                        updateCamera()
                    }
            )
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
        ]
        let rotation2: Set<String> = [
            "Periodic_Table",
            
        ]

        print("=== Scene Node Hierarchy ===")
        printAllNodeNames(node: sourceScene.rootNode)
        print("============================")

        scene = SCNScene()
        scene.background.contents = UIColor.black

        // Prepare the object
        objectNode = targetNode.clone()
        objectNode.name = "FocusObject"
        objectNode.position = SCNVector3Zero
        
        if rotation1.contains(nodeName) {
            objectNode.eulerAngles = SCNVector3Zero
        } else if rotation2.contains(nodeName) {
            objectNode.eulerAngles = SCNVector3(x: .pi/2, y: 4.6, z: .pi)
        } else {
            objectNode.eulerAngles = SCNVector3(x: .pi/2, y: 0, z: .pi)
        }
        
        objectNode.scale = SCNVector3(x: 1, y: 1, z: 1)

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

}

#Preview {
    FocusObjectView(sceneFile: "Level1.scn", nodeName: "Calendar")
}
