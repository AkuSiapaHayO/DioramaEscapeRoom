//
//  Interaction Zone.swift
//  DioramaEscapeRoom
//
//  Created by Derend Marvel Hanson Prionggo on 20/06/25.
//

import Foundation
import SceneKit

struct InteractionZone {
    let name: String
    let centerPosition: SCNVector3
    let radius: Float
    let zoomDistance: Float
    let heightOffset: Float
    
    init(name: String, centerPosition: SCNVector3, radius: Float = 2.0, zoomDistance: Float = 3.0, heightOffset: Float = 0.0) {
        self.name = name
        self.centerPosition = centerPosition
        self.radius = radius
        self.zoomDistance = zoomDistance
        self.heightOffset = heightOffset
    }
}
