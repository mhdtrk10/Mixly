//
//  SingleAudioEngine.swift
//  Mixly
//
//  Created by Mehdi Oturak on 15.11.2025.
//

import Foundation
import AVFoundation

/// Sadece TEK parçayı çalmak için minimal motor
final class SingleAudioEngine {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()

    private var file: AVAudioFile?
    private var segment: AudioSegment?

    init() {
        engine.attach(player)
        // Basit zincir: player -> mainMixer
        engine.connect(player, to: engine.mainMixerNode, format: nil)
    }

    func setSegment(_ seg: AudioSegment?) throws {
        segment = seg
        if let seg {
            file = try AVAudioFile(forReading: seg.url)
        } else {
            file = nil
        }
        try startEngineIfNeeded()
    }

    func play() throws {
        guard let seg = segment, let f = file else { return }
        player.stop()

        let sr = f.processingFormat.sampleRate
        let startFrame = AVAudioFramePosition(seg.startSec * sr)
        let frames = AVAudioFrameCount(seg.selectedLengthSec * sr)
        print("🎚️ startFrame=\(startFrame) frames=\(frames) sr=\(sr)")
        guard frames > 0 else { print("⛔️ frames=0"); return }

        player.scheduleSegment(f, startingFrame: startFrame, frameCount: frames, at: nil, completionHandler: nil)
        try startEngineIfNeeded()
        player.play()
    }

    func stop() {
        player.stop()
    }

    // MARK: - Helpers
    private func startEngineIfNeeded() throws {
        let s = AVAudioSession.sharedInstance()
        try? s.setCategory(.playback, mode: .default, options: [.mixWithOthers, .defaultToSpeaker])
        try? s.setActive(true)

        engine.prepare()
        if !engine.isRunning {
            try engine.start()
        }
    }
}
