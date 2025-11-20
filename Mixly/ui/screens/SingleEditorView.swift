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
    
    //private let pxPerSec: CGFloat = 80 // 1sn = 80pt (zoom gibi)

    private let timelineWidth: CGFloat = 3000        // sabit genişlik (pt)
    private let secondsShown: Double = 300           // 5 dakika görünür alan
    private var pxPerSec: CGFloat { timelineWidth / CGFloat(secondsShown) }

    // liste ekranı için
    @State private var showDemoSheet = false
    // Demo butonuna ekleyeceğim şarkıların isim uzantıları
    private let demoSongs: [String] = ["attention", "katy", "streets", "katyvocal"]
    
    init() {
        NavigationBarStyle.setupNavigationBar()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.green).opacity(0.2)
                    .ignoresSafeArea(edges: .all)
                
                VStack {
                    
                    
                    // Yeni TimeLine alanı
                    VStack {
                        ScrollView(.horizontal, showsIndicators: true) {
                            ZStack(alignment: .leading) {
                                VStack(alignment: .leading, spacing: 16) {
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


                                }
                                .frame(width: timelineWidth, alignment: .topLeading)
                            }
                            .frame(height: 500, alignment: .top)
                        }

                        
                    }
                    .frame(maxWidth: .infinity, maxHeight: 500,alignment: .top)
                    .background(Color.blue.opacity(0.2))
                    
                  

                    // Alt bar
                    HStack {
                        Button("Demo Ekle") {
                                //vm.addBundledDemo("attention")
                                // veya istersen iki tane de yükleyebilirsin, ikincisini sonradan çalarız
                                //vm.addBundledDemo("katy")
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
                        Spacer()
                    }
                    .padding()
                }
                .navigationTitle("Mixly — Tek Parça")
                .frame(maxWidth: .infinity, maxHeight: .infinity,alignment: .top)
                .background(Color.gray.opacity(0.2))
            }
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
                .navigationTitle("Müzik Seç")
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
// Placeholder track bar (waveform yerine sade çubuk)
/*
private struct TrackBarView: View {
    
    @ObservedObject var vm: SingleTrackViewModel
    let pxPerSec: CGFloat
    //let duration: Double      // burada ‘görsel süre’ = secondsShown
    let height: CGFloat = 30
    @GestureState private var dragOffset: CGFloat = 0

    var body: some View {
        let totalWidth = CGFloat(vm.segment?.durationSec ?? 300) * pxPerSec
        let startX = CGFloat(vm.segment?.startSec ?? 0) * pxPerSec
        let endX = CGFloat(vm.segment?.endSec ?? 300) * pxPerSec
        
        ZStack(alignment: .leading) {
            // arka plan
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.3))
                .frame(width: totalWidth, height: height)
            
            // seçili arka plan
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.blue.opacity(0.4))
                .frame(width: max(endX - startX, 0), height: height)
                .offset(x: startX)
            
            // sol handle
            Circle()
                .fill(Color.white)
                .frame(width: 16, height: 16)
                .offset(x: startX - 8, y: height/2 - 8)
                .gesture(DragGesture()
                    .onChanged { value in
                        let seconds = max(0, Double((value.location.x) / pxPerSec))
                        vm.updateSelection(start: seconds, end: vm.segment?.endSec ?? seconds)
                    }
                )
            
            // sağ handle
            Circle()
                .fill(Color.white)
                .frame(width: 16, height: 16)
                .offset(x: endX - 8, y: height/2 - 8)
                .gesture(DragGesture()
                    .onChanged { value in
                        let seconds = max(0, Double((value.location.x) / pxPerSec))
                        vm.updateSelection(start: vm.segment?.startSec ?? 0, end: seconds)
                    }
                )

        }
        .frame(width: totalWidth, height: height)
        //let width = CGFloat(duration) * pxPerSec   // = timelineWidth
        /*
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.35))
                .frame(width: width, height: 40)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.12)))
            Text("Tıkla: Çal/Durdur")
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(.leading, 8)
        }
         */
    }
}
*/


#Preview {
    SingleEditorView()
}
