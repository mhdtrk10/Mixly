//
//  NavigationBarStyle.swift
//  Mixly
//
//  Created by Mehdi Oturak on 16.11.2025.
//

import Foundation
import SwiftUI


struct NavigationBarStyle {
    static func setupNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = UIColor(.cyan)
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
}
