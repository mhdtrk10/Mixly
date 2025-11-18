//
//  TrackRowView.swift
//  Mixly
//
//  Created by Mehdi Oturak on 14.11.2025.
//

import SwiftUI

import SwiftUI

struct TrackRowView: View {
    let title: String
    let duration: Double
    let startSec: Double
    let endSec: Double
    let color: Color
    let pxPerSec: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.isEmpty ? "Parça" : title)
                .font(.subheadline).foregroundColor(.secondary)
                .lineLimit(1)
            
            ZStack(alignment: .leading) {
                // 1) Placeholder waveform barları (gerçek waveform 2. aşama)
                PlaceholderWaveform(duration: duration, pxPerSec: pxPerSec)
                    .frame(height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.12), lineWidth: 1))
                
                // 2) Seçilen aralık görseli
                if endSec > startSec {
                    let x = CGFloat(startSec) * pxPerSec
                    let w = CGFloat(endSec - startSec) * pxPerSec
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.28))
                        .frame(width: w, height: 80)
                        .offset(x: x)
                        .overlay(
                            // basit tutacaklar (şimdilik görsel)
                            HStack {
                                Rectangle().fill(color.opacity(0.9)).frame(width: 3)
                                Spacer()
                                Rectangle().fill(color.opacity(0.9)).frame(width: 3)
                            }
                                .frame(width: w, height: 80)
                                .offset(x: x)
                        )
                }
            }
        }
    }
}

struct PlaceholderWaveform: View {
    let duration: Double
    let pxPerSec: CGFloat
    
    var body: some View {
        let width = max(CGFloat(duration) * pxPerSec, 600)
        // Basit dikey çubuklar: 0.1s aralıkla
        let stepPx: CGFloat = max(pxPerSec / 10, 2)
        let count = Int(width / stepPx)
        
        return ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.35))
            ForEach(0..<count, id: \.self) { i in
                // pseudo amplitude
                let amp = CGFloat((sin(Double(i) * 0.35) * 0.5 + 0.5)) // 0..1
                let h = 8 + amp * 64
                Rectangle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 2, height: h)
                    .offset(x: CGFloat(i) * stepPx, y: (80 - h)/2)
            }
        }
        .frame(width: width)
    }
}

