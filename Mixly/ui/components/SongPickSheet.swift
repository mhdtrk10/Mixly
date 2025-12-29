//
//  SongPickSheet.swift
//  Mixly
//
//  Created by Mehdi Oturak on 19.12.2025.
//

import SwiftUI

struct SongPickSheet: View {
    let demoSongs: [String]
    let onPick: (String) -> Void
    let onClose: () -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(demoSongs, id: \.self) { name in
                    Button {
                        onPick(name)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "music.note")
                            Text(name)
                        }
                    }
                }
            }
            .navigationTitle("Müzik Seç")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { onClose() }
                }
            }
        }
    }
}

