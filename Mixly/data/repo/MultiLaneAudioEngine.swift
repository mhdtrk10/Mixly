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
    func play(lanes: [Lane], sources: [AudioSource], leadInSec: Double = 0.5) throws {
        stop()
        try prepareSessionIfNeeded()

        // 1) Clip listesi
        let clips = try buildClips(lanes: lanes, sources: sources)

        // 2) Lane başına player kur
        try setupPlayers(for: lanes)

        // 3) Engine start
        try engine.start()

        // 4) Ortak başlangıç hostTime (küçük bir lead-in veriyoruz ki schedule yetişsin)
        let startHost = currentHostTime() + secondsToHostTime(leadInSec)


        // 5) Her lane'in player'ına schedule et
        // Lane bazında gruplayıp, timelineStart'a göre sırala
        let clipsByLane = Dictionary(grouping: clips, by: { $0.laneID })

        for (laneID, laneClips) in clipsByLane {
            guard let player = players[laneID] else { continue }

            // Aynı lane’de üst üste bindirme olmasın diye sırala
            let ordered = laneClips.sorted { $0.timelineStartSec < $1.timelineStartSec }

            for c in ordered {
                let file = try cachedFile(for: c.sourceURL)
                let sr = file.processingFormat.sampleRate

                let startFrame = AVAudioFramePosition(c.sourceStartSec * sr)
                let frames = AVAudioFrameCount(max(0, c.lengthSec * sr))

                guard frames > 0 else { continue }

                let clipHost = startHost + secondsToHostTime(c.timelineStartSec)
                let when = AVAudioTime(hostTime: clipHost)

                // 🎯 En kritik satır: timelineStartSec anında başlayacak şekilde schedule
                player.scheduleSegment(
                    file,
                    startingFrame: startFrame,
                    frameCount: frames,
                    at: when,
                    completionHandler: nil
                )

                print("🎚️ scheduled t=\(c.timelineStartSec) lane=\(laneID) src=\(c.sourceStartSec) len=\(c.lengthSec) \(c.sourceURL.lastPathComponent)")

            }

            // Player'ı da aynı ortak hostTime'da başlatıyoruz
            player.play(at: AVAudioTime(hostTime: startHost))
            print("▶️ lane \(laneID) started at host \(startHost)")

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
        try s.setCategory(.playback, mode: .default, options: [.mixWithOthers, .defaultToSpeaker])
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

