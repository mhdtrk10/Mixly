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
    
    
    enum PlaybackMode: String, CaseIterable {
        case playList
        case multiTrack
    }
    @Published var playbackMode: PlaybackMode = .multiTrack
    
    @Published var tracks: [AudioSegment] = [] // birden fazla şarkı için
    @Published var selectedTrackIndex: Int? = nil // şuan seçili satır
    @Published var isPlaying: Bool = false
    @Published var currentSec: Double = 0 // sadece seçili track için playhead
    
    private var currentSegment: AudioSegment? {
        guard let idx = selectedTrackIndex, tracks.indices.contains(idx) else { return nil }
        return tracks[idx]
    }
    
    private let singleEngine = SingleTrackAudioEngine()
    private let multiEngine = MultiTrackAudioEngine()
    private var accessedURLs: Set<URL> = []
    
    
    private var progressTask: Task<Void, Never>?
    private var playStartedAt: Date?

    private var timer: Timer?
    
    private var playListStartIndex: Int?
    
    
    // Dosya seçimi (fileImporter dönüşü)
    func handlePick(result: Result<URL, Error>) {
        guard case .success(let url) = result else { return }

        // Eğer çalıyorsa durdur ve progress task'i temizle
        if isPlaying {
            singleEngine.stop()
            multiEngine.stop()
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
            let wf = await loadWaveform(url: url)
            // 1) Yeni segment oluştur
            //let seg = AudioSegment(url: url, durationSec: dur)
            var seg = AudioSegment(url: url, durationSec: dur)
            seg.waveform = wf
            // 2) tracks listesine ekle
            tracks.append(seg)
            let newIndex = tracks.count - 1
            // 3) yeni eklenenin index'i
            selectedTrackIndex = newIndex

            // 4) playhead'i bu parçanın başlangıcına al
            currentSec = seg.startSec
            
            // 5) motoru bu parça ile hazırla
            if playbackMode == .playList {
                try? singleEngine.setSegment(seg)
            }

            
            try? multiEngine.setTracks(tracks)
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
            singleEngine.stop()
            multiEngine.stop()
            isPlaying = false
            stopProgressTask()
            return
        }
        
        switch playbackMode {
            // sadece tek şarkı yapıp sırayla çalmak için
        case .playList:
            playPlayList(from: index)
            
            // aynı anda istediği şarkıları çalmak için
        case .multiTrack:
            currentSec = 0
            try? multiEngine.setTracks(tracks)
            try? multiEngine.play()
        }
        isPlaying = true
        startProgressTask()
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
            //print("🎵 Demo yüklendi: \(name) (\(dur)s)")
            //let seg = AudioSegment(url: url, durationSec: dur)
            let wf = await loadWaveform(url: url)
            print("demo yüklendi: \(name) (\(dur)s) wfCount=\(wf.count)")
            var seg = AudioSegment(url: url, durationSec: dur)
            seg.waveform = wf
            // yeni track'i listeye ekle
            tracks.append(seg)
            selectedTrackIndex = tracks.count - 1
            currentSec = seg.startSec
            
            try? multiEngine.setTracks(tracks)
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
            
            // Mix / playlist moduna göre toplam süre
            let totalLength: Double = await MainActor.run {
                switch self.playbackMode {
                case .playList:
                    let startIdx = self.playListStartIndex ?? self.selectedTrackIndex ?? 0
                    guard self.tracks.indices.contains(startIdx) else { return 0 }
                    let slice = self.tracks[startIdx...]
                    return slice.map { $0.selectedLengthSec }.reduce(0, +)
                    
                case .multiTrack:
                    return self.tracks.map { $0.selectedLengthSec }.max() ?? 0
                }
            }
            
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: tick)
                
                
                await MainActor.run {
                    guard self.isPlaying else { return }
                    
                    let elapsed = Date().timeIntervalSince(self.playStartedAt ?? Date())
                    self.currentSec = elapsed

                    if elapsed >= totalLength {
                        self.singleEngine.stop()
                        self.multiEngine.stop()
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
        
        switch playbackMode {
        case .playList:
            if selectedTrackIndex == index {
                try? singleEngine.setSegment(seg)
            }
        case .multiTrack:
            try? multiEngine.setTracks(tracks)
        }
        
    }
    // MARK: Waveform fonksiyonu
    // Şarkının yaklaşık waveform'unu üret (örnek sayısı: 800)
    // Şarkının yaklaşık waveform'unu üret (RMS tabanlı, örnek sayısı: 400)
    private func loadWaveform(url: URL, samples: Int = 800) async -> [Float] {
        do {
            let file = try AVAudioFile(forReading: url)
            let format = file.processingFormat

            let frameCount = AVAudioFrameCount(file.length)
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
                return []
            }
            try file.read(into: buffer)

            guard let channelData = buffer.floatChannelData?[0] else { return [] }
            let frameLength = Int(buffer.frameLength)

            // Downsample: tüm dosyayı 'samples' parçaya bölelim
            let binSize = max(1, frameLength / samples)
            var result: [Float] = []
            result.reserveCapacity(samples)

            var i = 0
            while i < frameLength {
                let upper = min(i + binSize, frameLength)

                // 🔵 peak yerine RMS (ortalama enerji)
                var sumSquares: Float = 0
                var count: Int = 0
                var j = i
                while j < upper {
                    let v = channelData[j]
                    sumSquares += v * v
                    count += 1
                    j += 1
                }

                let rms: Float
                if count > 0 {
                    rms = sqrt(sumSquares / Float(count))   // 0…yaklaşık 1
                } else {
                    rms = 0
                }
                result.append(rms)
                i += binSize
            }

            // 0…1 arası normalize
            if let maxSample = result.max(), maxSample > 0 {
                // biraz daha kontrast için karekök al (soft compression)
                return result.map { sqrt($0 / maxSample) }
            } else {
                return result
            }
        } catch {
            print("⛔️ waveform error:", error.localizedDescription)
            return []
        }
    }
    private func playPlayList(from index: Int) {
        guard tracks.indices.contains(index) else { return }
        
        playListStartIndex = index
        selectedTrackIndex = index
        
        playTrack(at: index)
    }
    private func playTrack(at index: Int) {
        guard tracks.indices.contains(index) else {
            // playlist bitişi
            isPlaying = false
            stopProgressTask()
            singleEngine.stop()
            return
        }
        
        let seg = tracks[index]
        selectedTrackIndex = index
        currentSec = seg.startSec
        
        try? singleEngine.setSegment(seg)
        
        // bu track bittiğinde sıradakine geçiş
        try? singleEngine.play(onFinish: { [weak self] in
            guard let self else { return }
            
            DispatchQueue.main.async {
                let nextIndex = index + 1
                if self.playbackMode == .playList, self.isPlaying {
                    self.playTrack(at: nextIndex)
                } else {
                    self.isPlaying = false
                    self.stopProgressTask()
                }
            }
            
        })
    }
}

