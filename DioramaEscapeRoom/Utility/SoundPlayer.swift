//
//  SoundPlayer.swift
//  DioramaEscapeRoom
//
//  Created by Derend Marvel Hanson Prionggo on 22/06/25.
//

import Foundation
import SceneKit

class SoundPlayer {
    static let shared = SoundPlayer()
    
    private var cachedSources: [String: SCNAudioSource] = [:]
    
    private init() {}

    /// Plays a sound effect on a given SCNNode.
    /// - Parameters:
    ///   - name: Name of the sound file (e.g., `"click.wav"`)
    ///   - node: The `SCNNode` to attach the sound to
    ///   - positional: Whether the sound should be positional (3D spatial audio)
    ///   - volume: Volume of the sound (0.0 to 1.0)
    func playSound(named name: String, on node: SCNNode, positional: Bool = false, volume: Float = 1.0) {
        let audioSource: SCNAudioSource

        if let cached = cachedSources[name] {
            audioSource = cached
        } else {
            guard let newSource = SCNAudioSource(fileNamed: name) else {
                print("❌ SceneKitSoundPlayer: Failed to load sound: \(name)")
                return
            }

            newSource.load()
            newSource.volume = volume
            newSource.isPositional = positional
            newSource.loops = false
            newSource.shouldStream = false

            cachedSources[name] = newSource
            audioSource = newSource
        }

        let player = SCNAudioPlayer(source: audioSource)
        node.addAudioPlayer(player)
    }
}
