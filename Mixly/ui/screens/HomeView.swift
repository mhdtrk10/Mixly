//
//  HomeView.swift
//  Mixly
//
//  Created by Mehdi Oturak on 2.12.2025.
//

import SwiftUI

struct HomeView: View {
    
    @EnvironmentObject private var themeManager: ThemeManager
    
    init () {
        NavigationBarStyle.setupNavigationBar()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                /*
                LinearGradient(
                    colors: [.purple.opacity(0.8),.blue.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .ignoresSafeArea()
                */
                
                themeManager.theme.background
                    .ignoresSafeArea()
                
                VStack(alignment: .center, spacing: 8) {
                    VStack(spacing: 4) {
                        // üst başlık
                        Text("Mixly")
                            .font(.system(size: 36,weight: .bold))
                            .foregroundStyle(Color.white)
                        Text("Şarkılarını kolayca mixle! \n özgün şarkılar oluştur!")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                        
                    }
                    .padding(.top, 64)
                    
                    /*
                    // ortada waveform kartı görsel olarak
                    RoundedRectangle(cornerRadius: 20)
                        .fill (
                            LinearGradient(
                                colors: [.purple.opacity(0.8),.blue.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 180)
                        .overlay (
                            VStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .frame(width: 50, height: 50)
                                        .foregroundStyle(Color.white)
                                    Image(systemName: "waveform.circle.fill")
                                        .font(.system(size: 50))
                                        .foregroundStyle(themeManager.theme.background)
                                }
                                
                                Text("MultiTrack & Playlist Modu")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                Text("İster sırayla çal, ister aynı anda miksle!")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                        )
                        .padding(.horizontal, 22)
                    */
                    Spacer()
                    
                    // alt butonlar
                    VStack(spacing: 12) {
                        NavigationLink {
                            LaneEditorView()
                        } label: {
                            Text("Yeni Mix Oluştur")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundStyle(.white)
                                .cornerRadius(12)
                        }
                        .buttonStyle(PressableStyle())
                        
                        NavigationLink {
                            // TODO: son mixler ekranı
                            RecentMixesView()
                            
                        } label: {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                Text("Son Mixler")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor.opacity(0.4))
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                        }
                        .buttonStyle(PressableStyle())
                        //.disabled(true) // şimdilik pasif
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(themeManager.theme.background)
                        .frame(height: 180)
                        .overlay (
                            VStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .frame(width: 50, height: 50)
                                        .foregroundStyle(Color.white)
                                    Image(systemName: "waveform.circle.fill")
                                        .font(.system(size: 50))
                                        .foregroundStyle(themeManager.theme.background)
                                }
                                
                                Text("MultiTrack & Playlist")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                Text("İster sırayla çal, ister aynı anda miksle!")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.9))
                            }
                        )
                        .padding(.horizontal, 22)
                        
                )
            }
            .navigationTitle("Mixly")
        }
    }
}

#Preview {
    HomeView()
}
