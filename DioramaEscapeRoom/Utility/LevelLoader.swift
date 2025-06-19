//
//  LevelLoader.swift
//  DioramaEscapeRoom
//
//  Created by Louis Mario Wijaya on 18/06/25.
//

import Foundation

struct LevelLoader {
    static func loadLevels() -> [Level] {
        guard let url = Bundle.main.url(forResource: "Levels", withExtension: "json") else {
            print("levels.json not found")
            return[]
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let levels = try decoder.decode([Level].self, from: data)
            return levels
        } catch {
            print("Failed to load Levels.json: \(error)")
            return []
        }
    }
}
