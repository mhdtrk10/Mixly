//
//  MixLibrary.swift
//  Mixly
//
//  Created by Mehdi Oturak on 26.02.2026.
//

import Foundation

enum MixLibrary {

    static func mixesFolder() throws -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let folder = docs.appendingPathComponent("Mixes", isDirectory: true)
        if !FileManager.default.fileExists(atPath: folder.path) {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }

    static func copyExportToLibrary(from tempURL: URL, fileExt: String = "m4a") throws -> (fileName: String, finalURL: URL) {
        let folder = try mixesFolder()

        // benzersiz dosya adı
        let fileName = "mix_\(UUID().uuidString).\(fileExt)"
        let finalURL = folder.appendingPathComponent(fileName)

        // aynı isim varsa sil (olmaz ama garanti)
        if FileManager.default.fileExists(atPath: finalURL.path) {
            try FileManager.default.removeItem(at: finalURL)
        }

        try FileManager.default.copyItem(at: tempURL, to: finalURL)
        return (fileName, finalURL)
    }

    static func urlFor(fileName: String) throws -> URL {
        let folder = try mixesFolder()
        return folder.appendingPathComponent(fileName)
    }

    static func deleteFileIfExists(fileName: String) {
        do {
            let url = try urlFor(fileName: fileName)
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
        } catch {
            print("❌ delete file error:", error.localizedDescription)
        }
    }
    static func libraryFolderURL() -> URL {
        
        let fm = FileManager.default
        
        let base = fm.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        
        let folder = base.appendingPathComponent("Mixly")
        
        if !fm.fileExists(atPath: folder.path) {
            try? fm.createDirectory(
                at: folder,
                withIntermediateDirectories: true
            )
        }
        
        return folder
    }
    
    static func urlForSavedMix(fileName: String) -> URL? {
        let url = libraryFolderURL().appendingPathComponent(fileName)
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
}
