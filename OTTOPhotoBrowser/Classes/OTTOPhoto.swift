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
    let photoUrl: URL
    var progressUpdateBlock: ((CGFloat)->())?
    
    private(set) var underlyingImage: UIImage?
    
    public init(withUrl url: URL) {
        photoUrl = url
    }
    
    func loadUnterlyingImageAndNotify() {
        let manager = SDWebImageManager.shared()!
        let _ = manager.downloadImage(with: photoUrl, options: .retryFailed, progress: { (receivedSize, expectedSize) in
            let progress: CGFloat = CGFloat(receivedSize) / CGFloat(expectedSize)
            if let progressUpdateBlock = self.progressUpdateBlock {
                progressUpdateBlock(progress)
            }
        }, completed: { (image, error, cacheType, finished, imageUrl) in
            if let image = image {
                self.underlyingImage = image
                NotificationCenter.default.post(name: Notifications.ImageLoadingFinishedNotification, object: self)
            }
        })
    }
    
}

public func ==(lhs: OTTOPhoto, rhs: OTTOPhoto) -> Bool {
    return lhs.photoUrl == rhs.photoUrl
}
