//
//  AudioMixEngine.swift
//  Mixly
//
//  Created by Mehdi Oturak on 12.11.2025.
//

import Foundation
import AVFoundation


final class AudioMixEngine {
    private let engine = AVAudioEngine()
    private var players: [AVAudioPlayerNode] = []
    private var files: [AVAudioFile] = []
    private var segments: [AudioSegment] = []
    
    private let eqUnit = AVAudioUnitEQ(numberOfBands: 2)
    private let dist = AVAudioUnitDistortion()
    
    private let renderSampleRate: Double = 44100
    private var renderFormat: AVAudioFormat {
        AVAudioFormat(standardFormatWithSampleRate: renderSampleRate, channels: 2)!
    }
    
    init() {
        // EQ varsayılanları
        let low = eqUnit.bands[0]; low.filterType = .lowShelf; low.frequency = 120; low.gain = 4; low.bypass = false
        let high = eqUnit.bands[1]; high.filterType = .highShelf; high.frequency = 8000; high.gain = 2; high.bypass = false
        
        dist.loadFactoryPreset(.multiDistortedCubed)
        dist.preGain = -12
        
        // Bu iki üniti bir kere attach et
        engine.attach(eqUnit)
        engine.attach(dist)
        
        
    }
    @MainActor
    private func startEngineIfNeeded() throws {
        // 1) Audio session’ı hazırla (önce kategori, sonra active)
        let s = AVAudioSession.sharedInstance()
        try? s.setCategory(.playback, mode: .default, options: [.mixWithOthers, .defaultToSpeaker])
        try s.setActive(true, options: [])
        
        // 2) Bağlantıların gerçekten var olduğundan emin olmak için prepare
        engine.prepare()
        
        // 3) Çalışmıyorsa başlat
        if !engine.isRunning {
            try engine.start()
        }
    }
    func setTracks(_ tracks: [AudioSegment]) throws {
        segments = tracks
        files = []
        for t in tracks {
            do {
                let f = try AVAudioFile(forReading: t.url)
                files.append(f)
            } catch {
                print("⛔️ AVAudioFile error:", error.localizedDescription)
            }
        }
        
        // önceki player’ları sök
        players.forEach { p in engine.disconnectNodeOutput(p); engine.detach(p) }
        players.removeAll()
        
        // yeni player’ları oluştur
        for _ in tracks {
            let p = AVAudioPlayerNode()
            engine.attach(p)
            players.append(p)
        }
        
        // zinciri kur: tüm player’lar -> EQ -> Dist -> Main
        let main = engine.mainMixerNode
        engine.disconnectNodeOutput(eqUnit)
        engine.disconnectNodeOutput(dist)
        
        players.forEach { p in
            engine.disconnectNodeOutput(p)
            engine.connect(p, to: eqUnit, format: nil)
        }
        engine.connect(eqUnit, to: dist, format: nil)
        engine.connect(dist, to: main, format: nil)
        
        if !engine.isRunning { try? engine.start() }
        
        print("🔧 setTracks: players=\(players.count) files=\(files.count)")
    }
    
    func playPreview() throws {
        guard !players.isEmpty, players.count == files.count else {
            print("⚠️ players/files uyumsuz")
            return
        }
        players.forEach { $0.stop() }
        
        for i in 0..<players.count {
            let f = files[i], s = segments[i]
            let sr = f.processingFormat.sampleRate
            let startFrame = AVAudioFramePosition(s.startSec * sr)
            let frames = AVAudioFrameCount(max(s.selectedLengthSec, 0) * sr)
            guard frames > 0 else { continue }
            players[i].scheduleSegment(f, startingFrame: startFrame, frameCount: frames, at: nil, completionHandler: nil)
        }
        
        if !engine.isRunning { try engine.start() }
        players.forEach { $0.play() }
        print("▶️ preview started")
    }
    
    func stopPreview() { players.forEach { $0.stop() } }
    
    func renderToFile(format: ExportFormat) throws -> URL {
        guard !players.isEmpty, players.count == files.count else {
            throw NSError(domain: "NoTracks", code: -1)
        }
        
        // toplam mix süresi: tüm seçili aralıkların maksimumu
        let mixLen = segments.map { $0.selectedLengthSec }.max() ?? 0
        guard mixLen > 0.01 else { throw NSError(domain: "ZeroLength", code: -2) }
        
        try engine.enableManualRenderingMode(.offline, format: renderFormat, maximumFrameCount: 4096)
        players.forEach { $0.stop() }
        if engine.isRunning { engine.stop() }
        try engine.start()
        
        // planla (t=0)
        for i in 0..<players.count {
            let f = files[i], s = segments[i]
            let sr = f.processingFormat.sampleRate
            let startFrame = AVAudioFramePosition(s.startSec * sr)
            let frames = AVAudioFrameCount(s.selectedLengthSec * sr)
            let t0 = AVAudioTime(sampleTime: 0, atRate: renderSampleRate)
            players[i].scheduleSegment(f, startingFrame: startFrame, frameCount: frames, at: t0, completionHandler: nil)
            players[i].play()
        }
        
        // çıkış dosyası
        let outURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("mix_\(UUID().uuidString).\(format.rawValue)")
        
        let settings: [String: Any] = (format == .m4a)
        ? [ AVFormatIDKey: kAudioFormatMPEG4AAC, AVSampleRateKey: renderSampleRate, AVNumberOfChannelsKey: 2, AVEncoderBitRateKey: 192_000 ]
        : [ AVFormatIDKey: kAudioFormatLinearPCM, AVSampleRateKey: renderSampleRate, AVNumberOfChannelsKey: 2, AVLinearPCMBitDepthKey: 16, AVLinearPCMIsFloatKey: false, AVLinearPCMIsBigEndianKey: false ]
        
        let outFile = try AVAudioFile(forWriting: outURL, settings: settings)
        
        let maxFrames: AVAudioFrameCount = 4096
        let buffer = AVAudioPCMBuffer(pcmFormat: engine.manualRenderingFormat, frameCapacity: maxFrames)!
        var remaining = AVAudioFramePosition(mixLen * renderSampleRate)
        
        while remaining > 0 {
            let n = AVAudioFrameCount(min(remaining, AVAudioFramePosition(maxFrames)))
            let status = try engine.renderOffline(n, to: buffer)
            if status == .success { try outFile.write(from: buffer) }
            else if status == .error { throw NSError(domain: "RenderError", code: -3) }
            remaining -= AVAudioFramePosition(n)
        }
        
        engine.disableManualRenderingMode()
        try? engine.start()
        return outURL
    }
}
