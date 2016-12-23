//
//  ViewController.swift
//  OTTOPhotoBrowser
//
//  Created by Lukas Zielinski on 12/22/2016.
//  Copyright (c) 2016 Lukas Zielinski. All rights reserved.
//

import UIKit

class ViewController: UIViewController, OTTOPhotoBrowserDelegate {

    @IBOutlet var photoBrowser: OTTOPhotoBrowserView!
    @IBOutlet var counterLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let photos = [
            "http://www.clipartkid.com/images/376/bullet-1-red-1-clip-art-at-clker-com-vector-clip-art-online-royalty-UgUb3A-clipart.png",
            "http://www.drodd.com/images15/2-17.png",
            "http://www.drodd.com/images15/3-17.png"
            ].map { OTTOPhoto(withUrl: URL(string: $0)!) }

        photoBrowser.delegate = self
        photoBrowser.photos = photos
        
        updateCounterLabel()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: OTTOPhotoBrowserDelegate
    
    func photoBrowser(_ photoBrowser: OTTOPhotoBrowserView, firedEvent event: OTTOPhotoBrowserEvent) {
        switch event {
        case .didSwipeToImage: updateCounterLabel()
        case .doubleTapZoom: print("EVENT: double tap zoom")
        case .pinchout: print("EVENT: pinchout")
        case .pinchZoom: print("EVENT: pinchzoom")
        case .tap: print("EVENT: tap")
        }
    }
    
    private func updateCounterLabel() {
        let text = "\(photoBrowser.currentPageIndexStartingAtOne)/\(photoBrowser.photos.count)"
        counterLabel.text = text
    }
}

