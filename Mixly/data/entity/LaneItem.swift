//
//  LaneItem.swift
//  Mixly
//
//  Created by Mehdi Oturak on 18.12.2025.
//

import Foundation


struct LaneItem: Identifiable, Equatable {
    
    let id: UUID = UUID()
    var sourceID: UUID
    var originalSourceID: UUID
    
    
    
    var sourceStartSec: Double
    var lengthSec: Double
    var timelineStartSec: Double
    
    
    var volume: Float = 1.0
    var rate: Float = 1.0
    var reverbMix: Float = 0.0
    var fadeInSec: Double = 0.0
    var fadeOutSec: Double = 0.0
    
    
    // kaynak şarkın içinde bitiş saniyesi
    var sourceEndSec: Double {
        sourceStartSec + lengthSec
    }
    // timeline üzerinde bitiş süresi
    var timelineEndSec: Double {
        timelineStartSec + lengthSec
    }
    
    
}

