//
//  EditorView.swift
//  Mixly
//
//  Created by Mehdi Oturak on 13.11.2025.
//

import SwiftUI
import UniformTypeIdentifiers
import AVFoundation

struct EditorView: View {
    @StateObject var vm = MixViewModel()
    @State private var showPicker = false
    private let pxPerSec: CGFloat = 80
    

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // ÜST BAR
                HStack {
                    Button {
                        // en fazla 3 parça (şimdilik)
                        guard vm.tracks.count < 3 else { return }
                        showPicker = true
                    } label: {
                        Label("Şarkı Ekle", systemImage: "plus")
                    }
                    Spacer()
                    Text("\(vm.tracks.count) parça")
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal).padding(.vertical, 8)
                Divider()
                
                // ZAMAN ÇİZGİSİ + TRACK LİSTESİ
                TimelineScrollContainer(pxPerSec: pxPerSec, totalDuration: maxDuration()) {
                    VStack(spacing: 16) {
                        ForEach(Array(vm.tracks.enumerated()), id: \.offset) { idx, seg in
                            TrackRowView(
                                title: seg.url.lastPathComponent,
                                duration: seg.durationSec,
                                startSec: seg.startSec,
                                endSec: seg.endSec,
                                color: rowColor(idx),
                                pxPerSec: pxPerSec
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                // ileride: bu satıra özel detay sheet'i
                            }
                        }
                    }
                    .padding(.vertical, 16)
                }
                
                Divider()
                
                // ALT BAR
                // EditorView alt bar
                HStack {
                    Button(vm.isPlaying ? "Duraklat" : "Önizleme") {
                        vm.isPlaying ? vm.stopPreview() : vm.playPreview()
                    }
                    .buttonStyle(.borderedProminent)

                    if vm.isPlaying {
                        Circle().frame(width: 10, height: 10).foregroundStyle(.green)
                        Text("Çalıyor…").foregroundStyle(.secondary)
                    }
                    Spacer()
                    // Miksle & Kaydet...
                }
                .padding()
                Button("Demo Ekle") {
                    vm.addBundledDemo("dojacat")
                    vm.addBundledDemo("havhav")
                }

            }
            .onAppear { configureAudioSession() }
            .navigationTitle("Mixly — Editor")
        }
        .fileImporter(isPresented: $showPicker, allowedContentTypes: [.audio]) { vm.handlePick(result: $0) }
    }
    
    private func configureAudioSession() {
        let s = AVAudioSession.sharedInstance()
        try? s.setCategory(.playback, mode: .default, options: [.mixWithOthers, .defaultToSpeaker])
        try? s.setActive(true)
    }
    
    private func maxDuration() -> Double {
        vm.tracks.map { $0.durationSec }.max() ?? 30
    }
    private func rowColor(_ i: Int) -> Color { [Color.purple, .blue, .mint][i % 3] }
}


#Preview {
    EditorView()
}
