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

    @EnvironmentObject var mixPlaybackManager: MixPlaybackManager
    @EnvironmentObject var themeManager: ThemeManager
    
    @State private var selectedMix: MixExport?
    
    var body: some View {
        
        ZStack {
            
            themeManager.theme.background
                .ignoresSafeArea()
            
            if mixes.isEmpty {
                Text("Henüz kayıt yok.")
                    .foregroundStyle(.secondary)
                emptyState
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 14) {
                        ForEach(mixes) { mix in
                            let isThisPlaying = (mixPlaybackManager.currentMixID == mix.id && mixPlaybackManager.isPlaying)
                            
                            MixCardView(
                                mix: mix,
                                onPlay: {
                                    guard let id = mix.id, let fileName = mix.fileName else { return }
                                    //print("▶️ recent mix play tapped")
                                    mixPlaybackManager.togglePlay(mixID: id, fileName: fileName)
                                },
                                isPlaying: isThisPlaying
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedMix = mix
                            }
                            .contextMenu {
                                Button(role: .destructive) {
                                    delete(mix)
                                } label: {
                                    Label("Sil", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
                .padding(.top, 8)
                
            }
            
        }
        .navigationTitle("Son Mixler")
        .navigationDestination(item: $selectedMix) { mix in
            MixDetailView(mix: mix)
        }
        
    }
    
    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "music.note.list")
                .font(.system(size: 42))
                .foregroundStyle(.white.opacity(0.75))
            
            Text("Henüz kayıt yok")
                .font(.headline)
                .foregroundStyle(.white)
            
            Text("İlk mixini oluşturup kaydettiğinde burada görünecek.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.72))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
        }
    }
    
    private func delete(_ mix: MixExport) {
        let store = MixStore(context: context)
        store.deleteMix(mix)
        mixPlaybackManager.stopAndReset()
    }
}
