//
//  PlayHeadView.swift
//  Mixly
//
//  Created by Mehdi Oturak on 19.02.2026.
//


import SwiftUI

struct PlayheadView: View {
    let x: CGFloat
    let height: CGFloat

    var body: some View {
        Rectangle()
            .fill(Color.black.opacity(0.95))
            .frame(width: 2, height: height)
            .shadow(color: Color.red.opacity(0.35), radius: 6, x: 0, y: 0)
            .offset(x: x)
            .allowsHitTesting(false) 
    }
}
