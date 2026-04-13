//
//  LaneEditorViewModel.swift
//  Mixly
//
//  Created by Mehdi Oturak on 18.12.2025.
//

import Foundation
import AVFoundation
import Combine

@MainActor
final class LaneEditorViewModel: ObservableObject {

    // MARK: - Published state
    @Published var sources: [AudioSource] = []
    @Published var lanes: [Lane] = []

    @Published var selectedLaneID: Lane.ID?
    @Published var isLoading: Bool = false
    @Published var isPlaying: Bool = false

    // Edit range sheet (lane item tıklanınca)
    @Published var editingItem: EditingItem? = nil
    
    @Published var playHeadSec: Double = 0
    
    private var playHeadTimer: DispatchSourceTimer?
    private var playStartTime: Double = 0
    
    private let exporter = MultiLaneAudioExporter()
    
    
    @Published var timelineHeight: CGFloat = 0
    
    struct EditingItem: Identifiable {
        let id = UUID()
        let laneID: UUID
        let itemID: UUID
        
        
        let sourceID: UUID
        let originalSourceID: UUID
        
        let startSec: Double
        let endSec: Double
        
        let volume: Float
        let rate: Float
        let reverbMix: Float
        let fadeInSec: Double
        let fadeOutSec: Double
    }

    // Security scoped
    private var accessedURLs: Set<URL> = []

    // Playback engine (senin MultiLaneAudioEngine’in)
    private let playbackEngine = MultiLaneAudioEngine()
    
    private let engine = MultiLaneAudioEngine()
    
    var mixTotalDurationSec: Double {
        lanes
            .flatMap { $0.items }
            .map { $0.timelineEndSec }
            .max() ?? 0
    }
    
    @Published var selectedItemID: UUID?
    
    var selectedItem: LaneItem? {
        guard let selectedItemID else { return nil }
        
        for lane in lanes {
            if let item = lane.items.first(where: {$0.id == selectedItemID}) {
                return item
            }
        }
        return nil
    }
    

    // MARK: - Source creation

    func createBundledSource(_ name: String, ext: String = "mp3") async -> UUID? {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            print("⛔️ Demo bulunamadı:", name, ext)
            return nil
        }

        isLoading = true
        defer { isLoading = false }

        let dur = await readDurationSec(url: url)
        let wf  = await loadWaveformSamples(url: url)

        var src = AudioSource(url: url, durationSec: dur)
        src.waveform = wf

