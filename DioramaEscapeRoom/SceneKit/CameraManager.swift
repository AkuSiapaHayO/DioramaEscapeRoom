//
//  CameraManager.swift
//  DioramaEscapeRoom
//
//  Created by Louis Mario Wijaya on 17/06/25.
//

import Foundation
import SceneKit

class CameraManager {
    func createCamera() -> SCNNode {
        
        //Add Manual Camera
        let cameraNode = SCNNode()
        let camera = SCNCamera()

        //Experiment with camera position
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(x: 4, y: 3, z: 4)
        cameraNode.look(at: SCNVector3(0, 1, 0))

        return cameraNode
    }
}
