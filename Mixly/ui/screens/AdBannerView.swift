//
//  AdBannerView.swift
//  Mixly
//
//  Created by Mehdi Oturak on 22.02.2026.
//

import SwiftUI
import GoogleMobileAds

struct AdBannerView: UIViewRepresentable {

    let adUnitID: String
    let adSize: AdSize

    init(adUnitID: String, adSize: AdSize) {
        self.adUnitID = adUnitID
        self.adSize = adSize
    }

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: adSize)
        banner.adUnitID = adUnitID
        banner.rootViewController = context.coordinator.rootVC
        banner.delegate = context.coordinator
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, BannerViewDelegate {
        // SwiftUI’da root VC yakalamak için ufak bir host
        let rootVC = UIViewController()

        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            // print("✅ banner loaded")
        }

        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            print("❌ banner error:", error.localizedDescription)
        }
    }
}


