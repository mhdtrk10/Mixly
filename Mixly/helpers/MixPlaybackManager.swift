//
//  MixPlaybackManager.swift
//  Mixly
//
//  Created by Mehdi Oturak on 26.02.2026.
//

import Foundation
import AVFoundation
import Combine

@MainActor
final class MixPlaybackManager: ObservableObject {

    @Published var currentMixID: UUID?
    @Published var isPlaying: Bool = false

    private var player: AVAudioPlayer?

    func togglePlay(mixID: UUID, fileName: String) {
        print("tap:", mixID, "current:", currentMixID as Any, "isPlaying:", isPlaying)
        // Aynı mix çalıyorsa durdur
        if currentMixID == mixID, isPlaying {
            player?.pause()
            isPlaying = false
            return
        }

        // aynı mix ama paused ise devam
        if currentMixID == mixID, !isPlaying {
            player?.play()
            isPlaying = true
            return
        }
        
        do {
            
            player?.stop()
            player = nil
            
            let url = try MixLibrary.urlFor(fileName: fileName)
            
            let p = try AVAudioPlayer(contentsOf: url)
            p.prepareToPlay()
            p.play()
            
            player = p
            currentMixID = mixID
            isPlaying = true

        } catch {
            print("❌ Mix play error:", error.localizedDescription)
            stopAndReset()
        }
    }

    func stopAndReset() {
        player?.stop()
        player = nil
        isPlaying = false
        currentMixID = nil
    }
}
