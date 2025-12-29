//
//  LaneEditorView.swift
//  Mixly
//
//  Created by Mehdi Oturak on 19.12.2025.
//

import SwiftUI

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

    var body: some View {
        ZStack {
            AppColors.Background.ignoresSafeArea()

            VStack(spacing: 12) {

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
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Şarkı Ekle")
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 14)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(14)
                            }
                            .padding(.leading, 12)
                            .frame(width: timelineWidth, alignment: .leading)

                        } else {
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
                                        }
                                    )
                                    .padding(.leading, 12)
                                }

                                Button {
                                    addMode = .firstOrNewLane
                                    targetLaneID = nil
                                    showSongPickerSheet = true
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "plus.circle.fill")
                                        Text("Yeni Satır (Lane) Ekle")
                                    }
                                    .font(.subheadline)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 12)
                                    .background(Color.white.opacity(0.07))
                                    .cornerRadius(12)
                                }
                                .padding(.leading, 12)
                                .padding(.top, 6)
                            }
                            .frame(width: timelineWidth, alignment: .leading)
                        }
                    }
                    .frame(width: timelineWidth + 40, alignment: .topLeading)
                }

                Spacer(minLength: 8)

                // Bottom bar
                HStack {
                    Button("Şarkı Ekle") {
                        addMode = .firstOrNewLane
                        targetLaneID = nil
                        showSongPickerSheet = true
                    }

                    Spacer()

                    Button(vm.isPlaying ? "Stop" : "Play") {
                        vm.togglePlay()
                    }
                    .buttonStyle(.borderedProminent)

                    Spacer()
                    
                    Button("Kaydet") {
                        Task {
                            if let url = await vm.exportMix() {
                                print("kaydedildi.", url)
                            }
                        }
                    }
                    Spacer()
                    if vm.isLoading { ProgressView() }
                }
                .padding()
            }
        }
        .navigationTitle("Mixly")
        .navigationBarTitleDisplayMode(.inline)

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
    }
}



#Preview {
    LaneEditorView()
}
