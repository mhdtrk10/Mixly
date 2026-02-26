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

    @Published var playingMixID: UUID?
    @Published var isPlaying: Bool = false

    private var player: AVAudioPlayer?

    func togglePlay(mixID: UUID, fileName: String) {
        // Aynı mix çalıyorsa durdur
        if playingMixID == mixID, isPlaying {
            stop()
            return
        }

        // Başka mix çalıyorsa onu durdur, yenisini başlat
        stop()

        do {
            let url = try MixLibrary.urlFor(fileName: fileName)
            let p = try AVAudioPlayer(contentsOf: url)
            p.prepareToPlay()
            p.play()

            player = p
            playingMixID = mixID
            isPlaying = true

        } catch {
            print("❌ Mix play error:", error.localizedDescription)
            stop()
        }
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        playingMixID = nil
    }
}
