//
//  SingleEditorView.swift
//  Mixly
//
//  Created by Mehdi Oturak on 15.11.2025.
//

import SwiftUI
import UniformTypeIdentifiers
import AVFoundation

struct SingleEditorView: View {
    @StateObject private var vm = SingleTrackViewModel()
    @State private var showPicker = false
    // liste ekranı için
    @State private var showDemoSheet = false

    private let timelineWidth: CGFloat = 3000        // sabit genişlik (pt)
    private let secondsShown: Double = 300           // 5 dakika görünür alan
    private var pxPerSec: CGFloat { timelineWidth / CGFloat(secondsShown) }

    // Demo butonuna ekleyeceğim şarkıların isim uzantıları
    private let demoSongs: [String] = ["attention", "katy", "streets", "katyvocal"]
    
    init() {
        NavigationBarStyle.setupNavigationBar()
    }
    /*
    ClipTimelineView(clips: $vm.clips, tracks: vm.tracks, secondsShown: secondsShown, pxPerSec: pxPerSec, selectedClipID: $vm.selectedClipID, playheadSec: vm.playHeadSec)
        .padding(.leading, 12)
     */
    
    var body: some View {
        ZStack {
            Color(AppColors.Background)
                .ignoresSafeArea(edges: .all)
            
            VStack {
                
                // Yeni TimeLine alanı
                VStack {
                    ScrollView(.horizontal, showsIndicators: true) {
                        ScrollView(.vertical, showsIndicators: true) {
                            ZStack(alignment: .leading) {
                                VStack(alignment: .leading, spacing: 4) {
                                    
                                    TimeRulerView(totalSec: secondsShown, pxPerSec: pxPerSec)
                                        .frame(height: 22)
                                        .padding(.leading, 12)
                                    
                                    
                                    // Birden fazla track'i alt alta çiz
                                    ForEach(vm.tracks.indices, id: \.self) { idx in
                                        TrackRowView(
                                            index: idx,
                                            segment: vm.tracks[idx],
                                            isSelected: vm.selectedTrackIndex == idx,
                                            pxPerSec: pxPerSec,
                                            onChangeSelection: { index, start, end in
                                                vm.updateSelection(for: index, start: start, end: end)
                                            },
                                            onTapPlay: { index in
                                                vm.togglePlay(for: index)
                                            }
                                        )
                                        
                                    }
                                    .padding(.leading, 12)
                                    .padding(.top, 8)
                                }
                                .frame(width: timelineWidth + 40, alignment: .topLeading)
                            }
                            .frame(maxHeight: .infinity, alignment: .top)
                        }
                    }
                    
                    
                }
                .frame(maxWidth: .infinity, maxHeight: 500,alignment: .top)
                .padding(.top, 4)
                
                
                // Alt bar
                VStack(spacing: 4) {
                    HStack {
                        Button("Demo Ekle") {
                            showDemoSheet = true
                        }
                        
                        
                        
                        
                        Spacer()
                        Button(vm.isPlaying ? "Durdur" : "Çal") {
                            if vm.selectedTrackIndex == nil, !vm.tracks.isEmpty {
                                vm.selectedTrackIndex = 0
                            }
                            if let idx = vm.selectedTrackIndex {
                                vm.togglePlay(for: idx)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(width: 80)
                        
                        
                        Spacer()
                        Picker("Çalma Modu", selection: $vm.playbackMode) {
                            Text("Playlist").tag(SingleTrackViewModel.PlaybackMode.sequence)
                            Text("Mix MultiTrack").tag(SingleTrackViewModel.PlaybackMode.multiTrack)
                        }
                        .pickerStyle(.segmented)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    
                }
                
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity,alignment: .top)
            .navigationTitle("Editör")
            
        }
        .onAppear { configureAudioSession() }
        .fileImporter(isPresented: $showPicker, allowedContentTypes: [.audio]) { vm.handlePick(result: $0) }
        .sheet(isPresented: $showDemoSheet) {
            NavigationStack {
                List {
                    ForEach(demoSongs, id: \.self) { name in
                        Button {
                            vm.addBundledDemo(name)
                            showDemoSheet = false
                        } label: {
                            HStack {
                                Image(systemName: "music.note")
                                Text(name)
                            }
                        }
                    }
                }
                .navigationTitle("Müzikler")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("kapat") { showDemoSheet = false }
                    }
                }
            }
        }
    }

    // Ses oturumunu aç
    private func configureAudioSession() {
        let s = AVAudioSession.sharedInstance()
        try? s.setCategory(.playback, mode: .default, options: [.mixWithOthers, .defaultToSpeaker])
        try? s.setActive(true)
    }
}


#Preview {
    SingleEditorView()
}
