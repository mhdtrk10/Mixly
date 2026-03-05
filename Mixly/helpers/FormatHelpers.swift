//
//  FormatHelpers.swift
//  Mixly
//
//  Created by Mehdi Oturak on 5.03.2026.
//

import Foundation

private let mixDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateStyle = .medium
    f.timeStyle = .none
    return f
}()

func formatTime(_ seconds: Double) -> String {
    let s = max(0, Int(seconds.rounded()))
    let m = s / 60
    let r = s % 60
    return String(format: "%02d:%02d", m, r)
}

func formatDate(_ date: Date?) -> String {
    guard let date else { return "" }
    return mixDateFormatter.string(from: date)
}
