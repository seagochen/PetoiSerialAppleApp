//
//  BLECmdStackHandler.swift
//  PetoiSerialSwift
//
//  Created by Orlando Chen on 2021/4/2.
//

import UIKit
import Foundation


class BLESignalStackHandler: BLECommunicationHandler {
    
    var tokens = Array<(cmd: String, feedback: String)>()
    
    
    // 发送数据
    override func sendCmdViaSerial(msg: String) {
        let final: (cmd: String, feedback: String) = (cmd: msg, feedback: "")
        
        // always keeps the size to 15;
        if (tokens.count > 15) {
            tokens.removeFirst()
        }
        
        pushToken(token: final)
        print("sent: \(msg)")
        
        super.sendCmdViaSerial(msg: msg)
    };
    
    // 是否为空
    func isEmpty() -> Bool {
        return tokens.isEmpty
    };

    // 压栈
    func pushToken(token: (cmd: String, feedback: String)) {
        tokens.append(token)
    }

    // 出栈
    func popupToken() -> (cmd: String, feedback: String) {
        
        if tokens.count > 0 {
            let token = tokens.removeLast()
            return token
        }
        
        return (cmd: "", feedback: "")
    };
    
    
    func messageFromTop() -> String {
        
        if !isEmpty() {
            let token = tokens.last
            return token?.feedback ?? ""
        }
        
        return ""
    }
    
    // debug用
    func debugStack() {
        print("stack info----\(tokens.count)")
        
        for token in tokens {
            print(">>>\(token.cmd)<<<<>>>\(token.feedback)<<<")
        }
    };
}
