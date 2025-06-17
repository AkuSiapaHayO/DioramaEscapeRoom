import SceneKit

class RotationManager {
    private weak var roomNode: SCNNode?
    private var currentYRotation: Float = 0

    init(roomNode: SCNNode) {
        self.roomNode = roomNode
        self.currentYRotation = roomNode.eulerAngles.y
    }

    func applyRotation(delta: Float) {
        currentYRotation += delta
        roomNode?.eulerAngles.y = currentYRotation
    }

    func snapToNearestQuarterTurn(onComplete: @escaping () -> Void) {
        let turnAngle: Float = .pi / 2
        let snappedAngle = round(currentYRotation / turnAngle) * turnAngle
        let delta = snappedAngle - currentYRotation
        currentYRotation = snappedAngle

        let action = SCNAction.rotateBy(x: 0, y: CGFloat(delta), z: 0, duration: 0.3)
        action.timingMode = .easeInEaseOut

        roomNode?.runAction(action, completionHandler: {
            DispatchQueue.main.async {
                onComplete()
            }
        })
    }
}
