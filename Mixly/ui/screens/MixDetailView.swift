//
//  MixDetailView.swift
//  Mixly
//
//  Created by Mehdi Oturak on 5.03.2026.
//

import SwiftUI
import CoreData

struct MixDetailView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var showRename = false
    @State private var newName = ""

    let mix: MixExport
    @EnvironmentObject private var themeManager: ThemeManager
    
    @State private var showShareSheet = false
    
    
    var body: some View {
        ZStack {
            themeManager.theme.background
                .ignoresSafeArea()
            
            VStack(spacing: 16) {

                VStack(alignment: .leading, spacing: 8) {
                    Text(mix.title ?? "İsimsiz")
                        .font(.title2).bold()
                        .foregroundStyle(Color.white)
                    
                    Text("\(formatTime(mix.durationSec)) • \(formatDate(mix.createdAt))")
                        .foregroundStyle(.white)
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // ✅ Meta kartı
                HStack(spacing: 12) {
                    InfoPill(title: "Tracks", value: "\(mix.lanesCount)")
                        
                    
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                // ✅ Aksiyonlar
                VStack(spacing: 10) {
                    
                    if mixFileURL() != nil {
                        Button {
                            showShareSheet = true
                        } label: {
                            Label("Paylaş", systemImage: "squarre.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    Button {
                        showRename = true
                        newName = mix.title ?? ""
                    } label: {
                        Label("Adını değiştir", systemImage: "pencil")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button(role: .destructive) {
                        deleteMix()
                    } label: {
                        Label("Sil", systemImage: "trash")
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    
                }
            }
            .padding()
            .navigationTitle("Mix Detay Sayfası")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Mix Name", isPresented: $showRename) {
                TextField("Name", text: $newName)
                Button("Cancel", role: .cancel) {}
                Button("Save") { renameMix() }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = shareableTempURL() {
                    ShareSheet(items: [url])
                }
            }
        }
    }
    private func mixFileURL() -> URL? {
        guard let fileName = mix.fileName else { return nil }
        return try? MixLibrary.urlFor(fileName: fileName)
    }
    
    private func renameMix() {
        mix.title = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        try? context.save()
    }

    private func deleteMix() {
        context.delete(mix)
        try? context.save()
        dismiss()
    }
    private func shareableTempURL() -> URL? {
        guard let originalURL = mixFileURL() else { return nil }

        let tempDir = FileManager.default.temporaryDirectory
        let fileName = originalURL.lastPathComponent
        let tempURL = tempDir.appendingPathComponent(fileName)

        do {
            // Eski temp dosya varsa sil
            if FileManager.default.fileExists(atPath: tempURL.path) {
                try FileManager.default.removeItem(at: tempURL)
            }

            // Temp'e kopyala
            try FileManager.default.copyItem(at: originalURL, to: tempURL)
            print("✅ temp share file:", tempURL.path)
            return tempURL
        } catch {
            print("❌ temp copy error:", error.localizedDescription)
            return nil
        }
    }
}