        sources.append(src)
        return src.id
    }

    func addPickedSource(url: URL) {
        let ok = url.startAccessingSecurityScopedResource()
        if ok { accessedURLs.insert(url) }
        //print("security access:", ok, url.lastPathComponent)

        Task { @MainActor in
            isLoading = true
            defer { isLoading = false }

            let dur = await readDurationSec(url: url)
            let wf  = await loadWaveformSamples(url: url)

            var src = AudioSource(url: url, durationSec: dur)
            src.waveform = wf

            sources.append(src)
        }
    }

    // MARK: - Add items (custom: start/length source aralığı)

    /// Yeni lane'e ekle (timelineStartSec default 0)
    func addToNewLane(
        sourceID: UUID,
        originalSourceID: UUID,
        start: Double,
        length: Double,
        volume: Float = 1.0,
        rate: Float = 1.0,
        reverbMix: Float = 0,
        fadeInSec: Double = 0,
        fadeOutSec: Double = 0,
        timelineStartSec: Double = 0
    ) {
        guard let src = sources.first(where: { $0.id == sourceID }) else { return }

        let safeStart = clamp(start, 0, src.durationSec)
        let safeLen   = clamp(length, 0, src.durationSec - safeStart)

        var lane = Lane(items: [])

        let item = LaneItem(
            sourceID: sourceID,
            originalSourceID: originalSourceID,
            sourceStartSec: safeStart,
            lengthSec: safeLen,
            timelineStartSec: max(0, timelineStartSec),
            volume: volume,
            rate: rate,
            reverbMix: reverbMix,
            fadeInSec: fadeInSec,
            fadeOutSec: fadeOutSec
        )

        lane.items.append(item)
        lanes.append(lane)
        selectedLaneID = lane.id
        resetPlayHead()
    }

    /// Var olan lane'in sağına ekle. timelineStartSec verilmezse lane'in sonuna ekler.
    func addToRight(
        of laneID: UUID,
        sourceID: UUID,
        originalSourceID: UUID,
        start: Double,
        length: Double,
        volume: Float = 1.0,
        rate: Float = 1.0,
        reverbMix: Float = 0,
        fadeInSec: Double = 0,
        fadeOutSec: Double = 0,
        timelineStartSec: Double? = nil
    ) {
        guard let src = sources.first(where: { $0.id == sourceID }) else { return }
        guard let laneIndex = lanes.firstIndex(where: { $0.id == laneID }) else { return }

        let safeStart = clamp(start, 0, src.durationSec)
        let safeLen   = clamp(length, 0, src.durationSec - safeStart)

        let laneEnd = lanes[laneIndex].items.map { $0.timelineEndSec }.max() ?? 0
        let tStart  = max(0, timelineStartSec ?? laneEnd)

        let item = LaneItem(
            sourceID: sourceID,
            originalSourceID: originalSourceID,
            sourceStartSec: safeStart,
            lengthSec: safeLen,
            timelineStartSec: tStart,
            volume: volume,
            rate: rate,
            reverbMix: reverbMix,
            fadeInSec: fadeInSec,
            fadeOutSec: fadeOutSec
        )

        lanes[laneIndex].items.append(item)
        selectedLaneID = laneID
        resetPlayHead()
    }

    // MARK: - Move item on timeline (drag)

    func moveItem(laneID: UUID, itemID: UUID, newTimelineStart: Double) {
        guard let laneIndex = lanes.firstIndex(where: { $0.id == laneID }) else { return }
        guard let itemIndex = lanes[laneIndex].items.firstIndex(where: { $0.id == itemID }) else { return }

        lanes[laneIndex].items[itemIndex].timelineStartSec = max(0, newTimelineStart)
        resetPlayHead()
    }

    // MARK: - Update source range (edit)

    func beginEdit(laneID: UUID, item: LaneItem) {
        let end = item.sourceStartSec + item.lengthSec
        editingItem = EditingItem(
            laneID: laneID,
            itemID: item.id,
            sourceID: item.sourceID,
            originalSourceID: item.originalSourceID,
            startSec: item.sourceStartSec,
            endSec: end,
            volume: item.volume,
            rate: item.rate,
            reverbMix: item.reverbMix,
            fadeInSec: item.fadeInSec,
            fadeOutSec: item.fadeOutSec
        )
        
    }

    func updateItem(
        laneID: UUID,
        itemID: UUID,
        originalSourceID: UUID,
        start: Double,
        end: Double,
        volume: Float,
        rate: Float,
        reverbMix: Float,
        fadeInSec: Double,
        fadeOutSec: Double
    ) async {
        
        guard let laneIndex = lanes.firstIndex(where: { $0.id == laneID }) else { return }
        guard let itemIndex = lanes[laneIndex].items.firstIndex(where: { $0.id == itemID }) else { return }
        guard let originalSrc = sources.first(where: { $0.id == originalSourceID }) else {
            print("❌ original source bulunamadı")
            return
        }

        let s = clamp(start, 0, originalSrc.durationSec)
        let e = clamp(end, s, originalSrc.durationSec)

        guard let processedURL = await createProcessedClip(
            sourceURL: originalSrc.url,
            startSec: s,
            endSec: e,
            volume: volume,
            rate: rate,
            reverbMix: reverbMix,
            fadeInSec: fadeInSec,
            fadeOutSec: fadeOutSec
        ) else {
            print("❌ processed clip üretilemedi")
            return
        }

        guard let newSource = await makeProcessedSource(
            from: processedURL,
            originalName: originalSrc.displayName
        ) else {
            print("❌ newSource oluşturulamadı")
            return
        }

        sources.append(newSource)

        let newLength = newSource.durationSec

        lanes[laneIndex].items[itemIndex].sourceID = newSource.id
        lanes[laneIndex].items[itemIndex].originalSourceID = originalSourceID

        lanes[laneIndex].items[itemIndex].sourceStartSec = 0
        lanes[laneIndex].items[itemIndex].lengthSec = newLength

        lanes[laneIndex].items[itemIndex].volume = volume
        lanes[laneIndex].items[itemIndex].rate = rate
        lanes[laneIndex].items[itemIndex].reverbMix = reverbMix
        lanes[laneIndex].items[itemIndex].fadeInSec = fadeInSec
        lanes[laneIndex].items[itemIndex].fadeOutSec = fadeOutSec

        resetPlayHead()
    }

    // MARK: - Selection

    func selectLane(_ id: UUID) {
        selectedLaneID = id
    }

    // MARK: - Playback

    func togglePlay() {
        if isPlaying {
            playbackEngine.stop()
            isPlaying = false
            return
        }
        do {
            try playbackEngine.play(lanes: lanes, sources: sources) // timelineStartSec'e göre çalar
            isPlaying = true
        } catch {
            print("⛔️ play error:", error)
            isPlaying = false
        }
    }

    // MARK: - Utils

    private func clamp(_ v: Double, _ minV: Double, _ maxV: Double) -> Double {
        max(minV, min(v, maxV))
    }

    func readDurationSec(url: URL) async -> Double {
        let asset = AVURLAsset(url: url)
        do {
            let duration = try await asset.load(.duration)
            let seconds = CMTimeGetSeconds(duration)
            return seconds.isFinite ? seconds : 0
        } catch {
            print("duration load error", error)
            return 0
        }
    }

    private func loadWaveformSamples(url: URL) async -> [Float] {
        // Şimdilik fake; sonra gerçek waveform çıkarırız
        let count = 400
        return (0..<count).map { _ in Float.random(in: 0.1...1.0) }
    }

    deinit {
        accessedURLs.forEach { $0.stopAccessingSecurityScopedResource() }
        playHeadTimer?.cancel()
    }
    func exportMix() async -> URL? {
        let fileName = "Mixly-\(UUID().uuidString).caf"
        let cafURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try exporter.export(
                lanes: lanes,
                sources: sources,
                outputURL: cafURL
            )
            let m4aURL = try await convertCAFToM4A(inputURL: cafURL)
            
            return m4aURL
        } catch {
            print("⛔️ export error:", error)
            return nil
        }
    }
    
    func removeItem(laneID: UUID, itemID: UUID) {
        guard let laneIndex = lanes.firstIndex(where: { $0.id == laneID}) else { return }
        lanes[laneIndex].items.removeAll { $0.id == itemID }
        
        if lanes[laneIndex].items.isEmpty {
            lanes.remove(at: laneIndex)
            if selectedLaneID == laneID {
                selectedLaneID = lanes.first?.id
            }
        }
        stopPlayBack()
    }
    
    func startPlayHead(from sec: Double = 0) {
        playHeadSec = sec
        playStartTime = CACurrentMediaTime() - sec
        stopPlayHead()
        
        let endSec = mixDurationSec()
        
        let t = DispatchSource.makeTimerSource(queue: .main)
        t.schedule(deadline: .now(), repeating: 1.0 / 30.0)
        t.setEventHandler { [weak self] in
            guard let self else { return }
            guard self.isPlaying else { return }
            
            let now = CACurrentMediaTime()
            let current = max(0, now - self.playStartTime)
            
            self.playHeadSec = current
            
            if endSec > 0, current >= endSec {
                // önce playhead'i sona sabitle
                self.playHeadSec = endSec
                
                // sonra stop (engine + timer + isPlaying false)
                self.stopPlayBackUIOnly()
            }
        }
        t.resume()
        playHeadTimer = t
        
    }
    
    func stopPlayHead() {
        playHeadTimer?.cancel()
        playHeadTimer = nil
    }
    func stopPlayBackUIOnly() {
        engine.stop()
        isPlaying = false
        stopPlayHead()
    }
    
    func startPlayBack() {

        let end = mixTotalDurationSec
        if end > 0, playHeadSec >= end {
            playHeadSec = 0
        }

        do {
            try engine.play(lanes: lanes, sources: sources, startAtSec: playHeadSec, leadInSec: 0.5)
            isPlaying = true
            startPlayHead(from: playHeadSec)
        } catch {
            print("play error:", error)
            stopPlayBack()
        }
    }
    func stopPlayBack() {
        guard isPlaying else { return }
        
        engine.stop()
        isPlaying = false
        stopPlayHead()
        //playHeadSec = 0
    }
    func mixDurationSec() -> Double {
        let maxEnd = lanes
            .flatMap { $0.items }
            .map { $0.timelineEndSec }
            .max() ?? 0
        return max(0, maxEnd)
    }
    func resetPlayHead() {
        if isPlaying {
            engine.stop()
            isPlaying = false
            stopPlayHead()
        }
        playHeadSec = 0
    }
    func restartPlayback() {
        // önce durdur
        engine.stop()
        isPlaying = false
        stopPlayHead()
        
        // başa sar
        playHeadSec = 0
        
        // istersen otomatik başlat:
        //startPlayBack()
    }
    func createPickedSource(_ url: URL) async -> UUID? {
        let ok = url.startAccessingSecurityScopedResource()
        if ok { accessedURLs.insert(url) }
        //print("security access:", ok, url.lastPathComponent)

        isLoading = true
        defer { isLoading = false }
        
        print("📁 picked file:", url.lastPathComponent)
        
        let dur = await readDurationSec(url: url)
        print("duration: ", dur)
        
        let wf  = await loadWaveformSamples(url: url)
        print("waveform samples: ", wf.count)
        
        
        var src = AudioSource(url: url, durationSec: dur)
        src.waveform = wf
        
        
        
        sources.append(src)
        return src.id
    }
    
    func handlePickedFile(
        result: Result<URL, Error>,
        addMode: LaneEditorView.AddMode,
        targetLaneID: UUID?,
        openRangeSheet: @escaping () -> Void,
        setPending: @escaping (UUID, LaneEditorView.AddMode, UUID?) -> Void
    ) {
        guard case .success(let url) = result else { return }

        Task { @MainActor in
            guard let sid = await createPickedSource(url) else { return }

            setPending(sid, addMode, targetLaneID)
            openRangeSheet()
        }
    }
    func convertCAFToM4A(inputURL: URL) async throws -> URL {
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")

        let asset = AVURLAsset(url: inputURL)

        guard let exportSession = AVAssetExportSession(
            asset: asset,
            presetName: AVAssetExportPresetAppleM4A
        ) else {
            throw NSError(domain: "Export", code: -1)
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .m4a

        await exportSession.export()

        if exportSession.status == .completed {
            return outputURL
        } else {
            throw exportSession.error ?? NSError(domain: "Export", code: -2)
        }
    }
    func updateVolume(itemID: UUID, volume: Float) {
        for laneIndex in lanes.indices {
            if let itemIndex = lanes[laneIndex].items.firstIndex(where: { $0.id == itemID } ) {
                lanes[laneIndex].items[itemIndex].volume = volume
                break
            }
        }
    }
    func createProcessedClip(
        sourceURL: URL,
        startSec: Double,
        endSec: Double,
        volume: Float,
        rate: Float
    ) async -> URL? {
        let asset = AVURLAsset(url: sourceURL)
        
        do {
            let tracks = try await asset.loadTracks(withMediaType: .audio)
            guard let track = tracks.first else { return nil }
            
            let composition = AVMutableComposition()
            guard let compTrack = composition.addMutableTrack(
                withMediaType: .audio,
                preferredTrackID: kCMPersistentTrackID_Invalid
            ) else { return nil }
            
            let startTime = CMTime(seconds: startSec, preferredTimescale: 600)
            let originalDuration = CMTime(seconds: endSec - startSec, preferredTimescale: 600)
            
            try compTrack.insertTimeRange(
                CMTimeRange(start: startTime, duration: originalDuration),
                of: track,
                at: .zero
            )
            
            let safeRate = max(0.1, rate)
            let scaledDuration = CMTime(
                seconds: (endSec - startSec) / Double(safeRate),
                preferredTimescale: 600
            )
            
            compTrack.scaleTimeRange(
                CMTimeRange(start: .zero, duration: originalDuration),
                toDuration: scaledDuration
            )
            
            let audioMix = AVMutableAudioMix()
            let params = AVMutableAudioMixInputParameters(track: compTrack)
            params.setVolume(volume, at: .zero)
            audioMix.inputParameters = [params]
            
            let outputURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("processed-\(UUID().uuidString).m4a")
            
            guard let exporter = AVAssetExportSession(
                asset: composition,
                presetName: AVAssetExportPresetAppleM4A
            ) else { return nil }
            
            exporter.outputURL = outputURL
            exporter.outputFileType = .m4a
            exporter.audioMix = audioMix
            
            await exporter.export()
            
            if exporter.status == .completed {
                return outputURL
            } else {
                print("❌ processed export failed:", exporter.error?.localizedDescription ?? "unknown")
                return nil
            }
        } catch {
            print("❌ processing error:", error.localizedDescription)
            return nil
        }
    }
    func makeProcessedSource(from url: URL, originalName: String) async -> AudioSource? {
        let duration = await readDurationSec(url: url)
        let waveform = await loadWaveformSamples(url: url)
        

        return AudioSource(
            id: UUID(),
            url: url,
            durationSec: duration,
            waveform: waveform,
            customDisplayName: "\(originalName)"
            
        )
    }
    
    func createProcessedClip(
        sourceURL: URL,
        startSec: Double,
        endSec: Double,
        volume: Float,
        rate: Float,
        reverbMix: Float,
        fadeInSec: Double,
        fadeOutSec: Double
    ) async -> URL? {
        do {
            let file = try AVAudioFile(forReading: sourceURL)
            let sourceFormat = file.processingFormat
            let sampleRate = sourceFormat.sampleRate

            let engine = AVAudioEngine()
            let player = AVAudioPlayerNode()
            let timePitch = AVAudioUnitTimePitch()
            let reverb = AVAudioUnitReverb()

            reverb.loadFactoryPreset(.mediumHall)
            reverb.wetDryMix = reverbMix
            timePitch.rate = rate

            engine.attach(player)
            engine.attach(timePitch)
            engine.attach(reverb)

            engine.connect(player, to: timePitch, format: sourceFormat)
            engine.connect(timePitch, to: reverb, format: sourceFormat)
            engine.connect(reverb, to: engine.mainMixerNode, format: sourceFormat)

            let outputURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("processed-\(UUID().uuidString).caf")

            let renderFormat = engine.mainMixerNode.outputFormat(forBus: 0)

            try engine.enableManualRenderingMode(
                .offline,
                format: renderFormat,
                maximumFrameCount: 4096
            )

            try engine.start()

            let safeRate = max(0.1, rate)
            let startFrame = AVAudioFramePosition(startSec * sampleRate)
            let originalFrames = AVAudioFramePosition((endSec - startSec) * sampleRate)
            let renderedFrames = AVAudioFramePosition(Double(originalFrames) / Double(safeRate))

            player.volume = volume

            player.scheduleSegment(
                file,
                startingFrame: startFrame,
                frameCount: AVAudioFrameCount(originalFrames),
                at: nil,
                completionHandler: nil
            )

            player.play()

            let outFile = try AVAudioFile(
                forWriting: outputURL,
                settings: renderFormat.settings
            )

            guard let buffer = AVAudioPCMBuffer(
                pcmFormat: engine.manualRenderingFormat,
                frameCapacity: engine.manualRenderingMaximumFrameCount
            ) else {
                print("❌ buffer oluşturulamadı")
                engine.stop()
                return nil
            }

            while engine.manualRenderingSampleTime < renderedFrames {
                let framesToRender = min(
                    buffer.frameCapacity,
                    AVAudioFrameCount(renderedFrames - engine.manualRenderingSampleTime)
                )

                let status = try engine.renderOffline(framesToRender, to: buffer)

                switch status {
                case .success:
                    
                    let totalFrames = renderedFrames
                    let currentFrame = engine.manualRenderingSampleTime
                    
                    let fadeInFrames = AVAudioFramePosition(fadeInSec * sampleRate)
                    let fadeOutFrames = AVAudioFramePosition(fadeOutSec * sampleRate)
                    
                    let channelCount = Int(buffer.format.channelCount)
                    
                    for frame in 0..<Int(buffer.frameLength) {
                        
                        let globalFrame = currentFrame + AVAudioFramePosition(frame)
                        var gain: Float = 1.0
                        
                        // Fade In
                        if fadeInFrames > 0 && globalFrame < fadeInFrames {
                            gain = Float(globalFrame) / Float(fadeInFrames)
                        }
                        
                        // Fade Out
                        if fadeOutFrames > 0 && globalFrame > (totalFrames - fadeOutFrames) {
                            let remaining = totalFrames - globalFrame
                            gain = min(gain, Float(remaining) / Float(fadeOutFrames))
                        }
                        
                        for ch in 0..<channelCount {
                            buffer.floatChannelData?[ch][frame] *= gain
                        }
                    }
                    
                    try outFile.write(from: buffer)

                case .insufficientDataFromInputNode:
                    break

                case .cannotDoInCurrentContext:
                    break

                case .error:
                    print("❌ offline render error")
                    engine.stop()
                    return nil

                @unknown default:
                    break
                }
            }
            let lengthSec = endSec - startSec
            guard lengthSec > 0.05 else {
                print("❌ zero length clip")
                return nil
            }

            player.stop()
            engine.stop()

            return outputURL

        } catch {
            print("❌ processed clip render error:", error.localizedDescription)
            return nil
        }
    }
}

