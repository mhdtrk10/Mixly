//
//  LaneEditorView.swift
//  Mixly
//
//  Created by Mehdi Oturak on 19.12.2025.
//

import SwiftUI
import GoogleMobileAds
import UniformTypeIdentifiers

struct LaneEditorView: View {
    @StateObject private var vm = LaneEditorViewModel()

    @State private var showSongPickerSheet = false
    @State private var showRangeSheet = false

    @State private var addMode: AddMode = .firstOrNewLane
    @State private var targetLaneID: UUID? = nil

    // pending
    @State private var pendingSourceID: UUID? = nil
    @State private var pendingAddMode: AddMode = .firstOrNewLane
    @State private var pendingLaneID: UUID? = nil

    private let demoSongs: [String] = ["attention", "katy", "streets", "katyvocal"]

    private let timelineWidth: CGFloat = 3000
    private let secondsShown: Double = 300
    private var pxPerSec: CGFloat { timelineWidth / CGFloat(secondsShown) }

    enum AddMode {
        case firstOrNewLane
        case appendRight
    }
    
    @EnvironmentObject private var themeManager: ThemeManager
    
    @EnvironmentObject var adManager: AdManager
    @State private var showSaved = false
    @State private var waitingAdToClose = false
    @State private var lastDismissCount = 0
    
    @Environment(\.managedObjectContext) private var context
    @State private var showNamePrompt = false
    @State private var mixName: String = ""
    @State private var isExporting = false
    @State private var showFilePicker = false
    
