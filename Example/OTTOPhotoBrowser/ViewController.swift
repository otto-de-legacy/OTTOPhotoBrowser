//
//  ViewController.swift
//  OTTOPhotoBrowser
//
//  Created by Lukas Zielinski on 12/22/2016.
//  Copyright (c) 2016 Lukas Zielinski. All rights reserved.
//

import UIKit
import OTTOPhotoBrowser

class ViewController: UIViewController, OTTOPhotoBrowserDelegate {

    @IBOutlet var photoBrowser: OTTOPhotoBrowserView!
    @IBOutlet var counterLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let photos = [
            "https://github.com/otto-de/OTTOPhotoBrowser/raw/master/Example/Assets/1.png",
            "https://github.com/otto-de/OTTOPhotoBrowser/raw/master/Example/Assets/2.png",
            "https://github.com/otto-de/OTTOPhotoBrowser/raw/master/Example/Assets/3.png"
        ].map { OTTOPhoto(withUrl: URL(string: $0)!) }

        photoBrowser.delegate = self
        photoBrowser.photos = photos
        photoBrowser.padding = 12
        photoBrowser.margin = 3
        
        updateCounterLabel()
    }

    // MARK: OTTOPhotoBrowserDelegate
    
    func photoBrowser(_ photoBrowser: OTTOPhotoBrowserView, firedEvent event: OTTOPhotoBrowserEvent) {
        switch event {
        case .didSwipeToImage: updateCounterLabel()
        case .doubleTapZoom: print("EVENT: double tap zoom")
        case .pinchout: print("EVENT: pinchout")
        case .pinchZoom: print("EVENT: pinchzoom")
        case .tap: print("EVENT: tap -- show image index 2")
            photoBrowser.showImage(index: 2)
        }
    }
    
    private func updateCounterLabel() {
        let text = "\(photoBrowser.currentPageIndex + 1)/\(photoBrowser.photos.count)"
        counterLabel.text = text
    }
}

