//
//  Detector.swift
//  PetoiSerialSwift
//
//  Created by Orlando Chen on 2021/3/29.
//

import Foundation

class BLEMessageDetector
{
    private var millisecond: Int!
    private var timer : Timer?
    
    // wake up the program every 100 milliseconds
    init(millisecond: Int = 100) {
        self.millisecond = millisecond
    }
    
    func startListen(target aTarget: Any, selector aSelector: Selector) {
        
        // create timer thread
        timer = Timer.scheduledTimer(timeInterval: 1.0 / 1000.0 * Double(millisecond),
                                     target: aTarget, selector: aSelector,
                                     userInfo: nil, repeats: true)
        
        // start timer
        timer?.fire()
    }
    
    func stopListen() {
        if timer != nil {
            timer!.invalidate()
            timer = nil
        }
    }
}
