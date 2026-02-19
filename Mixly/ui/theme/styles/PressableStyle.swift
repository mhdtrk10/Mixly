//
//  PressableStyle.swift
//  Mixly
//
//  Created by Mehdi Oturak on 4.01.2026.
//



import Foundation
import SwiftUI


struct PressableStyle: ButtonStyle {
    
    var pressedScale: CGFloat = 1.1
    var shadowRadius: CGFloat = 10
    
   
    
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? pressedScale : 1)
            .shadow(radius: configuration.isPressed ? 12 : shadowRadius)
            .animation(.spring(response: 0.25, dampingFraction: 0.2), value: configuration.isPressed)
    }
     
    
        
}
