//
//  RecentMixesView.swift
//  Mixly
//
//  Created by Mehdi Oturak on 26.02.2026.
//

import SwiftUI
import CoreData

struct RecentMixesView: View {

    @Environment(\.managedObjectContext) private var context

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MixExport.createdAt, ascending: false)],
        animation: .default
    )
    private var mixes: FetchedResults<MixExport>

    @StateObject private var playback = MixPlaybackManager()   // ✅

    var body: some View {
        List {
            if mixes.isEmpty {
                Text("Henüz kayıt yok.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(mixes) { m in
                    mixRow(m)
                        .contentShape(Rectangle()) // ✅ boş alana tıklamayı da yakala
                        .onTapGesture {
                            guard
                                let id = m.id,
                                let fileName = m.fileName
                            else { return }

                            playback.togglePlay(mixID: id, fileName: fileName)
                        }
                }
                .onDelete(perform: delete)
            }
        }
        .navigationTitle("Son Mixler")
        .onDisappear {
            playback.stop() // ✅ ekrandan çıkınca çalmayı kes
        }
    }

    @ViewBuilder
    private func mixRow(_ m: MixExport) -> some View {
        let id = m.id
        let isThisPlaying = (id != nil && playback.playingMixID == id && playback.isPlaying)

        HStack(spacing: 12) {
            // ✅ Play icon
            Image(systemName: isThisPlaying ? "pause.circle.fill" : "play.circle.fill")
                .font(.system(size: 26))
                .foregroundStyle(Color.accentColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(m.title ?? "Mix")
                    .font(.headline)

                HStack(spacing: 10) {
                    if let d = m.createdAt {
                        Text(d.formatted(date: .abbreviated, time: .shortened))
                    }
                    Text("Lane: \(m.lanesCount)")
                    Text("\(Int(m.durationSec))s")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }

    private func delete(_ indexSet: IndexSet) {
        let store = MixStore(context: context)
        indexSet.map { mixes[$0] }.forEach { store.deleteMix($0) }
        playback.stop()
    }
}
