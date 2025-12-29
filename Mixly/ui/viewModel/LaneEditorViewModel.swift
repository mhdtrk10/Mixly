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
    private let exporter = MultiLaneAudioExporter()
    struct EditingItem: Identifiable {
        let id = UUID()
        let laneID: UUID
        let itemID: UUID
        let sourceID: UUID
        let startSec: Double
        let endSec: Double
    }

    // Security scoped
    private var accessedURLs: Set<URL> = []

    // Playback engine (senin MultiLaneAudioEngine’in)
    private let playbackEngine = MultiLaneAudioEngine()

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
        print("security access:", ok, url.lastPathComponent)

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
    func addToNewLane(sourceID: UUID, start: Double, length: Double, timelineStartSec: Double = 0) {
        guard let src = sources.first(where: { $0.id == sourceID }) else { return }

        let safeStart = clamp(start, 0, src.durationSec)
        let safeLen   = clamp(length, 0, src.durationSec - safeStart)

        var lane = Lane(items: [])

        let item = LaneItem(
            sourceID: sourceID,
            sourceStartSec: safeStart,
            lengthSec: safeLen,
            timelineStartSec: max(0, timelineStartSec)
        )

        lane.items.append(item)
        lanes.append(lane)
        selectedLaneID = lane.id

        print("✅ addToNewLane CUSTOM:", sourceID, "t=\(timelineStartSec)", "src=\(safeStart)", "len=\(safeLen)")
    }

    /// Var olan lane'in sağına ekle. timelineStartSec verilmezse lane'in sonuna ekler.
    func addToRight(of laneID: UUID, sourceID: UUID, start: Double, length: Double, timelineStartSec: Double? = nil) {
        guard let src = sources.first(where: { $0.id == sourceID }) else { return }
        guard let laneIndex = lanes.firstIndex(where: { $0.id == laneID }) else { return }

        let safeStart = clamp(start, 0, src.durationSec)
        let safeLen   = clamp(length, 0, src.durationSec - safeStart)

        let laneEnd = lanes[laneIndex].items.map { $0.timelineEndSec }.max() ?? 0
        let tStart  = max(0, timelineStartSec ?? laneEnd)

        let item = LaneItem(
            sourceID: sourceID,
            sourceStartSec: safeStart,
            lengthSec: safeLen,
            timelineStartSec: tStart
        )

        lanes[laneIndex].items.append(item)
        selectedLaneID = laneID

        print("✅ addToRight CUSTOM:", sourceID, "t=\(tStart)", "src=\(safeStart)", "len=\(safeLen)")
    }

    // MARK: - Move item on timeline (drag)

    func moveItem(laneID: UUID, itemID: UUID, newTimelineStart: Double) {
        guard let laneIndex = lanes.firstIndex(where: { $0.id == laneID }) else { return }
        guard let itemIndex = lanes[laneIndex].items.firstIndex(where: { $0.id == itemID }) else { return }

        lanes[laneIndex].items[itemIndex].timelineStartSec = max(0, newTimelineStart)
    }

    // MARK: - Update source range (edit)

    func beginEdit(laneID: UUID, item: LaneItem) {
        let end = item.sourceStartSec + item.lengthSec
        editingItem = EditingItem(
            laneID: laneID,
            itemID: item.id,
            sourceID: item.sourceID,
            startSec: item.sourceStartSec,
            endSec: end
        )
    }

    func updateItem(laneID: UUID, itemID: UUID, start: Double, end: Double) {
        guard let laneIndex = lanes.firstIndex(where: { $0.id == laneID }) else { return }
        guard let itemIndex = lanes[laneIndex].items.firstIndex(where: { $0.id == itemID }) else { return }
        guard let src = sources.first(where: { $0.id == lanes[laneIndex].items[itemIndex].sourceID }) else { return }

        let s = clamp(start, 0, src.durationSec)
        let e = clamp(end, s, src.durationSec)
        let len = max(0, e - s)

        lanes[laneIndex].items[itemIndex].sourceStartSec = s
        lanes[laneIndex].items[itemIndex].lengthSec = len
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
    }
    func exportMix() async -> URL? {
        let fileName = "Mixly-\(UUID().uuidString).caf"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try exporter.export(
                lanes: lanes,
                sources: sources,
                outputURL: url
            )
            return url
        } catch {
            print("⛔️ export error:", error)
            return nil
        }
    }
}

