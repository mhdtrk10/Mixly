//
//  SingleTrackViewModel.swift
//  Mixly
//
//  Created by Mehdi Oturak on 15.11.2025.
//

import Foundation
import AVFoundation
import Combine

@MainActor
final class SingleTrackViewModel: ObservableObject {
    @Published var segment: AudioSegment?
    @Published var isPlaying = false

    private let engine = SingleAudioEngine()
    private var accessedURLs: Set<URL> = []
    
    @Published var currentSec: Double = 0   // timeline'da imlecin olduğu zaman (s)
    private var progressTask: Task<Void, Never>?
    private var playStartedAt: Date?

    private var timer: Timer?
    
    
    
    
    // Dosya seçimi (fileImporter dönüşü)
    func handlePick(result: Result<URL, Error>) {
        guard case .success(let url) = result else { return }

        // Eğer çalıyorsa durdur ve timer'ı temizle
        if isPlaying {
            engine.stop()
            isPlaying = false
            stopProgressTask()
        }

        // Files (sandbox dışı) için güvenlik erişimi aç
        let ok = url.startAccessingSecurityScopedResource()
        if ok { accessedURLs.insert(url) }
        print("security access:", ok, url.lastPathComponent)

        // Süreyi iOS 16+ için async güvenli şekilde yükle
        Task { @MainActor in
            let dur = await readDurationSec(url: url)
            print("🎵 seçildi: \(url.lastPathComponent)  süre: \(dur)s")

            // Tüm klibi seçili aralık olarak ayarla
            let seg = AudioSegment(url: url, durationSec: dur)
            segment = seg
            currentSec = seg.startSec          // playhead'i başa getir
            try? engine.setSegment(seg)        // motoru bu parça ile hazırla
        }
    }


    func togglePlay() {
        guard let seg = segment else { print("⚠️ segment yok"); return }
        if isPlaying {
            print("⏹️ stop()")
            engine.stop()
            isPlaying = false
            stopProgressTask()
        } else {
            print("▶️ play() çağrılıyor")
            // Playhead'i seçili başlangıca getir
            currentSec = seg.startSec
            try? engine.play()
            isPlaying = true
            startProgressTask()
        }
    }



    deinit {
        // Task’ı iptal et
        progressTask?.cancel()
        progressTask = nil

        // Security-scoped erişimleri bırak
        for url in accessedURLs {
            url.stopAccessingSecurityScopedResource()
        }
    }



    // iOS 16+: async duration, daha altı: sync
    private func readDurationSec(url: URL) async -> Double {
        let asset = AVURLAsset(url: url)
        if #available(iOS 16.0, *) {
            do { return CMTimeGetSeconds(try await asset.load(.duration)) }
            catch { return 0 }
        } else {
            return CMTimeGetSeconds(asset.duration)
        }
    }
    // MARK: - Demo ekleme (bundle'dan)
    func addBundledDemo(_ name: String, ext: String = "mp3") {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            print("⛔️ Demo dosyası bulunamadı: \(name).\(ext)")
            return
        }
        Task { @MainActor in
            let dur = await readDurationSec(url: url)
            print("🎵 Demo yüklendi: \(name) (\(dur)s)")
            let seg = AudioSegment(url: url, durationSec: dur)
            segment = seg
            try? engine.setSegment(seg)
        }
    }
    private func startProgressTask() {
        // Eski task varsa iptal et
        progressTask?.cancel()
        playStartedAt = Date()

        progressTask = Task { [weak self] in
            guard let self else { return }
            // 30 FPS = ~33ms
            let tick: UInt64 = 33_000_000

            while !Task.isCancelled {
                // Ana aktörden izole alanlara erişimi ana aktörde yap
                await MainActor.run {
                    guard self.isPlaying, let seg = self.segment else {
                        self.progressTask?.cancel()
                        return
                    }
                    let elapsed = Date().timeIntervalSince(self.playStartedAt ?? Date())
                    self.currentSec = min(seg.startSec + elapsed, seg.endSec)

                    if elapsed >= seg.selectedLengthSec {
                        self.engine.stop()
                        self.isPlaying = false
                        self.progressTask?.cancel()
                    }
                }
                try? await Task.sleep(nanoseconds: tick)
            }
        }
    }

    private func stopProgressTask() {
        progressTask?.cancel()
        progressTask = nil
    }
    // MARK: - istediğimiz aralık kısmını ekleme
    func updateSelection(start: Double, end: Double) {
        guard var seg = segment else { return }
        
        // clamp değerleri
        let s = max(0,min(start, seg.durationSec))
        let e = max(0,min(end, seg.durationSec))
        
        seg.startSec = min(s,e)
        seg.endSec = max(s,e)
        segment = seg
        
        try? engine.setSegment(seg)
        
        if isPlaying {
            try? engine.play()
        }
    }
    
    

}

