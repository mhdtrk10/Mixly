//
//  LaneRowView.swift
//  Mixly
//
//  Created by Mehdi Oturak on 19.12.2025.
//

import SwiftUI

import SwiftUI

struct LaneRowView: View {
    let lane: Lane
    let sources: [AudioSource]
    let pxPerSec: CGFloat
    let isSelected: Bool
    let timelineWidth: CGFloat

    let onMoveItem: (UUID, Double) -> Void        // (itemID, newTimelineStart)
    let onTapItem: (LaneItem) -> Void             // edit açmak için
    let onTapLane: () -> Void
    let onTapAppendRight: () -> Void

    private let laneHeight: CGFloat = 64

    private var maxLaneEndSec: Double {
        lane.items.map { $0.timelineEndSec }.max() ?? 0
    }
    
    let onDeleteItem: (UUID, UUID) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            ZStack(alignment: .leading) {

                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.blue.opacity(0.4) : Color.white.opacity(0.4))
                    .frame(width: timelineWidth, height: laneHeight)

                // Klipler timeline'a göre konumlanır
                ForEach(lane.items) { item in
                    if let src = sources.first(where: { $0.id == item.sourceID }) {
                        LaneItemBlockView(
                            item: item,
                            source: src,
                            pxPerSec: pxPerSec,
                            height: laneHeight,
                            onMove: { newStart in
                                onMoveItem(item.id, newStart)
                            },
                            onDelete: {
                                onDeleteItem(lane.id, item.id)
                            }
                        )
                        .onTapGesture {
                            onTapItem(item) // ✅ edit
                        }
                    } else {
                        // fallback
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black.opacity(0.25))
                            .frame(width: CGFloat(item.lengthSec) * pxPerSec, height: laneHeight)
                            .offset(x: CGFloat(item.timelineStartSec) * pxPerSec)
                    }
                }

                // Lane'in en sağına + butonu
                Button {
                    onTapAppendRight()
                } label: {
                    
                    ZStack {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 44, height: 44)
                            .overlay {
                                Circle()
                                    .stroke(Color.blue, lineWidth: 1)
                            }
                            .shadow(color: Color.black.opacity(0.4), radius: 5, x: 0, y: 3)
                        Image(systemName: "plus")
                            .foregroundStyle(Color.white)
                            .font(Font.system(size: 24))
                    }
                    
                }
                .offset(x: CGFloat(maxLaneEndSec) * pxPerSec + 12)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                onTapLane()
            }
        }
    }
}

import SwiftUI

struct LaneItemBlockView: View {
    let item: LaneItem
    let source: AudioSource
    let pxPerSec: CGFloat
    let height: CGFloat
    let onMove: (Double) -> Void
    let onDelete: () -> Void
    @State private var baseTimelineStart: Double = 0

    var body: some View {
        let width = max(CGFloat(item.lengthSec) * pxPerSec, 40)
        let x = CGFloat(item.timelineStartSec) * pxPerSec

        ZStack(alignment: .topTrailing) {
            
            ZStack(alignment: .center) {
                

                if !source.waveform.isEmpty {
                    WaveformView(samples: source.waveform, style: .lane)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 8)
                        .clipped()
                }


                // küçük isim etiketi
                Text(source.url.lastPathComponent)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.black.opacity(0.9))
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.top, 6)
            }
                        
            Button {
                onDelete()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.95))
                    .padding(6)
                    .background(Color.black.opacity(0.55))
                    .clipShape(Circle())
            }
            
        }
        .frame(width: width, height: height)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.black, lineWidth: 1)
        )
        .background(Color.accentColor)
        .cornerRadius(10)
        .offset(x: x)
        .onAppear { baseTimelineStart = item.timelineStartSec }
        .gesture(
            DragGesture()
                .onChanged { value in
                    let deltaSec = Double(value.translation.width / pxPerSec)
                    let proposed = baseTimelineStart + deltaSec
                    onMove(max(0, proposed))
                }
                .onEnded { _ in
                    baseTimelineStart = item.timelineStartSec
                }
        )

    }
}

/*
private struct LaneItemFallbackView: View {
    let item: LaneItem
    let pxPerSec: CGFloat
    let height: CGFloat
    
    var body: some View {
        let x = CGFloat(item.timelineStartSec) * pxPerSec
        let w = max(CGFloat(item.lengthSec) * pxPerSec, 20)
        
        return RoundedRectangle(cornerRadius: 10)
            .fill(Color.white.opacity(0.12))
            .overlay(
                Text("Item")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            )
            .frame(width: w, height: height)
            .offset(x: x)
    }
}
*/

