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
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(mix.title ?? "Untitled")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text("\(formatTime(mix.durationSec)) • \(formatDate(mix.createdAt))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: onPlay) {
                    
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.subheadline)
                        .padding(10)
                        .background(.black.opacity(0.06))
                        .clipShape(Circle())
                }
                .buttonStyle(.borderless)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}


