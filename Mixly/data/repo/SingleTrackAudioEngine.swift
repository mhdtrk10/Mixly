//
//  SingleTrackAudioEngine.swift
//  Mixly
//
//  Created by Mehdi Oturak on 24.11.2025.
//

import Foundation
import AVFoundation


final class SingleTrackAudioEngine {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()

    private var file: AVAudioFile?
    private var segment: AudioSegment?
    private var onFinish: (() -> Void)?
    init() {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: nil)
    }

    // Hangi şarkıyı / aralığı çalacağımızı ayarla
    func setSegment(_ seg: AudioSegment?) throws {
        segment = seg
        if let seg {
            file = try AVAudioFile(forReading: seg.url)
        } else {
            file = nil
        }
        try startEngineIfNeeded()
    }

    // Seçili aralığı çal
    func play(onFinish: (() -> Void)? = nil) throws {
        guard let seg = segment, let f = file else { return }
        
        self.onFinish = onFinish
        player.stop()

        let sr = f.processingFormat.sampleRate
        let startFrame = AVAudioFramePosition(seg.startSec * sr)
        let frames = AVAudioFrameCount(seg.selectedLengthSec * sr)
        guard frames > 0 else { return }

        player.scheduleSegment(
            f,
            startingFrame: startFrame,
            frameCount: frames,
            at: nil
        ) { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.onFinish?()
            }
        }

        try startEngineIfNeeded()
        player.play()
    }

    func stop() {
        player.stop()
        onFinish = nil
    }

    // MARK: - Engine başlatma

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

