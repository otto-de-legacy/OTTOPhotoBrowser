//
//  OTTOTapDetectingImageView.swift
//  OTTOPhotoBrowser
//
//  Created by Lukas Zielinski on 23/12/2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit

protocol OTTOTapDetecingImageViewDelegate: class {
    func imageView(imageView: UIImageView, SingleTapDetected:UITouch)
    func imageView(imageView: UIImageView, DoubleTapDetected:UITouch)
}

class OTTOTapDetectingImageView: UIImageView {
    weak var tapDelegate: OTTOTapDetecingImageViewDelegate?
    
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
            tapDelegate?.imageView(imageView: self, SingleTapDetected: touch)
        case 2:
            tapDelegate?.imageView(imageView: self, DoubleTapDetected: touch)
        default:
            break
        }
        
        next?.touchesEnded(touches, with: event)
    }

}
