//
//  MultiLaneAudioEngine.swift
//  Mixly
//
//  Created by Mehdi Oturak on 29.12.2025.
//

import AVFoundation
import Foundation
import Darwin.Mach


/// Timeline'a göre çoklu lane çalma motoru (MVP)
final class MultiLaneAudioEngine {

    struct Clip {
        let laneID: UUID
        let sourceURL: URL
        let timelineStartSec: Double
        let sourceStartSec: Double
        let lengthSec: Double
    }

    private let engine = AVAudioEngine()
    private let mixer: AVAudioMixerNode

    private var players: [UUID: AVAudioPlayerNode] = [:]     // laneID -> player
    private var files: [URL: AVAudioFile] = [:]              // url cache

    private(set) var isPlaying: Bool = false

    init() {
        mixer = engine.mainMixerNode
    }

    func stop() {
        players.values.forEach { $0.stop() }
        engine.stop()
        isPlaying = false
    }

    /// lanes + sources'tan clip listesi üretip timeline'a göre çalar
    func play(
        lanes: [Lane],
        sources: [AudioSource],
        startAtSec: Double = 0,          // ✅ yeni
        leadInSec: Double = 0.5
    ) throws {
        stop()
        try prepareSessionIfNeeded()
        
        let clips = try buildClips(lanes: lanes, sources: sources)
        try setupPlayers(for: lanes)
        try engine.start()
        
        let startHost = currentHostTime() + secondsToHostTime(leadInSec)
        
        let clipsByLane = Dictionary(grouping: clips, by: { $0.laneID })
        
        for (laneID, laneClips) in clipsByLane {
            guard let player = players[laneID] else { continue }
            
            let ordered = laneClips.sorted { $0.timelineStartSec < $1.timelineStartSec }
            
            for c in ordered {
                // ✅ startAtSec’ten önce başlayanları atla / kes
                let clipEnd = c.timelineStartSec + c.lengthSec
                if clipEnd <= startAtSec { continue } // tamamen geride kaldı
                
                // clip'in timeline'daki efektif başlangıcı
                let effectiveTimelineStart = max(c.timelineStartSec, startAtSec)
                
                // clip'in source içinde nereden başlanacağı (kırpma)
                let cut = effectiveTimelineStart - c.timelineStartSec
                let effectiveSourceStart = c.sourceStartSec + cut
                
                // kalan süre
                let effectiveLen = max(0, clipEnd - effectiveTimelineStart)
                
                let file = try cachedFile(for: c.sourceURL)
                let sr = file.processingFormat.sampleRate
                
                let startFrame = AVAudioFramePosition(effectiveSourceStart * sr)
                let frames = AVAudioFrameCount(max(0, effectiveLen * sr))
                guard frames > 0 else { continue }
                
                // ✅ schedule zamanı: (effectiveTimelineStart - startAtSec) kadar gecikme
                let clipHost = startHost + secondsToHostTime(effectiveTimelineStart - startAtSec)
                let when = AVAudioTime(hostTime: clipHost)
                
                player.scheduleSegment(file,
                                       startingFrame: startFrame,
                                       frameCount: frames,
                                       at: when,
                                       completionHandler: nil)
            }
            
            player.play(at: AVAudioTime(hostTime: startHost))
        }
        
        isPlaying = true
    }

    // MARK: - Helpers

    private func setupPlayers(for lanes: [Lane]) throws {
        // önce mevcut player'ları temizle
        players.values.forEach { p in
            p.stop()
            engine.detach(p)
        }
        players.removeAll()

        for lane in lanes {
            let p = AVAudioPlayerNode()
            engine.attach(p)
            engine.connect(p, to: mixer, format: nil)  // format nil => engine conversion yapar
            players[lane.id] = p
        }
    }

    private func cachedFile(for url: URL) throws -> AVAudioFile {
        if let f = files[url] { return f }
        let f = try AVAudioFile(forReading: url)
        files[url] = f
        return f
    }

    private func buildClips(lanes: [Lane], sources: [AudioSource]) throws -> [Clip] {
        var result: [Clip] = []

        for lane in lanes {
            for item in lane.items {
                guard let src = sources.first(where: { $0.id == item.sourceID }) else { continue }

                // timelineStartSec: item.timelineStartSec
                // sourceStartSec: item.sourceStartSec
                // lengthSec: item.lengthSec
                let clip = Clip(
                    laneID: lane.id,
                    sourceURL: src.url,
                    timelineStartSec: item.timelineStartSec,
                    sourceStartSec: item.sourceStartSec,
                    lengthSec: item.lengthSec
                )
                result.append(clip)
            }
        }

        return result
    }

    private func prepareSessionIfNeeded() throws {
        let s = AVAudioSession.sharedInstance()
        try s.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try s.setActive(true)
    }

    

    private func currentHostTime() -> UInt64 {
        mach_absolute_time()
    }

    private func secondsToHostTime(_ seconds: Double) -> UInt64 {
        var info = mach_timebase_info_data_t()
        mach_timebase_info(&info)

        // mach_absolute_time tick -> nanoseconds: tick * numer/denom
        // seconds -> ticks:
        let nanos = seconds * 1_000_000_000.0
        let ticks = nanos * Double(info.denom) / Double(info.numer)
        return UInt64(ticks)
    }
    func totalTimelineSec(lanes: [Lane]) -> Double {
        lanes.flatMap { $0.items }
            .map { $0.timelineStartSec + $0.lengthSec }
            .max() ?? 0
    }



}

