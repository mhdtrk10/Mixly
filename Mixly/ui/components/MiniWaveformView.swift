//
//  MiniWaveformView.swift
//  Mixly
//
//  Created by Mehdi Oturak on 6.03.2026.
//

import SwiftUI

struct MiniWaveformView: View {
    let isPlaying: Bool

    var body: some View {
        GeometryReader { geo in
            HStack(alignment: .center, spacing: 3) {
                ForEach(0..<32, id: \.self) { i in
                    Capsule()
                        .fill(isPlaying ? Color.white.opacity(0.5) : Color.accentColor.opacity(0.45))
                        .frame(
                            width: max(2, geo.size.width / 50),
                            height: [8, 12, 16, 10, 18, 7, 14, 20][i % 8]
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}
