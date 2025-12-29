//
//  MultiLaneAudioExporter.swift
//  Mixly
//
//  Created by Mehdi Oturak on 29.12.2025.
//

import Foundation
import AVFoundation

final class MultiLaneAudioExporter {

    enum ExportError: Error {
        case cannotCreateFile
        case renderFailed
    }

    func export(
        lanes: [Lane],
        sources: [AudioSource],
        outputURL: URL
    ) throws {

        let engine = AVAudioEngine()
        let mixer = engine.mainMixerNode

        // Lane başına player
        var players: [UUID: AVAudioPlayerNode] = [:]
        for lane in lanes {
            let p = AVAudioPlayerNode()
            engine.attach(p)
            engine.connect(p, to: mixer, format: nil)
            players[lane.id] = p
        }

        // Output format (offline render formatı)
        let renderFormat = mixer.outputFormat(forBus: 0)
        let sr = renderFormat.sampleRate

        // Offline render mode
        try engine.enableManualRenderingMode(
            .offline,
            format: renderFormat,
            maximumFrameCount: 4096
        )

        try engine.start()

        // ✅ SAMPLE TIME bazlı schedule
        for lane in lanes {
            guard let player = players[lane.id] else { continue }

            let items = lane.items.sorted { $0.timelineStartSec < $1.timelineStartSec }

            for item in items {
                guard let src = sources.first(where: { $0.id == item.sourceID }) else { continue }
                let file = try AVAudioFile(forReading: src.url)

                let fileSR = file.processingFormat.sampleRate
                let startFrame = AVAudioFramePosition(item.sourceStartSec * fileSR)
                let frames = AVAudioFrameCount(item.lengthSec * fileSR)
                guard frames > 0 else { continue }

                // timelineStartSec → renderFormat sampleTime
                let startSample = AVAudioFramePosition(item.timelineStartSec * sr)
                let when = AVAudioTime(sampleTime: startSample, atRate: sr)

                player.scheduleSegment(
                    file,
                    startingFrame: startFrame,
                    frameCount: frames,
                    at: when,
                    completionHandler: nil
                )
            }

            // Offline timeline 0'dan başlat
            player.play(at: AVAudioTime(sampleTime: 0, atRate: sr))
        }

        // Output file (PCM settings ile yazıyoruz; sonra m4a encode adımı ekleyeceğiz)
        guard let outFile = try? AVAudioFile(forWriting: outputURL, settings: renderFormat.settings) else {
            throw ExportError.cannotCreateFile
        }

        // Render loop: timeline toplam frame kadar
        let totalSec = totalTimelineSec(lanes)
        let totalFrames = AVAudioFramePosition(totalSec * sr)

        let buffer = AVAudioPCMBuffer(
            pcmFormat: engine.manualRenderingFormat,
            frameCapacity: engine.manualRenderingMaximumFrameCount
        )!

        while engine.manualRenderingSampleTime < totalFrames {
            let framesToRender = buffer.frameCapacity
            let status = try engine.renderOffline(framesToRender, to: buffer)

            switch status {
            case .success:
                try outFile.write(from: buffer)
            case .insufficientDataFromInputNode:
                // offline'da bazen olur, devam
                break
            case .cannotDoInCurrentContext:
                break
            case .error:
                throw ExportError.renderFailed
            @unknown default:
                break
            }
        }

        engine.stop()
    }

    private func totalTimelineSec(_ lanes: [Lane]) -> Double {
        lanes.flatMap { $0.items }
            .map { $0.timelineStartSec + $0.lengthSec }
            .max() ?? 0
    }
}


