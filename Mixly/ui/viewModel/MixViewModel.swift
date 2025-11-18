//
//  MixViewModel.swift
//  Mixly
//
//  Created by Mehdi Oturak on 12.11.2025.
//

import Foundation
import AVFoundation
import Combine

@MainActor
final class MixViewModel : ObservableObject {
    
    @Published var tracks: [AudioSegment] = []   // 0..2 arası (şimdilik en fazla 3)

    @Published var exporting = false
    @Published var canPreview = false
    @Published var exportFormat: ExportFormat = .m4a
    
    @Published var isPlaying = false
    
    private var accessedURLs: Set<URL> = []   // güvenli erişim seti
    
    private let engine = AudioMixEngine()
    
    
    func handlePick(result: Result<URL, Error>) {
        guard case .success(let url) = result else { return }
        
        // 1) security-scoped erişim
        let gotAccess = url.startAccessingSecurityScopedResource()
        if gotAccess { accessedURLs.insert(url) }
        
        Task { @MainActor in
            let dur = await readDurationSec(url: url)
            print("🎵 Seçildi: \(url.lastPathComponent)  süre: \(dur)s  access:\(gotAccess)")
            tracks.append(AudioSegment(url: url, durationSec: dur))
            refreshEngine()
        }
    }
    
    deinit {
        // (opsiyonel) erişimi bırak
        accessedURLs.forEach { $0.stopAccessingSecurityScopedResource() }
    }
    
    func updateRange(for index: Int, start: Double, end: Double) {
        guard tracks.indices.contains(index) else { return }
        func clamp(_ s: Double, _ e: Double, _ maxVal: Double) -> (Double, Double) {
            let s1 = Swift.max(0, Swift.min(s, maxVal))
            let e1 = Swift.max(0, Swift.min(e, maxVal))
            return (Swift.min(s1, e1), Swift.max(s1, e1))
        }
        var t = tracks[index]
        (t.startSec, t.endSec) = clamp(start, end, t.durationSec)
        tracks[index] = t
        refreshEngine()
    }

        //func onVolume1Change(_ v: Float) { engine.volume1 = v }
        //func onVolume2Change(_ v: Float) { engine.volume2 = v }
        //func onFXChange() { engine.bassBoostEnabled = bassBoost; engine.eqEnabled = eqEnabled }

    func playPreview() {
        if (try? engine.playPreview()) != nil {
            isPlaying = true
        }
    }
    func stopPreview() {
        engine.stopPreview()
        isPlaying = false
    }

    func exportMix(completion: @escaping (URL?) -> Void) {
        guard canPreview else { completion(nil); return }
        exporting = true
        let format = exportFormat   // MainActor'da kopyala
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let url = try? self.engine.renderToFile(format: format)
            DispatchQueue.main.async {
                self.exporting = false
                completion(url)
            }
        }
    }
    
    private func refreshEngine() {
        try? engine.setTracks(tracks)                    // 👈 artık dizi veriyoruz
        canPreview = tracks.count >= 2 && tracks.allSatisfy { $0.selectedLengthSec > 0 }
    }
    private func readDurationSec(url: URL) async -> Double {
        let asset = AVURLAsset(url: url)
        if #available(iOS 16.0, *) {
            do { return CMTimeGetSeconds(try await asset.load(.duration)) } catch { return 0 }
        } else {
            return CMTimeGetSeconds(asset.duration)
        }
    }
    func addBundledDemo(_ name: String, ext: String = "mp3") {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            print("⛔️ demo yok"); return
        }
        Task { @MainActor in
            let dur = await readDurationSec(url: url)
            tracks.append(AudioSegment(url: url, durationSec: dur))
            refreshEngine()
        }
    }
}
