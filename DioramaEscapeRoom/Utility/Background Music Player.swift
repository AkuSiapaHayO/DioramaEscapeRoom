//
//  Background Music Player.swift
//  DioramaEscapeRoom
//
//  Created by Derend Marvel Hanson Prionggo on 22/06/25.
//

import Foundation
import AVFoundation

class BackgroundMusicPlayer {
    static let shared = BackgroundMusicPlayer()
    
    private var audioPlayer: AVAudioPlayer?
    
    private init() { }

    func play(filename: String, fileExtension: String = "mp3", volume: Float = 0.5, loop: Bool = true) {
        guard let url = Bundle.main.url(forResource: filename, withExtension: fileExtension) else {
            print("❌ BackgroundMusicPlayer: File \(filename).\(fileExtension) not found.")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = loop ? -1 : 0
            audioPlayer?.volume = volume
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            print("🎵 Playing background music: \(filename).\(fileExtension)")
        } catch {
            print("❌ Failed to play music: \(error.localizedDescription)")
        }
    }
    
    func stop() {
        audioPlayer?.stop()
    }

    func pause() {
        audioPlayer?.pause()
    }

    func resume() {
        audioPlayer?.play()
    }

    func setVolume(_ volume: Float) {
        audioPlayer?.volume = volume
    }

    var isPlaying: Bool {
        return audioPlayer?.isPlaying ?? false
    }
}
