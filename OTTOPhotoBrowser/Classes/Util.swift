//
//  Util.swift
//  OTTOPhotoBrowser
//
//  Created by Lukas Zielinski on 22/12/2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import Foundation



func onMainThread(block: @escaping () -> ()) {
    if Thread.isMainThread {
        block()
    } else {
        OperationQueue.main.addOperation({ block() })
    }
}

func debugPrint(_ s: String) {
    // uncomment to enable debug printing
    print(s)
}
