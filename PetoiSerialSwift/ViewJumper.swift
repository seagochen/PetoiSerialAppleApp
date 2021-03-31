//
//  ViewJumper.swift
//  PetoiSerialSwift
//
//  Created by Orlando Chen on 2021/3/31.
//

import Foundation
import UIKit

class ViewJumper {
    
    static func forward(from: UIViewController, to: UIViewController) {
        from.present(to, animated: true, completion: nil)
    }
    
    static func backward(from: UIViewController) {
        from.dismiss(animated: true, completion: nil)
    }
    
}
