//
//  OTTOPhoto.swift
//  OTTOPhotoBrowser
//
//  Created by Lukas Zielinski on 22/12/2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import SDWebImage

public class OTTOPhoto: Equatable {
    let url: URL    
    var image: UIImage?
    
    public init(withUrl url: URL) {
        self.url = url
    }
}

public func ==(lhs: OTTOPhoto, rhs: OTTOPhoto) -> Bool {
    return lhs.url == rhs.url
}
