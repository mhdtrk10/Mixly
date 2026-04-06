//
//  SongPickSheet.swift
//  Mixly
//
//  Created by Mehdi Oturak on 19.12.2025.
//

import SwiftUI

struct SongPickSheet: View {
    let demoSongs: [String]
    let onPick: (String) -> Void
    let onClose: () -> Void
    @EnvironmentObject private var themeManager: ThemeManager
    var body: some View {
        NavigationStack {
            
            ZStack {
                
                themeManager.theme.background.edgesIgnoringSafeArea(.all)
                
                VStack {
                    ForEach(demoSongs, id: \.self) { name in
                        Button {
                            onPick(name)
                        } label: {
                            HStack(spacing: 16) {
                                Image(systemName: "music.note")
                                    .foregroundStyle(Color.white)
                                Text(name)
                                    .foregroundStyle(Color.white)
                            }
                            .frame(width: 200, height: 40, alignment: .leading)
                            .padding(.leading, 16)
                            .background(AppColors.Navbar.opacity(0.8))
                            .cornerRadius(8)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, 8)
            }
            .navigationTitle("Müzik Seç")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        onClose()
                    } label: {
                        Text("Kapat")
                            .foregroundStyle(Color.white)
                            .font(Font.body.bold())
                            .frame(width: 100, height: 40)
                            .background(Color.accentColor.opacity(0.5))
                            .cornerRadius(12)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 8)
                    .buttonStyle(PressableStyle())
                    .shadow(color: Color.black.opacity(0.4), radius: 5,x: 5, y: -5)
                    .shadow(color: Color.black.opacity(0.4), radius: 5,x: -5, y: 5)
                }
                .sharedBackgroundVisibility(.hidden)
            }
        }
    }
}

