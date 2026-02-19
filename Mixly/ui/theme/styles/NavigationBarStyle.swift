//
//  NavigationBarStyle.swift
//  Mixly
//
//  Created by Mehdi Oturak on 1.12.2025.
//

import Foundation
import SwiftUI

struct NavigationBarStyle {
    static func setupNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = UIColor(AppColors.Navbar)
        
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor(Color.white),
            
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(Color.white),
            
        ]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
       
        
        
 
    }
    
}


