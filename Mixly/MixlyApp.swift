//
//  MixlyApp.swift
//  Mixly
//
//  Created by Mehdi Oturak on 12.11.2025.
//

import SwiftUI
import GoogleMobileAds
import CoreData

@main
struct MixlyApp: App {
    @StateObject private var playback = MixPlaybackManager()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var adManager = AdManager()
    let persistence = PersistenceController.shared
    init() {
        TabBarStyle.setupTabBar()
        MobileAds.shared.requestConfiguration.testDeviceIdentifiers = ["SIMULATOR"]
        MobileAds.shared.start()
        
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(themeManager)
                .environmentObject(adManager)
                .environmentObject(playback)
                .environment(\.managedObjectContext, persistence.container.viewContext)
        }
    }
}
