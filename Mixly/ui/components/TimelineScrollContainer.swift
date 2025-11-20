//
//  TimelineScrollContainer.swift
//  Mixly
//
//  Created by Mehdi Oturak on 14.11.2025.
//

import SwiftUI

struct TimelineScrollContainer<Content: View>: View {
    
    let pxPerSec: CGFloat
    let totalDuration: Double
    @ViewBuilder let content: Content
    
    
    var body: some View {
        // içeriğin genişliği
        let width = max(CGFloat(totalDuration) * pxPerSec, 800)
        
        ScrollView(.horizontal, showsIndicators: true) {
            VStack(alignment: .leading,spacing: 0) {
                TimeRulerView(totalSec: totalDuration, pxPerSec: pxPerSec)
                    .frame(height: 28)
                    .padding(.horizontal, 12)
                
                content
                    .frame(minWidth: width, alignment: .leading)
                    .padding(.horizontal, 12)
            }
            .frame(minWidth: width, alignment: .leading)
        }
    }
}

struct TimeRulerView: View {
    let totalSec: Double
    let pxPerSec: CGFloat
    
    var body: some View {
        let secCount = Int(ceil(totalSec))
        
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                ForEach(0...secCount, id: \.self) { s in
                    let x = CGFloat(s) * pxPerSec
                    Rectangle()
                        .fill(Color.black.opacity(s % 10 == 0 ? 0.7 : 0.35))
                        .frame(width: 1, height: s % 10 == 0 ? 14 : 7)
                        .offset(x: x)
                        .padding(.bottom, 16)
                    if s % 10 == 0 {
                        Text("\(s)s")
                            .font(.system(size: 12))
                            .frame(width: 40)
                            .bold()
                            .foregroundColor(.secondary)
                            .offset(x: x - 15, y: 10)
                            
                    }
                }
                
            }
            
        }
    }
}