    var body: some View {
        ZStack {
           
            
            themeManager.theme.background
                .ignoresSafeArea()
            
            VStack(spacing: 12) {
                
                BannerTopBar()

                ScrollView(.horizontal, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 12) {

                        TimeRulerView(totalSec: secondsShown, pxPerSec: pxPerSec)
                            .frame(height: 22)
                            .padding(.leading, 12)

                        if vm.lanes.isEmpty {
                            Button {
                                addMode = .firstOrNewLane
                                targetLaneID = nil
                                showSongPickerSheet = true
                            } label: {
                                Text("Şarkı Ekle")
                                    .foregroundStyle(.white)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 14)
                                    .frame(maxWidth: 150, maxHeight: 50, alignment: .center)
                                    .background(Color.accentColor.opacity(0.5))
                                    .cornerRadius(14)
                                    
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 8)
                            .buttonStyle(PressableStyle())
                            .simultaneousGesture(DragGesture(minimumDistance: 0))
                            
                            
                        } else {
                            ZStack(alignment: .topLeading) {
                                VStack(alignment: .leading, spacing: 12) {
                                    
                                    ForEach(vm.lanes) { lane in
                                        LaneRowView(
                                            lane: lane,
                                            sources: vm.sources,
                                            pxPerSec: pxPerSec,
                                            isSelected: vm.selectedLaneID == lane.id,
                                            timelineWidth: timelineWidth,
                                            onMoveItem: { itemID, newStart in
                                                vm.moveItem(laneID: lane.id, itemID: itemID, newTimelineStart: newStart)
                                            },
                                            onTapItem: { item in
                                                vm.beginEdit(laneID: lane.id, item: item)
                                            },
                                            onTapLane: {
                                                vm.selectLane(lane.id)
                                            },
                                            onTapAppendRight: {
                                                vm.selectLane(lane.id)
                                                addMode = .appendRight
                                                targetLaneID = lane.id
                                                showSongPickerSheet = true
                                            },
                                            onDeleteItem: { laneID, itemID in
                                                vm.removeItem(laneID: laneID, itemID: itemID)
                                            }
                                        )
                                        .padding(.leading, 12)
                                        //.padding(.bottom, 12)
                                    }
                                    
                                    
                                    Button {
                                        addMode = .firstOrNewLane
                                        targetLaneID = nil
                                        showSongPickerSheet = true
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: "plus.circle.fill")
                                                .foregroundStyle(Color.white)
                                            Text("Yeni Satır (Lane) Ekle")
                                                .foregroundStyle(Color.white)
                                        }
                                        .font(.subheadline)
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 12)
                                        .background(Color.accentColor.opacity(0.5))
                                        .cornerRadius(12)
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 8)
                                    .simultaneousGesture(DragGesture(minimumDistance: 0))
                                    .buttonStyle(PressableStyle())

                                    
                                }
                                .frame(width: timelineWidth, alignment: .leading)
                                .background(
                                    GeometryReader { geo in
                                        Color.clear
                                            .onAppear { vm.timelineHeight = geo.size.height }
                                            .onChange(of: geo.size.height) { _, newH in
                                                vm.timelineHeight = newH
                                            }
                                    }
                                )
                                
                                
                                
                                PlayheadView(x: CGFloat(vm.playHeadSec) * pxPerSec + 12, height: vm.timelineHeight - 50)
                                
                            }
                            
                        }
                    }
                    .frame(width: timelineWidth + 40, alignment: .topLeading)
                    
                }

                Spacer(minLength: 8)

                // Bottom bar
                HStack {
                    Button{
                        addMode = .firstOrNewLane
                        targetLaneID = nil
                        //showSongPickerSheet = true
                        showFilePicker = true
                    } label: {
                        Text("Şarkı ekle")
                            .foregroundStyle(Color.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 8)
                            .frame(maxWidth: 100, maxHeight: 40, alignment: .center)
                            .background(Color.accentColor.opacity(0.5))
                            .cornerRadius(12)
                    }

                    Spacer()

                    Button(vm.isPlaying ? "Stop" : "Play") {
                        
                        if vm.isPlaying {
                            vm.stopPlayBack()
                            
                            
                        } else {
                            vm.startPlayBack()
                        }
                    }
                    
                    .buttonStyle(.borderedProminent)
                    .disabled(vm.lanes.flatMap { $0.items }.isEmpty)
                    Spacer()
                    
                    Button {
                        vm.restartPlayback()
                    } label: {
                        Image(systemName: "gobackward")
                        
                    }
                    .disabled(isExporting || vm.lanes.isEmpty)
                    Spacer()
                    
                    Button {
                        mixName = ""
                        showNamePrompt = true
                        
                    } label: {
                         Text("Kaydet")
                            .foregroundStyle(Color.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 12)
                            .frame(maxWidth: 100, maxHeight: 40, alignment: .center)
                            .background(Color.accentColor.opacity(0.5))
                            .cornerRadius(12)
                    }
                    .disabled(isExporting || vm.lanes.isEmpty)
                    .alert("Mix Adı: ", isPresented: $showNamePrompt) {
                        TextField("Örn:  BestMix", text: $mixName)
                        
                        Button("Vazgeç", role: .cancel) { }
                        
                        Button("Kaydet") {
                            showNamePrompt = false
                            Task {@MainActor in
                                
                                await exportAndSaveWithName()
                            }
                        }
                    } message: {
                        Text("Kaydederken listede bu isim gözükecek.")
                    }
                    .alert("Kaydedildi!", isPresented: $showSaved) {
                        Button("Tamam", role: .cancel) {}
                    }
                    .onChange(of: adManager.interstitialDismissCount) { oldValue, newValue in
                        // ✅ reklam kapandıysa ve biz bekliyorsak -> şimdi bildir
                        guard waitingAdToClose else { return }
                        guard newValue > lastDismissCount else { return }
                        
                        waitingAdToClose = false
                        showSaved = true
                    }
                    
                    Spacer()
                    if vm.isLoading { ProgressView() }
                }
                .padding()
            }
        }
        .navigationTitle("Mixly")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            adManager.loadInterstitial()
        }
        // MARK: - Sheets
        .sheet(isPresented: $showSongPickerSheet) {
            SongPickSheet(
                demoSongs: demoSongs,
                onPick: { name in
                    Task { @MainActor in
                        guard let sid = await vm.createBundledSource(name) else {
                            showSongPickerSheet = false
                            return
                        }
                        pendingSourceID = sid
                        pendingAddMode = addMode
                        pendingLaneID = targetLaneID

                        showRangeSheet = true
                        showSongPickerSheet = false
                    }
                },
                onClose: { showSongPickerSheet = false }
            )
        }
        .sheet(isPresented: $showRangeSheet) {
            if let sid = pendingSourceID,
               let src = vm.sources.first(where: { $0.id == sid }) {

                RangePickSheet(
                    source: src,
                    pxPerSec: pxPerSec,
                    onConfirm: { start, end in
                        Task { @MainActor in
                            let length = max(0, end - start)

                            switch pendingAddMode {
                            case .firstOrNewLane:
                                vm.addToNewLane(sourceID: sid, start: start, length: length)

                            case .appendRight:
                                if let laneID = pendingLaneID {
                                    vm.addToRight(of: laneID, sourceID: sid, start: start, length: length)
                                } else {
                                    vm.addToNewLane(sourceID: sid, start: start, length: length)
                                }
                            }

                            pendingSourceID = nil
                            pendingLaneID = nil
                            showRangeSheet = false
                        }
                    },
                    onCancel: {
                        pendingSourceID = nil
                        pendingLaneID = nil
                        showRangeSheet = false
                    }
                )
            }
        }

        // item tıkla → düzenle
        .sheet(item: $vm.editingItem) { edit in
            if let src = vm.sources.first(where: { $0.id == edit.sourceID }) {
                RangePickSheet(
                    source: src,
                    pxPerSec: pxPerSec,
                    defaultStart: edit.startSec,
                    defaultEnd: edit.endSec,
                    onConfirm: { start, end in
                        vm.updateItem(laneID: edit.laneID, itemID: edit.itemID, start: start, end: end)
                        vm.editingItem = nil
                    },
                    onCancel: {
                        vm.editingItem = nil
                    }
                )
            }
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.mp3, .mpeg4Audio, .wav]
        ) { result in
            vm.handlePickedFile(
                result: result,
                addMode: addMode,
                targetLaneID: targetLaneID,
                openRangeSheet: {
                    showRangeSheet = true
                },
                setPending: { sid, mode, laneID in
                    pendingSourceID = sid
                    pendingAddMode = mode
                    pendingLaneID = laneID
                }
            )
        }
    }
    @MainActor
    private func exportAndSaveWithName() async {
        guard !isExporting else { return }
        isExporting = true
        defer { isExporting = false }

        let trimmed = mixName.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle = trimmed.isEmpty
            ? "Mix \(Date.now.formatted(date: .numeric, time: .shortened))"
            : trimmed

        guard let url = await vm.exportMix() else { return }

        // ✅ 1) Kaydet
        let store = MixStore(context: context)
        store.saveMix(
            fromExportURL: url,
            title: finalTitle,
            durationSec: vm.mixTotalDurationSec,
            lanesCount: vm.lanes.count,
            ext: "m4a"
        )

        // ✅ 2) Reklamı göster
        waitingAdToClose = true
        lastDismissCount = adManager.interstitialDismissCount

        let shown = adManager.showInterstitialIfReady()

        // ✅ 3) Reklam yoksa direkt bildir
        if !shown {
            waitingAdToClose = false
            showSaved = true   // veya presentToast("Kaydedildi ✅")
        }
    }
}
struct BannerTopBar: View {

    // Google Test Banner ID
    private let bannerID = "ca-app-pub-3940256099942544/2435281174"

    var body: some View {

        let width = UIScreen.main.bounds.width
        let size = largePortraitAnchoredAdaptiveBanner(width: width)

        AdBannerView(adUnitID: bannerID, adSize: size)
            .frame(width: size.size.width, height: 40)
            .frame(maxWidth: .infinity)
            
    }
}


#Preview {
    LaneEditorView()
}
