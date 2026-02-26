//
//  MixStore.swift
//  Mixly
//
//  Created by Mehdi Oturak on 26.02.2026.
//

import CoreData
import Foundation
import Combine

@MainActor
final class MixStore: ObservableObject {

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func saveMix(fromExportURL exportURL: URL,
                 title: String? = nil,
                 durationSec: Double = 0,
                 lanesCount: Int = 0,
                 ext: String = "m4a") {

        do {
            let (fileName, _) = try MixLibrary.copyExportToLibrary(from: exportURL, fileExt: ext)

            let item = MixExport(context: context)
            item.id = UUID()
            item.title = title ?? "Mix \(DateFormatter.short.string(from: Date()))"
            item.fileName = fileName
            item.createdAt = Date()
            item.durationSec = durationSec
            item.lanesCount = Int16(lanesCount)

            try context.save()
            print("✅ CoreData saved:", fileName)

        } catch {
            print("❌ saveMix error:", error.localizedDescription)
        }
    }

    func deleteMix(_ mix: MixExport) {
        if let fileName = mix.fileName {
            MixLibrary.deleteFileIfExists(fileName: fileName)
        }
        context.delete(mix)

        do {
            try context.save()
        } catch {
            print("❌ deleteMix coredata error:", error.localizedDescription)
        }
    }
}

private extension DateFormatter {
    static let short: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd.MM HH:mm"
        return f
    }()
}
