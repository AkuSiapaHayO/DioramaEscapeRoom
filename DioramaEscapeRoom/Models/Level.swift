//
//  Level.swift
//  DioramaEscapeRoom
//
//  Created by Louis Mario Wijaya on 18/06/25.
//

import Foundation

struct Level: Identifiable, Codable, Hashable {
    var id: Int
    var name: String
    var sceneFile: String
    var mainMenuHiddenItems: [String]?
    var inGameHiddenItems: [String: [String]]?
}
