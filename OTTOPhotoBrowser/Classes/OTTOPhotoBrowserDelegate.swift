//
//  OTTOPhotoBrowserDelegate.swift
//  OTTOPhotoBrowser
//
//  Created by Lukas Zielinski on 23/12/2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit

public enum OTTOPhotoBrowserEvent {
    case pinchout // The user pinch-zoomed out beyond a certain treshold. Can be used as a close event.
    case tap
    case pinchZoom
    case doubleTapZoom
    case didSwipeToImage
}

public protocol OTTOPhotoBrowserDelegate: class {
    func photoBrowser(_ photoBrowser: OTTOPhotoBrowserView, firedEvent: OTTOPhotoBrowserEvent)
}
