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
    
    @EnvironmentObject private var themeManager: ThemeManager
    
    @StateObject private var preview = RangePreviewPlayer()
    
    init(
        source: AudioSource,
        pxPerSec: CGFloat,
        defaultStart: Double = 0,
        defaultEnd: Double = 10,
        onConfirm: @escaping (_ start: Double, _ end: Double) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.source = source
        self.pxPerSec = pxPerSec
        
        
        let safeDuration = max(0, source.durationSec)
        
        
        // şarkı kısa ise clamp
        let s = min(max(0, defaultStart), max(0, safeDuration))
        let proposedEnd = min(defaultEnd, safeDuration)
        
        let e: Double
        if proposedEnd - s >= 0.1 {
            e = proposedEnd
        } else {
            e = min(s + min(5, safeDuration), safeDuration)
        }

        _startSec = State(initialValue: s)
        _endSec = State(initialValue: e)

        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }

    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.theme.background
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    
                    
                    ZStack {
                        Rectangle()
                            .fill(Color.accentColor)
                            .frame(width: 175, height: 50)
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.4), radius: 17, x: -30, y: 0)
                            .shadow(color: Color.black.opacity(0.4), radius: 17, x: 30, y: 0)
                        
                        Text(source.displayName)
                            .font(.title)
                            .foregroundStyle(Color.white)
                    }

                    
                    VStack(spacing: 8) {
                        
                        VStack {
                            ScrollViewReader { proxy in
                                ScrollView(.horizontal, showsIndicators: false) {
                                    RangePickRow(
                                        durationSec: preview.durationSec,
                                        waveform: source.waveform,
                                        pxPerSec: pxPerSec,
                                        startSec: $startSec,
                                        endSec: $endSec
                                    )
                                    .frame(height: 64)
                                    .padding(.horizontal, 12)
                                }
                                .onAppear {
                                    DispatchQueue.main.async {
                                        proxy.scrollTo("selectionMid", anchor: .center)
                                    }
                                }
                            }
                        }
                        .frame(height: 64)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                        .padding(.bottom, 8)
                        .background(Color.blue.opacity(0.65))

                        

                        HStack {
                            Text("Start: \(Int(startSec))s")
                                .foregroundStyle(Color.white)
                            Spacer()
                            Text("End: \(Int(endSec))s")
                                .foregroundStyle(Color.white)
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                    }
                    .frame(maxWidth: .infinity, maxHeight: 120)
                    .background(Color.accentColor)
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.4), radius: 5, x: 0, y: 5)
                    .shadow(color: Color.black.opacity(0.4), radius: 5, x: 0, y: -5)
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray, lineWidth: 1)
                    }
                    .padding(.bottom, 8)
                    
                    
                    HStack(spacing: 12) {
                        
                        Button {
                            let s = min(max(0, startSec), source.durationSec)
                            let e = min(max(s, endSec), source.durationSec)
                            onConfirm(s, e)
                        } label: {
                            Text("Ekle")
                                .foregroundStyle(Color.white)
                                .font(Font.body.bold())
                                .frame(width: 140, height: 50)
                                .background(Color.accentColor.opacity(0.5))
                                .cornerRadius(12)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 8)
                        .buttonStyle(PressableStyle())
                        
                        Spacer()
                        
                        Button {
                            if preview.isPlaying {
                                preview.stop()
                            } else {
                                
                                preview.playRange(startSec: startSec, endSec: endSec)
                            }
                            
                        } label: {
                            HStack(spacing: 8) {
                                Text(preview.isPlaying ? "Durdur" : "Dinle")
                            }
                            .foregroundStyle(Color.white)
                            .font(Font.body.bold())
                            .frame(width: 140, height: 50)
                            .background(Color.accentColor.opacity(0.5))
                            .cornerRadius(12)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 8)
                        .buttonStyle(PressableStyle())
                        
                        
                    }
                    .padding(.horizontal, 16)
                    
                    
                    
                }
                .navigationTitle("Aralık Seç")
                //.navigationBarTitleDisplayMode(.inline)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .padding(.top, 12)
                .padding(.horizontal, 12)
                .onAppear {
                    preview.prepare(url: source.url)
                    preview.stop()
                }
                .onDisappear {
                    preview.stop()
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            onCancel()
                        } label: {
                            Text("Vazgeç")
                                .foregroundStyle(Color.white)
                                .font(Font.body.bold())
                                .frame(width: 100, height: 40)
                                .background(Color.accentColor.opacity(0.5))
                                .cornerRadius(12)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 8)
                        .buttonStyle(PressableStyle())
                    }
                    .sharedBackgroundVisibility(.hidden)
                    
                }
            }
        }
    }
}


