//
//  TabBarStyle.swift
//  Mixly
//
//  Created by Mehdi Oturak on 23.01.2026.
//

import UIKit
import SwiftUI

struct TabBarStyle {
    static func setupTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .cyan

        // NORMAL (seçili olmayan)
        let normalIcon = UIColor.yellow
        let normalText = UIColor.gray

        // SELECTED (seçili)
        let selectedIcon = UIColor.systemBlue
        let selectedText = UIColor.systemBlue

        // ✅ 1) stacked (iPhone portrait çoğu zaman)
        appearance.stackedLayoutAppearance.normal.iconColor = normalIcon
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normalText]
        appearance.stackedLayoutAppearance.selected.iconColor = selectedIcon
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedText]

        // ✅ 2) inline (bazı iPad / bazı boyutlar)
        appearance.inlineLayoutAppearance.normal.iconColor = normalIcon
        appearance.inlineLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normalText]
        appearance.inlineLayoutAppearance.selected.iconColor = selectedIcon
        appearance.inlineLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedText]

        // ✅ 3) compactInline (bazı landscape durumları)
        appearance.compactInlineLayoutAppearance.normal.iconColor = normalIcon
        appearance.compactInlineLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: normalText]
        appearance.compactInlineLayoutAppearance.selected.iconColor = selectedIcon
        appearance.compactInlineLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: selectedText]

        let tabBar = UITabBar.appearance()
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance


        // ✅ SwiftUI bazen normal renkleri buradan bekler
        tabBar.unselectedItemTintColor = normalIcon
        tabBar.tintColor = selectedIcon
    }
}
