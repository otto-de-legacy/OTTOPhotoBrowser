//
//  OTTOTapDetectingView.swift
//  OTTOPhotoBrowser
//
//  Created by Lukas Zielinski on 23/12/2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit

protocol OTTOTapDetectingViewDelegate: class {
    func view(view: UIView, SingleTapDetected: UITouch)
    func view(view: UIView, DoubleTapDetected: UITouch)
}

class OTTOTapDetectingView: UIView {
    weak var tapDelegate: OTTOTapDetectingViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.isUserInteractionEnabled = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.isUserInteractionEnabled = true
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        
        switch(touch.tapCount) {
        case 1:
            tapDelegate?.view(view: self, SingleTapDetected: touch)
        case 2:
            tapDelegate?.view(view: self, DoubleTapDetected: touch)
        default:
            break
        }
        
        next?.touchesEnded(touches, with: event)
    }

}
