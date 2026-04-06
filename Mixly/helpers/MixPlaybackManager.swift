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
        //print("🎯 togglePlay called")
        //print("mixID:", mixID)
        //print("fileName:", fileName)
        //print("currentMixID:", currentMixID as Any, "isPlaying:", isPlaying)

        // aynı mix çalıyorsa pause
        if currentMixID == mixID, isPlaying {
            //print("⏸️ pause current mix")
            player?.pause()
            isPlaying = false
            return
        }

        // aynı mix paused ise resume
        if currentMixID == mixID, !isPlaying {
            //print("▶️ resume current mix")
            player?.play()
            isPlaying = true
            return
        }

        do {
            player?.stop()
            player = nil

            let url = try MixLibrary.urlFor(fileName: fileName)
            //print("📂 resolved url:", url.path)
            //print("📂 file exists:", FileManager.default.fileExists(atPath: url.path))

            let p = try AVAudioPlayer(contentsOf: url)
            p.prepareToPlay()

            let played = p.play()
            //print("▶️ AVAudioPlayer play result:", played)

            player = p
            currentMixID = mixID
            isPlaying = played

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
