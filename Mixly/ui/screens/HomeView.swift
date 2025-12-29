//
//  HomeView.swift
//  Mixly
//
//  Created by Mehdi Oturak on 2.12.2025.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.Background.edgesIgnoringSafeArea(.all)
                
                VStack {
                    VStack(spacing: 4) {
                        // üst başlık
                        Text("Mixly")
                            .font(.system(size: 36,weight: .bold))
                        Text("Şarkılarını kolayca mixle! \n özgün şarkılar oluştur!")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.black)
                        
                    }
                    .padding(.top, 40)
                    
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
                                Image(systemName: "waveform.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundStyle(.black)
                                
                                Text("MultiTrack & Playlist Modu")
                                    .font(.headline)
                                    .foregroundStyle(.black)
                                Text("İster sırayla çal, ister aynı anda miksle!")
                                    .font(.caption)
                                    .foregroundStyle(.black.opacity(0.9))
                            }
                        )
                        .padding(.horizontal, 22)
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
                                .foregroundStyle(.black)
                                .cornerRadius(12)
                        }
                        
                        Button {
                            // TODO: son mixler ekranı
                        } label: {
                            HStack {
                                Image(systemName: "clock.arrow.circlepath")
                                Text("Yakında: Son Mixler")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .foregroundStyle(.black)
                            .cornerRadius(12)
                        }
                        .disabled(true) // şimdilik pasif
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
            .navigationTitle("Mixly")
        }
    }
}

#Preview {
    HomeView()
}
