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
    
    //@Published var segment: AudioSegment?
    //@Published var isPlaying = false
    //@Published var currentSec: Double = 0   // timeline'da imlecin olduğu zaman (s)
    
    @Published var tracks: [AudioSegment] = [] // birden fazla şarkı için
    @Published var selectedTrackIndex: Int? = nil // şuan seçili satır
    @Published var isPlaying: Bool = false
    @Published var currentSec: Double = 0 // sadece seçili track için playhead
    
    private var currentSegment: AudioSegment? {
        guard let idx = selectedTrackIndex, tracks.indices.contains(idx) else { return nil }
        return tracks[idx]
    }
    
    //private let engine = SingleAudioEngine()
    private let engine = MultiTrackAudioEngine()
    private var accessedURLs: Set<URL> = []
    
    
    private var progressTask: Task<Void, Never>?
    private var playStartedAt: Date?

    private var timer: Timer?
    
    
    
    
    // Dosya seçimi (fileImporter dönüşü)
    func handlePick(result: Result<URL, Error>) {
        guard case .success(let url) = result else { return }

        // Eğer çalıyorsa durdur ve progress task'i temizle
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

            // 1) Yeni segment oluştur
            let seg = AudioSegment(url: url, durationSec: dur)

            // 2) tracks listesine ekle
            tracks.append(seg)

            // 3) yeni eklenenin index'i
            selectedTrackIndex = tracks.count - 1

            // 4) playhead'i bu parçanın başlangıcına al
            currentSec = seg.startSec

            // 5) motoru bu parça ile hazırla
            try? engine.setTracks(tracks)
        }
    }



    func togglePlay(for index: Int) {
        
        //guard let seg = segment else { print("⚠️ segment yok"); return }
        guard tracks.indices.contains(index) else {
            print("Geçersiz index:"); return
        }
        
        // önce seçili tracksi güncelle
        selectedTrackIndex = index
        
        if isPlaying {
            //print("⏹️ stop()")
            engine.stop()
            isPlaying = false
            stopProgressTask()
        } else {
            //print("▶️ play() çağrılıyor")
            // Mix play: tüm track'lerin seçili aralıklarını aynı anda çal
            currentSec = 0
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
            
            // yeni track'i listeye ekle
            tracks.append(seg)
            selectedTrackIndex = tracks.count - 1
            currentSec = seg.startSec
            
            try? engine.setTracks(tracks)
            //segment = seg
            //try? engine.setSegment(seg)
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
            
            // Mix'in toplam süresi
            let mixLength: Double = await MainActor.run {
                self.tracks.map{ $0.selectedLengthSec }.max() ?? 0
            }
            
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: tick)
                
                // Ana aktörden izole alanlara erişimi ana aktörde yap
                await MainActor.run {
                    guard self.isPlaying else { return }
                    
                    let elapsed = Date().timeIntervalSince(self.playStartedAt ?? Date())
                    self.currentSec = elapsed

                    if elapsed >= mixLength {
                        print("mix bitti: elapsed=\(elapsed), mixLength=\(mixLength)")
                        self.engine.stop()
                        self.isPlaying = false
                        self.progressTask?.cancel()
                    }
                }
            }
        }
    }

    private func stopProgressTask() {
        progressTask?.cancel()
        progressTask = nil
    }
    // MARK: - istediğimiz aralık kısmını ekleme
    func updateSelection(for index: Int, start: Double, end: Double) {
        //guard var seg = segment else { return }
        
        guard tracks.indices.contains(index) else { return }
        
        var seg = tracks[index]
        
        // clamp değerleri
        let s = max(0,min(start, seg.durationSec))
        let e = max(0,min(end, seg.durationSec))
        
        seg.startSec = min(s,e)
        seg.endSec = max(s,e)
        //segment = seg
        
        tracks[index] = seg
        
        //try? engine.setSegment(seg)
        /*
        if isPlaying {
            try? engine.play()
        }
         */
        // eğer bu satır seçili ise playhead'i de oraya alabilirsin
        if selectedTrackIndex == index {
            currentSec = seg.startSec
        }
        // bütün track'ler için motoru güncelle
        try? engine.setTracks(tracks)
    }
    
    

}

