//
//  RangePickRow.swift
//  Mixly
//
//  Created by Mehdi Oturak on 25.12.2025.
//

import SwiftUI

struct RangePickRow: View {
    let durationSec: Double
    let waveform: [Float]
    let pxPerSec: CGFloat

    @Binding var startSec: Double
    @Binding var endSec: Double

    private let height: CGFloat = 56
    private let handleSize: CGFloat = 22

    var body: some View {
        let totalWidth = max(CGFloat(durationSec) * pxPerSec, 200)
        let startX = CGFloat(startSec) * pxPerSec
        let endX   = CGFloat(endSec) * pxPerSec

        ZStack(alignment: .leading) {
            
            
            
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.18))
                .frame(width: totalWidth, height: height)

            if !waveform.isEmpty {
                WaveformView(samples: waveform, style: .picker)
                .frame(width: totalWidth, height: height)
                .padding(.vertical, 8)
                .clipped()
            }


            // Sol karartma
            if startX > 0 {
                Rectangle()
                    .fill(Color.black.opacity(0.35))
                    .frame(width: startX, height: height)
            }

            // Sağ karartma
            if endX < totalWidth {
                Rectangle()
                    .fill(Color.black.opacity(0.35))
                    .frame(width: totalWidth - endX, height: height)
                    .offset(x: endX)
            }

            // SOL HANDLE (TrackRowView gibi: location.x)
            handleCircle
                .offset(x: startX - handleSize/2, y: height/2 - handleSize/2)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let sec = Double(value.location.x / pxPerSec)
                            startSec = clamp(sec, 0, endSec) // end'i geçmesin
                        }
                )

            // SAĞ HANDLE
            handleCircle
                .offset(x: endX - handleSize/2, y: height/2 - handleSize/2)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let sec = Double(value.location.x / pxPerSec)
                            endSec = clamp(sec, startSec, durationSec) // start'ın altına inmesin
                        }
                )
        }
        .frame(width: totalWidth, height: height)
    }

    private func clamp(_ v: Double, _ minV: Double, _ maxV: Double) -> Double {
        max(minV, min(v, maxV))
    }

    // TrackRowView'deki handle stiline yakın
    private var handleCircle: some View {
        Circle()
            .fill(Color.white)
            .frame(width: handleSize, height: handleSize)
            .shadow(color: Color.accentColor.opacity(0.5), radius: 6)
    }
}




