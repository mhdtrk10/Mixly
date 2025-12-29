//
//  AudioSource.swift
//  Mixly
//
//  Created by Mehdi Oturak on 18.12.2025.
//

import Foundation


struct AudioSource: Identifiable, Equatable {
    var id: UUID = UUID()
    
    // şarkı dosyasının urli
    let url: URL
    
    
    // şarkının toplam süresi
    let durationSec: Double
    
    // waveform örnekleri
    var waveform: [Float] = []
    
    // UI da göstermek için dosya adı
    var displayName: String {
        url.deletingPathExtension().lastPathComponent
    }
}
