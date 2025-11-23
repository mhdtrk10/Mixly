//
//  AudioSegment.swift
//  Mixly
//
//  Created by Mehdi Oturak on 12.11.2025.
//

import Foundation

struct AudioSegment {
    var url: URL
    var durationSec: Double
    var startSec: Double = 0
    var endSec: Double
    var waveform: [Float]? = nil
    
    init(url: URL, durationSec: Double) {
        self.url = url
        self.durationSec = max(0, durationSec)
        self.endSec = durationSec
    }
    
    var selectedLengthSec: Double {
        max(0,endSec - startSec)
    }
    
}
