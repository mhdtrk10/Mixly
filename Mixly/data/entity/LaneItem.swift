//
//  LaneItem.swift
//  Mixly
//
//  Created by Mehdi Oturak on 18.12.2025.
//

import Foundation


struct LaneItem: Identifiable, Equatable {
    
    let id: UUID = UUID()
    
    // hangi kaynak şarkı geliyor
    let sourceID: UUID
    
    // kaynak şarkının içinde kaçıncı saniyeden başlayacak
    var sourceStartSec: Double
    
    // kaç saniye sürecek
    var lengthSec: Double
    
    // global timeline da kaçıncı saniyede başlayacak
    var timelineStartSec: Double
    
    //ses yüksekliği için
    var volume: Float = 1.0
    
    // kaynak şarkın içinde bitiş saniyesi
    var sourceEndSec: Double {
        sourceStartSec + lengthSec
    }
    // timeline üzerinde bitiş süresi
    var timelineEndSec: Double {
        timelineStartSec + lengthSec
    }
    
    
}

