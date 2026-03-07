//
//  MainTabView.swift
//  Mixly
//
//  Created by Mehdi Oturak on 3.01.2026.
//

import SwiftUI
import GoogleMobileAds

struct MainTabView: View {
    @StateObject private var themeManager = ThemeManager()
    @State private var selectedTab: Int = 0
    
    
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tag(0)
            .tabItem { Label("Home", systemImage: "house.fill") }
            
            NavigationStack {
                LaneEditorView()
            }
            .tag(1)
            .tabItem { Label("Mix", systemImage: "waveform") }
            
            NavigationStack {
                RecentMixesView()
            }
            .tabItem { Label("Son Mixler", systemImage: "clock.arrow.circlepath") }
            .tag(2)
            
            NavigationStack {
                SettingsView()
            }
            .tag(3)
            .tabItem { Label("Ayarlar", systemImage: "gearshape.fill") }
        }
        .environmentObject(themeManager)
        //.tint(Color.white)
        
    }
    
    
}



#Preview {
    MainTabView()
}
