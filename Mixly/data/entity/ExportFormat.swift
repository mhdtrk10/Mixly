//
//  ExportFormat.swift
//  Mixly
//
//  Created by Mehdi Oturak on 12.11.2025.
//

import Foundation

enum ExportFormat : String, CaseIterable, Identifiable {
    case m4a
    case wav
    var id: String { self.rawValue }
}
