//
//  WaveformStyle.swift
//  Mixly
//
//  Created by Mehdi Oturak on 30.12.2025.
//

import Foundation

struct WaveformStyle {
    var lineWidth: CGFloat = 1
    var verticalInset: CGFloat = 10   // üst-alt boşluk (padding gibi)
    var opacity: Double = 0.9
    var mirror: Bool = true           // üst+alt simetrik çiz
}
extension WaveformStyle {
    static let picker = WaveformStyle(lineWidth: 3, verticalInset: 6, opacity: 0.95, mirror: true)
    static let lane   = WaveformStyle(lineWidth: 1, verticalInset: 2, opacity: 0.65, mirror: true)
}
