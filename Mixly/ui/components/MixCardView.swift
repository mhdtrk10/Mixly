//
//  MixCardView.swift
//  Mixly
//
//  Created by Mehdi Oturak on 5.03.2026.
//

import SwiftUI

struct MixCardView: View {
    let mix: MixExport
    let onPlay: () -> Void
    let isPlaying: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Button(action: onPlay) {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 44, height: 44)

                        Button(action: onPlay) {
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.subheadline)
                                .padding(10)
                                .background(.white.opacity(0.06))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .buttonStyle(.borderless)

                VStack(alignment: .leading, spacing: 4) {
                    Text(mix.title ?? "Untitled Mix")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Text("\(formatTime(mix.durationSec)) • \(formatDate(mix.createdAt))")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.white.opacity(0.45))
                    .font(.caption.weight(.semibold))
            }

            MiniWaveformView(isPlaying: isPlaying)
                .frame(height: 26)
        }
        
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    isPlaying ? Color.accentColor : Color.white.opacity(0.08),
                    lineWidth: isPlaying ? 1.2 : 1
                )
        )
        .shadow(color: Color.black.opacity(0.18), radius: 10, x: 0, y: 5)
    }
}


