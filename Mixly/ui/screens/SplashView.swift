//
//  SplashView.swift
//  Mixly
//
//  Created by Mehdi Oturak on 10.03.2026.
//

import SwiftUI

struct SplashView: View {
    @State private var animate = false
    @State private var showMain = false
    var body: some View {
        ZStack {
            
            Image("mixlySplash") // Assets'e ekleyeceğin görsel
                .resizable()
                //.scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                //.scaleEffect(animate ? 1.0 : 0.92)
                //.opacity(animate ? 1 : 0.7)
                .ignoresSafeArea()
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        showMain = true
                    }
                }
            /*
            VStack(spacing: 12) {
                
                Text("Mixly")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.white)

                Text("Create your mix")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            */
        }
        
    }
}
