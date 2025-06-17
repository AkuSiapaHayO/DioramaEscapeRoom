import SwiftUI
import SceneKit

struct SceneKitView: UIViewRepresentable {
    @ObservedObject var controller: SceneKitController
    
    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()
        let scene = SCNScene()
        sceneView.scene = scene
        
        if let roomScene = SCNScene(named: "Room.scn") {
            let roomNode = roomScene.rootNode.clone()
            roomNode.eulerAngles.x = -.pi / 2
            roomNode.name = "Room"
            scene.rootNode.addChildNode(roomNode)
            controller.setRoomNode(roomNode)
            controller.updateWallVisibility()
        }
        
        // Add fixed camera
        let cameraManager = CameraManager()
        let cameraNode = cameraManager.createCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        sceneView.autoenablesDefaultLighting = true
        sceneView.allowsCameraControl = false
        sceneView.backgroundColor = .white
        
        // Add pan gesture recognizer
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        sceneView.addGestureRecognizer(panGesture)
        
        return sceneView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(controller: controller)
    }
    
    class Coordinator: NSObject {
        let controller: SceneKitController
        
        init(controller: SceneKitController) {
            self.controller = controller
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            let translation = gesture.translation(in: gesture.view)
            let deltaX = Float(translation.x)
            
            // Sensitivity: tweak this value to adjust how fast rotation feels
            let rotationDelta = deltaX * 0.01
            
            controller.rotateRoom(by: rotationDelta)
            
            gesture.setTranslation(.zero, in: gesture.view)
            
            if gesture.state == .ended {
                controller.snapRoomRotation()
            }
        }
    }
}

