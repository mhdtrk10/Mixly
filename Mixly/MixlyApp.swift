//
//  MixlyApp.swift
//  Mixly
//
//  Created by Mehdi Oturak on 12.11.2025.
//

import SwiftUI

@main
struct MixlyApp: App {
    
    init() {
        TabBarStyle.setupTabBar()
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                //.environmentObject(ThemeManager())
        }
    }
}
