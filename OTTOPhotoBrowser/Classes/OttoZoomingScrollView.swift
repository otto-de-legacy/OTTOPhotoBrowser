//
//  OttoZoomingScrollView.swift
//  OTTOPhotoBrowser
//
//  Created by Lukas Zielinski on 22/12/2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit

class OTTOZoomingScrollView: UIScrollView, UIScrollViewDelegate, OTTOTapDetectingViewDelegate, OTTOTapDetecingImageViewDelegate {
    
    var photo: OTTOPhoto? {
        didSet {
            displayImage()
        }
    }
    
    weak var photoBrowserView: OTTOPhotoBrowserView?
    private let tapView: OTTOTapDetectingView
    private let photoImageView: OTTOTapDetectingImageView
    private let progressView: UIProgressView
    private var isPinchoutDetected = false
    private var tapTimer: Timer?
    
    func prepareForReuse() {
        debugPrint("prepare for reuse")
        self.photo = nil
    }
    
    func setProgress(_ progress :CGFloat) { // TODO: make property or set directly
        progressView.setProgress(Float(progress), animated: true)
    }
    
    required init?(coder aDecoder: NSCoder) {
         fatalError("init(coder:) has not been implemented")
    }
    
    init(photoBrowserView: OTTOPhotoBrowserView) {
        
        self.photoBrowserView = photoBrowserView
    
        tapView = OTTOTapDetectingView(frame: CGRect.zero)
        photoImageView = OTTOTapDetectingImageView(frame: CGRect.zero)
        progressView = UIProgressView(frame: CGRect.zero)
        
        super.init(frame: CGRect.zero)
        
        tapView.tapDelegate = self
        tapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tapView.backgroundColor = UIColor.clear
        
        photoImageView.tapDelegate = self
        photoImageView.backgroundColor = UIColor.clear
        
        let screenBounds = UIScreen.main.bounds
        let isLandscape = UIDevice.current.orientation == .landscapeLeft || UIDevice.current.orientation == .landscapeRight
        let screenWidth : CGFloat = isLandscape ?  screenBounds.height : screenBounds.width
        let screenHeight : CGFloat = isLandscape ? screenBounds.width : screenBounds.height
        let progressViewFrame = CGRect(x: (screenWidth - 35) / 2, y: (screenHeight - 35) - 2, width: 35, height: 35)
        progressView.frame = progressViewFrame
        progressView.tag = 101
        
        addSubview(tapView)
        addSubview(photoImageView)
        addSubview(progressView)
        
        backgroundColor = UIColor.clear
        delegate = self
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        decelerationRate = UIScrollViewDecelerationRateFast
        autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    func displayImage() {
        guard let photo = photo else {
            return
        }
        
        maximumZoomScale = 1
        minimumZoomScale = 1
        zoomScale = 1
        contentSize = CGSize.zero
        
        if let image = photoBrowserView?.imageForPhoto(photo: photo) {
            progressView.removeFromSuperview()
            
            photoImageView.image = image
            photoImageView.isHidden = false
            
            let photoImageViewFrame = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
            photoImageView.frame = photoImageViewFrame
            contentSize = photoImageViewFrame.size
            
            setMaxMinZoomScalesForCurrentBounds()
        } else {
            photoImageView.isHidden = true
            progressView.alpha = 1
        }
        
        setNeedsLayout()
    }
    
    func setMaxMinZoomScalesForCurrentBounds() {
        maximumZoomScale = 1
        minimumZoomScale = 1
        zoomScale = 1
        
        if photoImageView.image == nil {
            return
        }
        
        var boundsSize = bounds.size
        boundsSize.width -= 0.1
        boundsSize.height -= 0.1
        
        let imageSize = photoImageView.frame.size
        
        let xScale = boundsSize.width / imageSize.width;    // the scale needed to perfectly fit the image width-wise
        let yScale = boundsSize.height / imageSize.height;  // the scale needed to perfectly fit the image height-wise
        let minScale = min(xScale, yScale);                 // use minimum of these to allow the image to become fully visible
        var maxScale: CGFloat = 4.0; // Allow double scale
        
        maxScale = UIScreen.main.scale
        if maxScale < minScale {
            maxScale = minScale * 2
        }
        
        
        self.maximumZoomScale = maxScale;
        self.minimumZoomScale = minScale;
        self.zoomScale = minScale;
        
        photoImageView.frame = CGRect(x: 0, y: 0, width: photoImageView.frame.size.width, height: photoImageView.frame.size.height)
        setNeedsLayout()
    }
    
    override func layoutSubviews() {
        tapView.frame = self.bounds
        
        super.layoutSubviews()
        
        let boundsSize = bounds.size
        var frameToCenter = photoImageView.frame
        
        if (frameToCenter.size.width < boundsSize.width) {
            frameToCenter.origin.x = floor((boundsSize.width - frameToCenter.size.width) / CGFloat(2))
        } else {
            frameToCenter.origin.x = 0;
        }
    
        if (frameToCenter.size.height < boundsSize.height) {
            frameToCenter.origin.y = floor((boundsSize.height - frameToCenter.size.height) / CGFloat(2));
        } else {
            frameToCenter.origin.y = 0;
        }
        
        if !photoImageView.frame.equalTo(frameToCenter) {
            photoImageView.frame = frameToCenter
        }
    }
    
    // MARK: UIScrollViewDelegate
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return photoImageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        setNeedsLayout()
        layoutIfNeeded()
        if zoomScale < (minimumZoomScale - minimumZoomScale * 0.4) {
            isPinchoutDetected = true
        }
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        photoBrowserView?.scrollViewDidEndZooming(scrollView, with: view, atScale: scale)
        if isPinchoutDetected {
            isPinchoutDetected = false
            photoBrowserView?.onPinchout()
        }
    }
    
    // MARK: Tap Detection
    
    func handleSingleTap() {
        onMainThread {
            self.photoBrowserView?.onTap()
        }
    }
    
    private func handleDoubleTap(_ touchPoint: CGPoint) {
        if zoomScale == maximumZoomScale {
            setZoomScale(minimumZoomScale, animated: true)
        } else {
            zoom(to: CGRect(x: touchPoint.x, y: touchPoint.y, width: 1, height: 1), animated: true)
        }
        
        photoBrowserView?.onZoomedWithDoubleTap()
    }
    
    // MARK: Image View Tap Detection
    
    func imageView(imageView: UIImageView, SingleTapDetected: UITouch) {
        // could be a double tap, wait for a moment before reporting
        tapTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(handleSingleTap), userInfo: nil, repeats: false)
    }
    
    func imageView(imageView: UIImageView, DoubleTapDetected touch: UITouch) {
        tapTimer?.invalidate() // dismiss reporting of single tap
        tapTimer = nil
        
        handleDoubleTap(touch.location(in: imageView))
    }
    
    // MARK: Background View Tap Detection
    
    func view(view: UIView, SingleTapDetected: UITouch) {
        // could be a double tap, wait for a moment before reporting
        tapTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(handleSingleTap), userInfo: nil, repeats: false)
    }
    
    func view(view: UIView, DoubleTapDetected touch: UITouch) {
        tapTimer?.invalidate() // dismiss reporting of single tap
        tapTimer = nil
        
        handleDoubleTap(touch.location(in: view))
    }
}
