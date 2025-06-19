//
//  RoomRotationManager.swift
//  DioramaEscapeRoom
//
//  Created by Daniel Fernando Herawan on 19/06/25.
//
import Foundation
import SceneKit

class RoomRotationManager: ObservableObject {
    private let roomNode: SCNNode
    private let pivotNode: SCNNode
    private var currentAngle: Float = 0.0
    private let hiddenWallConfig: [Int: [String]]

    init?(scene: SCNScene, hiddenWallConfig: [Int: [String]]) {
        guard let roomNode = scene.rootNode.childNode(withName: "root", recursively: true) else {
            return nil
        }

        self.roomNode = roomNode
        self.hiddenWallConfig = hiddenWallConfig

        pivotNode = SCNNode()
        pivotNode.position = SCNVector3(0, 0, 0)
        scene.rootNode.addChildNode(pivotNode)
        roomNode.removeFromParentNode()
        pivotNode.addChildNode(roomNode)

        currentAngle = roomNode.eulerAngles.y
    }

    func rotate(by delta: Float) {
        currentAngle += delta
        roomNode.eulerAngles.y = currentAngle
        updateWallsVisibility()
    }

    func snapToNearestCorner() {
        let quarterTurn: Float = .pi / 2
        let snappedAngle = round(currentAngle / quarterTurn) * quarterTurn
        currentAngle = snappedAngle

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.3
        roomNode.eulerAngles.y = currentAngle
        SCNTransaction.completionBlock = { [weak self] in
            self?.updateWallsVisibility()
        }
        SCNTransaction.commit()
    }

    private func updateWallsVisibility() {
        let rawAngle = round(currentAngle / (.pi / 2)) * 90
        let degree = ((Int(rawAngle) % 360) + 360) % 360 // Normalisasi ke 0–359
        let hiddenNames = hiddenWallConfig[degree] ?? []

        roomNode.enumerateChildNodes { node, _ in
            if node.name?.starts(with: "Wall_") == true {
                node.isHidden = hiddenNames.contains(node.name!)
            }
        }
    }
}

