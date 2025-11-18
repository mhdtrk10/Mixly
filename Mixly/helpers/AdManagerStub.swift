//
//  AdManagerStub.swift
//  Mixly
//
//  Created by Mehdi Oturak on 13.11.2025.
//

import Foundation

final class AdManager {
    static let shared = AdManager()
    
    private init() {}
    
    /// Uygulama açıldığında çağrılır (örnek: AdMob başlatma)
    func start() {
        print("📢 AdManager started (stub)")
    }
    
    /// Gerçekte burada 2 interstitial reklam gösterilecekti.
    /// Şimdilik sadece log basıp işlemi tamamlıyor.
    func showTwoInterstitials(_ completion: @escaping () -> Void) {
        print("🎬 (Stub) 2 adet reklam gösteriliyor...")
        
        // simüle edilmiş gecikme — reklam süresi gibi
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            print("✅ Reklamlar bitti (stub)")
            completion()
        }
    }
}

    

