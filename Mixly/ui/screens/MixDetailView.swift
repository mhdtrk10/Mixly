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

    var body: some View {
        VStack(spacing: 16) {

            VStack(alignment: .leading, spacing: 8) {
                Text(mix.title ?? "Untitled")
                    .font(.title2).bold()

                Text("\(formatTime(mix.durationSec)) • \(formatDate(mix.createdAt))")
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // ✅ Meta kartı
            HStack(spacing: 12) {
                InfoPill(title: "Tracks", value: "\(mix.lanesCount)")
                //InfoPill(title: "Format", value: (mix.ext ?? "m4a").uppercased())
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            // ✅ Aksiyonlar
            VStack(spacing: 10) {
                Button {
                    showRename = true
                    newName = mix.title ?? ""
                } label: {
                    Label("Rename", systemImage: "pencil")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button(role: .destructive) {
                    deleteMix()
                } label: {
                    Label("Delete", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .navigationTitle("Mix Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Mix Name", isPresented: $showRename) {
            TextField("Name", text: $newName)
            Button("Cancel", role: .cancel) {}
            Button("Save") { renameMix() }
        }
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
}
