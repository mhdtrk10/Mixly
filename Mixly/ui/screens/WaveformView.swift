//
//  WaveformView.swift
//  Mixly
//
//  Created by Mehdi Oturak on 21.11.2025.
//
import SwiftUI

struct WaveformView: View {
    let samples: [Float]
    var style: WaveformStyle = .init()

    var body: some View {
        Canvas { ctx, size in
            guard !samples.isEmpty else { return }

            let top = style.verticalInset
            let bottom = size.height - style.verticalInset
            let midY = (top + bottom) / 2

            let usableHalf = (bottom - top) / 2
            let stepX = size.width / CGFloat(samples.count)

            var path = Path()

            for (idx, amp) in samples.enumerated() {
                let x = CGFloat(idx) * stepX
                let a = CGFloat(max(0, min(1, amp))) // 0..1 clamp
                let h = a * usableHalf

                if style.mirror {
                    path.move(to: CGPoint(x: x, y: midY - h))
                    path.addLine(to: CGPoint(x: x, y: midY + h))
                } else {
                    // tek yön (alt bar gibi)
                    path.move(to: CGPoint(x: x, y: bottom - h))
                    path.addLine(to: CGPoint(x: x, y: bottom))
                }
            }

            ctx.stroke(
                path,
                with: .color(.white.opacity(style.opacity)),
                lineWidth: style.lineWidth
            )
        }
    }
}



