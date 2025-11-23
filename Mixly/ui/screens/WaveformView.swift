//
//  WaveformView.swift
//  Mixly
//
//  Created by Mehdi Oturak on 21.11.2025.
//

import SwiftUI


struct WaveformView: View {
    let samples: [Float]

    var body: some View {
        Canvas { ctx, size in
            guard !samples.isEmpty else { return }

            let midY = (size.height / 2)
            let stepX = (size.width / CGFloat(samples.count)) * 1.5

            var path = Path()
            for (idx, amp) in samples.enumerated() {
                let x = (CGFloat(idx) * stepX)
                let h = (CGFloat(amp) * (size.height / 2))

                // her sample için dikey bir çizgi
                path.move(to: CGPoint(x: x, y: midY - h))
                path.addLine(to: CGPoint(x: x, y: midY + h))
            }

            ctx.stroke(path,
                       with: .color(.white.opacity(0.9)),
                       lineWidth: 2.5)
        }
    }
}



