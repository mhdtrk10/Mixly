//
//  InfoPill.swift
//  Mixly
//
//  Created by Mehdi Oturak on 5.03.2026.
//

import SwiftUI

struct InfoPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
