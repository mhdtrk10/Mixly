//
//  Theme.swift
//  Mixly
//
//  Created by Mehdi Oturak on 3.01.2026.
//

import SwiftUI
import Combine

enum AppTheme: String, CaseIterable, Identifiable {
    case deepIndigo
    case purpleBlue

    var id: String { rawValue }

    var title: String {
        switch self {
        case .deepIndigo: return "Deep Indigo"
        case .purpleBlue: return "Purple • Blue"
        }
    }

    /// Uygulama arka planı (LinearGradient)
    var background: LinearGradient {
        switch self {
        case .deepIndigo:
            return LinearGradient(
                colors: [Color(hex: "0B0E14"), Color(hex: "1B1F3B")],
                startPoint: .top,
                endPoint: .bottom
            )
        case .purpleBlue:
            return LinearGradient(
                colors: [.purple.opacity(0.8), .blue.opacity(0.8)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }

    /// Kart / panel arka planı (overlay’ler iyi dursun diye)
    var cardFill: Color {
        switch self {
        case .deepIndigo: return Color.white.opacity(0.06)
        case .purpleBlue: return Color.white.opacity(0.08)
        }
    }

    /// Kart border rengi
    var cardStroke: Color {
        switch self {
        case .deepIndigo: return Color.white.opacity(0.10)
        case .purpleBlue: return Color.white.opacity(0.14)
        }
    }
}

@MainActor
final class ThemeManager: ObservableObject {
    @AppStorage("mixly.theme") private var storedTheme: String = AppTheme.deepIndigo.rawValue

    var theme: AppTheme {
        get { AppTheme(rawValue: storedTheme) ?? .purpleBlue }
        set { storedTheme = newValue.rawValue }
    }

    func setTheme(_ t: AppTheme) {
        theme = t
        objectWillChange.send()
    }
}



