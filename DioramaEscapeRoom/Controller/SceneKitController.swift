import SceneKit
import Combine

class SceneKitController: ObservableObject {
    var roomNode: SCNNode?
    private var rotationManager: RotationManager?

    func setRoomNode(_ node: SCNNode) {
        roomNode = node
        rotationManager = RotationManager(roomNode: node)
    }

    func rotateRoom(by delta: Float) {
        rotationManager?.applyRotation(delta: delta)
    }
    
    func snapRoomRotation() {
        rotationManager?.snapToNearestQuarterTurn(onComplete: { [weak self] in
            self?.updateWallVisibility()
        })
    }
    
    func updateWallVisibility() {
        guard let roomNode = roomNode else { return }

        let turnAngle: Float = .pi / 2
        let currentY = roomNode.eulerAngles.y

        // Round current angle to nearest 90°
        let index = Int(round(currentY / turnAngle)) % 4
        let visibleSides = [
            [3, 4],
            [1, 3],
            [2, 1],
            [4, 2]
        ]

        let activeSides = visibleSides[index < 0 ? index + 4 : index] // handle negative index

        for i in 1...4 {
            if let wall = roomNode.childNode(withName: "Wall_\(i)", recursively: true) {
                wall.isHidden = !activeSides.contains(i)
            }
        }
    }
}
