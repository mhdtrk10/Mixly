//
//  TrackRowView.swift
//  Mixly
//
//  Created by Mehdi Oturak on 14.11.2025.
//

import SwiftUI

import SwiftUI

struct TrackRowView: View {
    let index: Int
    let segment: AudioSegment
    let isSelected: Bool
    let pxPerSec: CGFloat
    let onChangeSelection: (Int, Double, Double) -> Void
    let onTapPlay: (Int) -> Void

    let height: CGFloat = 60
    let secondsShown: Double = 300
    
    var body: some View {
        let trackDuration = segment.durationSec
        let totalWidth = CGFloat(trackDuration) * pxPerSec
        let startX = CGFloat(segment.startSec) * pxPerSec
        let endX   = CGFloat(segment.endSec) * pxPerSec
        
        VStack(alignment: .leading, spacing: 4) {
            // şarkı adı
            Text(segment.url.lastPathComponent)
                .font(.caption)
                .foregroundColor(isSelected ? .primary : .secondary)
                .lineLimit(1)
            
            ZStack(alignment: .leading) {
                // arka plan
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.black.opacity(0.35))
                    .frame(width: totalWidth, height: height)
                
                // waveform - ses dalgası
                if let wf = segment.waveform, !wf.isEmpty {
                    WaveformView(samples: wf)
                        .frame(width: totalWidth, height: height)
                        .clipped()
                        
                }
                
                // seçili aralık
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.35))
                    .frame(width: max(endX - startX, 0), height: height)
                    .offset(x: startX)
                
                // handle'lar
                handleCircle
                    .offset(x: startX - 7, y: height / 2 - 7)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let sec = max(0,Double(value.location.x / pxPerSec))
                                onChangeSelection(index, sec, segment.endSec)
                            }
                    )
                
                handleCircle
                    .offset(x: endX - 7, y: height / 2 - 7)
                    .gesture (
                        DragGesture()
                            .onChanged { value in
                                let sec = max(0, Double(value.location.x / pxPerSec))
                                onChangeSelection(index, segment.startSec, sec)
                            }
                    )
            }
            .onTapGesture {
                onTapPlay(index)     // satıra tıklayınca çal/dur
            }
        }
        
        
    }
    private var handleCircle: some View {
        Circle()
            .fill(Color.white)
            .shadow(radius: 1)
            .frame(width: 14, height: 14)
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
                    .fill(Color.black.opacity(0.6))
                    .frame(width: 2, height: h)
                    .offset(x: CGFloat(i) * stepPx, y: (80 - h)/2)
            }
        }
        .frame(width: width)
    }
}

