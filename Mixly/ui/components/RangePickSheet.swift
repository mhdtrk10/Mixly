//
//  RangePickSheet.swift
//  Mixly
//
//  Created by Mehdi Oturak on 25.12.2025.
//

import SwiftUI

struct RangePickSheet: View {
    
    let source: AudioSource
    let pxPerSec: CGFloat
    
    private let editorPxPerSec: CGFloat = 40
    @State private var startSec: Double
    @State private var endSec: Double

    let onConfirm: (_ start: Double, _ end: Double) -> Void
    let onCancel: () -> Void

    init(
        source: AudioSource,
        pxPerSec: CGFloat,
        defaultStart: Double = 20,
        defaultEnd: Double = 30,
        onConfirm: @escaping (_ start: Double, _ end: Double) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.source = source
        self.pxPerSec = pxPerSec
        
        let editorPxPerSec: CGFloat = 40 // 1 saniye 40pt (çok daha rahat)
        
        // şarkı kısa ise clamp
        let s = min(max(0, defaultStart), source.durationSec)
        let e = min(max(s, defaultEnd), source.durationSec)

        _startSec = State(initialValue: s)
        _endSec = State(initialValue: e)

        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                Text(source.displayName)
                    .font(.headline)

                
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: true) {
                        RangePickRow(
                            durationSec: source.durationSec,
                            waveform: source.waveform,
                            pxPerSec: pxPerSec,
                            startSec: $startSec,
                            endSec: $endSec
                        )
                        .frame(height: 64)
                        .padding(.horizontal, 16)
                    }
                    .onAppear {
                        DispatchQueue.main.async {
                            proxy.scrollTo("selectionMid", anchor: .center)
                        }
                    }
                }



                HStack {
                    Text("Start: \(Int(startSec))s")
                    Spacer()
                    Text("End: \(Int(endSec))s")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)

                Spacer()
            }
            .padding(.top, 12)
            .navigationTitle("Aralık Seç")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Vazgeç") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ekle") {
                        let s = min(max(0, startSec), source.durationSec)
                        let e = min(max(s, endSec), source.durationSec)
                        onConfirm(s, e)
                    }
                }
            }
        }
    }
}


