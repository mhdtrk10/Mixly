//
//  ShareHelper.swift
//  Mixly
//
//  Created by Mehdi Oturak on 13.11.2025.
//

import UIKit

enum ShareHelper {
    static func presentShare(urls: [URL]) {
        let av = UIActivityViewController(activityItems: urls, applicationActivities: nil)
        UIApplication.shared.topMostVC()?.present(av, animated: true)
    }
}

extension UIApplication {
    func topMostVC(base: UIViewController? = UIApplication.shared.connectedScenes
        .compactMap { ($0 as? UIWindowScene)?.keyWindow }
        .first?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController { return topMostVC(base: nav.visibleViewController) }
        if let tab = base as? UITabBarController { return topMostVC(base: tab.selectedViewController) }
        if let presented = base?.presentedViewController { return topMostVC(base: presented) }
        return base
    }
}

