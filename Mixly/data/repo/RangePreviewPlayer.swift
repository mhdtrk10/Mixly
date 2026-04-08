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
    @Published var durationSec: Double = 0
    
    
    private let timePitch = AVAudioUnitTimePitch()
    private let reverb = AVAudioUnitReverb()
    
    init() {
        engine.attach(player)
        engine.attach(timePitch)
        engine.attach(reverb)
        
        reverb.loadFactoryPreset(.mediumHall)
        reverb.wetDryMix = 0
        
        engine.connect(player, to: timePitch, format: nil)
        engine.connect(timePitch, to: reverb, format: nil)
        engine.connect(reverb, to: engine.mainMixerNode, format: nil)
        do {
            try engine.start()
        } catch {
            print("❌ engine start error:", error)
        }
    }

    func prepare(url: URL) {
        do {
            let file = try AVAudioFile(forReading: url)
            self.file = file
            self.sampleRate = file.processingFormat.sampleRate
            
            let frames = Double(file.length)
            self.durationSec = frames / sampleRate
            
            try prepareSessionIfNeeded()
            try startEngineIfNeeded()

        } catch {
            print("❌ prepare file error:", error.localizedDescription)
        }
    }

    func playRange(startSec: Double, endSec: Double, volume: Float, rate: Float, reverbMix: Float) {
        guard let file else { return }
        
        do {
            try prepareSessionIfNeeded()
            try startEngineIfNeeded()
        } catch {
            print("❌ preview engine/session error:", error.localizedDescription)
            return
        }
        
        stop()

        let lengthSec = max(0, endSec - startSec)
        guard lengthSec > 0.05 else { return }

        let startFrame = AVAudioFramePosition(startSec * sampleRate)
        let frames = AVAudioFrameCount(lengthSec * sampleRate)
        
        player.volume = volume
        timePitch.rate = rate
        reverb.wetDryMix = reverbMix
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
    private func prepareSessionIfNeeded() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try session.setActive(true)
    }

    private func startEngineIfNeeded() throws {
        if !engine.isRunning {
            engine.prepare()
            try engine.start()
        }
    }

    nonisolated deinit {
        player.stop()
        engine.stop()
    }
}
