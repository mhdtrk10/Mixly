//
//  RecentMixesView.swift
//  Mixly
//
//  Created by Mehdi Oturak on 26.02.2026.
//

import SwiftUI
import CoreData
import AVFoundation
struct RecentMixesView: View {

    @Environment(\.managedObjectContext) private var context

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \MixExport.createdAt, ascending: false)],
        animation: .default
    )
    private var mixes: FetchedResults<MixExport>

    @EnvironmentObject var playback: MixPlaybackManager
    
    
    
    
    
    var body: some View {
        List {
            if mixes.isEmpty {
                Text("Henüz kayıt yok.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(mixes) { m in
                    let isThisPlaying = (playback.currentMixID == m.id && playback.isPlaying)
                    
                    /*
                     mixRow(m)
                         .contentShape(Rectangle()) // ✅ boş alana tıklamayı da yakala
                         .onTapGesture {
                             guard
                                 let id = m.id,
                                 let fileName = m.fileName
                             else { return }

                             playback.togglePlay(mixID: id, fileName: fileName)
                         }
                     */
                    
                    ZStack {
                        NavigationLink {
                            MixDetailView(mix: m)
                        } label: {
                            //MixCardView(mix: m, onPlay: {togglePreview(m)}, isPlaying: playingMixID == m.id && isPlaying)
                            EmptyView()
                        }
                        .opacity(0)
                        
                        MixCardView(
                            mix: m,
                            onPlay: {
                                guard let id = m.id else { return }
                                guard let fileName = m.fileName else { return }
                                playback.togglePlay(mixID: id , fileName: fileName)
                            },
                            isPlaying: isThisPlaying)
                        
                    }
                    
                }
                .onDelete(perform: delete)
            }
        }
        .navigationTitle("Son Mixler")
        
    }
    /*
    private func togglePreview(_ mix: MixExport) {

        guard let fileName = mix.fileName else { return }

        let docs = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!

        let url = docs.appendingPathComponent(fileName)

        // aynı mix çalıyorsa pause
        if playingMixID == mix.id, isPlaying {
            player?.pause()
            isPlaying = false
            return
        }

        // başka mix seçildiyse yeniden başlat
        do {
            player?.stop()
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()

            playingMixID = mix.id
            isPlaying = true

        } catch {
            print("preview play error:", error)
        }
    }
     */
    /*
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
     */
    private func delete(_ indexSet: IndexSet) {
        let store = MixStore(context: context)
        indexSet.map { mixes[$0] }.forEach { store.deleteMix($0) }
        playback.stopAndReset()
    }
}
