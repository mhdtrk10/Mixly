//
//  SettingsView.swift
//  Mixly
//
//  Created by Mehdi Oturak on 3.01.2026.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.theme.background
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    // Tema kartı
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Tema")
                            .font(.headline)

                        Picker("Tema", selection: Binding(
                            get: { themeManager.theme },
                            set: { themeManager.setTheme($0) }
                        )) {
                            ForEach(AppTheme.allCases) { t in
                                Text(t.title).tag(t)
                            }
                        }
                        .pickerStyle(.segmented)

                        // küçük preview kartı
                        RoundedRectangle(cornerRadius: 16)
                            .fill(themeManager.theme.background)
                            .frame(height: 90)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(themeManager.theme.cardStroke, lineWidth: 1)
                            )
                            .overlay(
                                HStack {
                                    Image(systemName: "waveform")
                                    Text("Mixly Preview")
                                        .font(.headline)
                                }
                                .foregroundColor(.white.opacity(0.9))
                            )
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(themeManager.theme.cardFill)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(themeManager.theme.cardStroke, lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 16)

                    Spacer()
                }
                .padding(.top, 16)
            }
            .navigationTitle("Ayarlar")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}



