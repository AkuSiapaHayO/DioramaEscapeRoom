//
//  SoundPlayer.swift
//  DioramaEscapeRoom
//
//  Created by Derend Marvel Hanson Prionggo on 22/06/25.
//

import Foundation
import SceneKit
import AVFoundation

class SoundPlayer {
    static let shared = SoundPlayer()
    
    private var cachedSources: [String: SCNAudioSource] = [:]
    private var audioPlayer: AVAudioPlayer?

    private init() {}

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

    /// Plays a non-positional sound without requiring a SCNNode (for SwiftUI Views)
    func playSoundUI(named name: String, volume: Float = 1.0) {
        guard let url = Bundle.main.url(forResource: name, withExtension: nil) else {
            print("❌ UI Sound: Failed to find sound: \(name)")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.volume = volume
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("❌ UI Sound: Failed to play sound \(name): \(error)")
        }
    }
}

