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
        
        print("=== Scene Node Hierarchy ===")
        printAllNodeNames(node: sourceScene.rootNode)
        print("============================")

        scene = SCNScene()
        scene.background.contents = UIColor.black

        objectNode = targetNode.clone()
        objectNode.name = "FocusObject"
        objectNode.position = SCNVector3Zero
        objectNode.eulerAngles = SCNVector3(x: .pi/3, y: 0, z: 0)
        objectNode.scale = SCNVector3(x: 4, y: 4, z: 4)
        
        rotationX = objectNode.eulerAngles.x
        rotationY = objectNode.eulerAngles.y

        scene.rootNode.addChildNode(objectNode)


        // Fit camera based on object size
        let (minBox, maxBox) = objectNode.boundingBox
        let size = SCNVector3(
            x: maxBox.x - minBox.x,
            y: maxBox.y - minBox.y,
            z: maxBox.z - minBox.z
        )
        let maxDimension = Swift.max(size.x, size.y, size.z)
        zoom = Swift.max(maxDimension * 2.5, 4)

      

        // Camera
        cameraNode = SCNNode()
        cameraNode.camera = {
            let cam = SCNCamera()
            cam.zNear = 0.01
            cam.zFar = 1000
            cam.fieldOfView = 55
            cam.focalLength = 80
            return cam
        }()
        cameraNode.position = SCNVector3(0, 0, zoom)
        scene.rootNode.addChildNode(cameraNode)
    }

    private func updateTransform() {
        objectNode.eulerAngles = SCNVector3(rotationX, rotationY, 0)
    }

    private func updateCamera() {
        cameraNode.position = SCNVector3(0, 0, zoom)
    }
    
    func degreesToRadians(_ degrees: Float) -> Float {
        return degrees * .pi / 180
    }

}

#Preview {
    FocusObjectView(sceneFile: "Level1.scn", nodeName: "Passcode_Machine")
}
