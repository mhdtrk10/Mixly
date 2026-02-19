//
//  RangePreviewPlayer.swift
//  Mixly
//
//  Created by Mehdi Oturak on 23.01.2026.
//

import Foundation
import AVFoundation
import Combine

@MainActor
final class RangePreviewPlayer: ObservableObject {
    @Published var isPlaying: Bool = false

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private var file: AVAudioFile?
    private var sampleRate: Double = 44100

    init() {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: nil)
        do {
            try engine.start()
        } catch {
            print("❌ engine start error:", error)
        }
    }

    func prepare(url: URL) {
        do {
            let f = try AVAudioFile(forReading: url)
            file = f
            sampleRate = f.processingFormat.sampleRate
        } catch {
            print("❌ prepare file error:", error)
        }
    }

    func playRange(startSec: Double, endSec: Double) {
        guard let file else { return }

        stop()

        let lengthSec = max(0, endSec - startSec)
        guard lengthSec > 0.05 else { return }

        let startFrame = AVAudioFramePosition(startSec * sampleRate)
        let frames = AVAudioFrameCount(lengthSec * sampleRate)

        player.scheduleSegment(file,
                               startingFrame: startFrame,
                               frameCount: frames,
                               at: nil) { [weak self] in
            Task { @MainActor [weak self] in
                self?.isPlaying = false
            }
        }

        player.play()
        isPlaying = true
    }

    func stop() {
        if player.isPlaying { player.stop() }
        isPlaying = false
    }

    nonisolated deinit {
        player.stop()
        engine.stop()
    }
}
