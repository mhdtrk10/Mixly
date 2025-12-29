//
//  EmptyTimelineAddButton.swift
//  Mixly
//
//  Created by Mehdi Oturak on 19.12.2025.
//

import SwiftUI

struct EmptyTimelineAddButton: View {
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 22))
                Text("Şarkı Ekle")
                    .font(.headline)
                Text("Mix’e başlamak için ilk parçanı ekle.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 100, height: 120)
            .background(Color.white.opacity(0.05))
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
        .foregroundColor(.white)
    }
}

