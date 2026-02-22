//
//  AdManager.swift
//  Mixly
//
//  Created by Mehdi Oturak on 20.02.2026.
//

import Combine
import GoogleMobileAds
import SwiftUI
import UIKit

@MainActor
final class AdManager: NSObject, ObservableObject {
    
    @AppStorage("mixly.exportCount") private var exportCount: Int = 0
    private let showEvery: Int = 10
    private let secondAdEvery: Int = 3
    

    // ✅ TEST Interstitial Ad Unit ID
    private let interstitialUnitID = "ca-app-pub-2214588741197172/4465605294"

    private var interstitial: InterstitialAd?

    func loadInterstitial() {
        let request = Request()

        InterstitialAd.load(with: interstitialUnitID, request: request) { [weak self] ad, error in
            if let error {
                print("❌ interstitial load error:", error.localizedDescription)
                return
            }
            guard let ad else { return }
            guard let strongSelf = self else { return }

            Task { @MainActor [strongSelf] in
                strongSelf.interstitial = ad
                strongSelf.interstitial?.fullScreenContentDelegate = strongSelf
                print("✅ interstitial loaded")
            }
        }
    }

    func showInterstitialIfReady() {
        // Export completion bazen background'tan gelebilir; garantiye alalım
        Task { @MainActor in
            guard let topVC = self.topVC() else { return }

            guard let interstitial = self.interstitial else {
                print("⚠️ interstitial not ready")
                return
            }

            interstitial.present(from: topVC)
        }
    }

    private func topVC() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
              let window = scene.windows.first(where: { $0.isKeyWindow }),
              var top = window.rootViewController else { return nil }

        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
    
    func registerExportAndMaybeShowAd() {
        exportCount += 1
        
        // ✅ 1) Ana interstitial
        if exportCount % showEvery == 0 {
            showInterstitialIfReady()
        }
    }
    
    func registerShareAndMaybeShowSecondAd() {
        // ✅ 2) İkinci reklamı daha seyrek göster
        if exportCount % secondAdEvery == 0 {
            showInterstitialIfReady()
        }
    }
    
}

// MARK: - Full screen delegate
extension AdManager: FullScreenContentDelegate {

    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.interstitial = nil
            self.loadInterstitial()
        }
    }

    nonisolated func ad(_ ad: FullScreenPresentingAd,
                       didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            print("❌ interstitial present error:", error.localizedDescription)
            self.interstitial = nil
            self.loadInterstitial()
        }
    }
}
