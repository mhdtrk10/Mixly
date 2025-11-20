//
//  MultiTrackAudioEngine.swift
//  Mixly
//
//  Created by Mehdi Oturak on 21.11.2025.
//

import Foundation
import AVFoundation

/// Birden fazla şarkıyı aynı anda çalmak için basit miks motoru
final class MultiTrackAudioEngine {
    private let engine = AVAudioEngine()
    private var players: [AVAudioPlayerNode] = []
    private var files: [AVAudioFile] = []
    private var segments: [AudioSegment] = []

    init() {
        // Şimdilik efekt yok: her player doğrudan mainMixer'a bağlanacak
    }

    /// Tüm track listesini motorla senkronla
    func setTracks(_ tracks: [AudioSegment]) throws {
        segments = tracks
        files.removeAll()

        // Eski player’ları sök
        players.forEach { p in
            engine.disconnectNodeOutput(p)
            engine.detach(p)
        }
        players.removeAll()

        // Yeni dosyaları aç
        for seg in tracks {
            do {
                let f = try AVAudioFile(forReading: seg.url)
                files.append(f)
            } catch {
                print("⛔️ AVAudioFile hata:", seg.url.lastPathComponent, error.localizedDescription)
            }
        }

        // Her track için yeni player
        for _ in tracks {
            let p = AVAudioPlayerNode()
            engine.attach(p)
            players.append(p)
        }

        // Bağlantı: tüm player → mainMixer
        let main = engine.mainMixerNode
        players.forEach { p in
            engine.connect(p, to: main, format: nil)
        }

        try startEngineIfNeeded()

        print("🔧 setTracks: players=\(players.count), files=\(files.count)")
    }

    /// Tüm track’lerin seçili aralıklarını aynı anda başlat
    func play() throws {
        guard !players.isEmpty, players.count == files.count else {
            print("⚠️ players/files uyumsuz"); return
        }

        // varsa eski çalma dursun
        players.forEach { $0.stop() }

        for i in 0..<players.count {
            let f = files[i]
            let seg = segments[i]

            let sr = f.processingFormat.sampleRate
            let startFrame = AVAudioFramePosition(seg.startSec * sr)
            let frames = AVAudioFrameCount(seg.selectedLengthSec * sr)
            guard frames > 0 else {
                print("⚠️ track \(i) için frames=0, atlanıyor")
                continue
            }

            print("🎚️ [\(i)] startSec=\(seg.startSec) endSec=\(seg.endSec)  startFrame=\(startFrame) frames=\(frames)")
            // hepsini t=0'da planlıyoruz → aynı anda başlarlar
            players[i].scheduleSegment(f,
                                       startingFrame: startFrame,
                                       frameCount: frames,
                                       at: nil,
                                       completionHandler: nil)
        }

        try startEngineIfNeeded()
        players.forEach { $0.play() }
        print("▶️ multi-track play")
    }

    func stop() {
        players.forEach { $0.stop() }
    }

    // MARK: - Audio session + engine başlatma

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
