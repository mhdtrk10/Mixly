//
//  Lane.swift
//  Mixly
//
//  Created by Mehdi Oturak on 18.12.2025.
//

import Foundation


struct Lane: Identifiable, Equatable {
    let id: UUID = UUID()
    var items: [LaneItem] = []
}
