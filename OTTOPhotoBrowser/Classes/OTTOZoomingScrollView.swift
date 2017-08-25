//
//  OttoZoomingScrollView.swift
//  OTTOPhotoBrowser
//
//  Created by Lukas Zielinski on 22/12/2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit

class OTTOZoomingScrollView: UIScrollView, UIScrollViewDelegate {
    
    var photo: OTTOPhoto? {
        didSet {
            displayImage()
        }
    }
    
    var padding: CGFloat = 0
    weak var photoBrowserView: OTTOPhotoBrowserView?
    private let activityIndicatorView: UIActivityIndicatorView
    private let tapView: UIView
    private let photoImageView: UIImageView
    private var isPinchoutDetected = false
    
    func prepareForReuse() {
        photo = nil
    }
    
    required init?(coder aDecoder: NSCoder) {
         fatalError("init(coder:) has not been implemented")
    }
    
    init(photoBrowserView: OTTOPhotoBrowserView) {
        self.photoBrowserView = photoBrowserView
    
        activityIndicatorView = UIActivityIndicatorView()
        tapView = UIView(frame: CGRect.zero)
        photoImageView = UIImageView(frame: CGRect.zero)
        
        super.init(frame: CGRect.zero)
        
        activityIndicatorView.activityIndicatorViewStyle = .gray
        activityIndicatorView.hidesWhenStopped = true
        addSubview(activityIndicatorView)
        
        tapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tapView.backgroundColor = UIColor.clear
        let tapViewSingleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(gestureRecognizer:)))
        let tapViewDoubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(gestureRecognizer:)))
        tapViewDoubleTapRecognizer.numberOfTapsRequired = 2
        tapViewSingleTapRecognizer.require(toFail: tapViewDoubleTapRecognizer)
        tapView.addGestureRecognizer(tapViewSingleTapRecognizer)
        tapView.addGestureRecognizer(tapViewDoubleTapRecognizer)
        
        photoImageView.backgroundColor = UIColor.clear
        let imageViewSingleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(gestureRecognizer:)))
        let imageViewDoubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(gestureRecognizer:)))
        imageViewDoubleTapRecognizer.numberOfTapsRequired = 2
        imageViewSingleTapRecognizer.require(toFail: imageViewDoubleTapRecognizer)
        photoImageView.isUserInteractionEnabled = true
        photoImageView.addGestureRecognizer(imageViewSingleTapRecognizer)
        photoImageView.addGestureRecognizer(imageViewDoubleTapRecognizer)
        addSubview(tapView)
        addSubview(photoImageView)
        
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
        
        minimumZoomScale = 1
        maximumZoomScale = 1
        zoomScale = 1
        
        if let image = photoBrowserView?.imageForPhoto(photo: photo), image.size.width > 0, image.size.height > 0 {
            photoImageView.image = image
            photoImageView.isHidden = false
            
            let photoImageViewFrame = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
            photoImageView.frame = photoImageViewFrame.insetBy(dx: padding, dy: padding)
            contentSize = photoImageViewFrame.size
            
            setMaxMinZoomScalesForCurrentBounds()
            activityIndicatorView.stopAnimating()
        } else {
            photoImageView.isHidden = true
            activityIndicatorView.startAnimating()
        }
        setNeedsLayout()
    }
    
    private func setMaxMinZoomScalesForCurrentBounds() {
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
        let maxScale = minScale * 2.5
        
        maximumZoomScale = maxScale;
        minimumZoomScale = minScale;
        zoomScale = minScale;
        
        photoImageView.frame = CGRect(x: 0, y: 0, width: photoImageView.frame.size.width, height: photoImageView.frame.size.height).insetBy(dx: padding, dy: padding)
        
        setNeedsLayout()
    }
    
    override func layoutSubviews() {
        tapView.frame = bounds
        
        super.layoutSubviews()
        
        let boundsSize = bounds.size
        var frameToCenter = photoImageView.frame
        
        if frameToCenter.size.width < boundsSize.width {
            frameToCenter.origin.x = floor((boundsSize.width - frameToCenter.size.width) / CGFloat(2))
        } else {
            frameToCenter.origin.x = 0;
        }
    
        if frameToCenter.size.height < boundsSize.height {
            frameToCenter.origin.y = floor((boundsSize.height - frameToCenter.size.height) / CGFloat(2));
        } else {
            frameToCenter.origin.y = 0;
        }
        
        photoImageView.frame = frameToCenter
        
        activityIndicatorView.center = CGPoint(x: bounds.midX, y: bounds.midY)
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
    
    func handleSingleTap(gestureRecognizer: UITapGestureRecognizer) {
        photoBrowserView?.onTap()
    }
    
    func handleDoubleTap(gestureRecognizer: UITapGestureRecognizer) {
        let touchPoint = gestureRecognizer.location(in: photoImageView)
        if zoomScale == maximumZoomScale {
            setZoomScale(minimumZoomScale, animated: true)
        } else {
            zoom(to: CGRect(x: touchPoint.x, y: touchPoint.y, width: 1, height: 1), animated: true)
        }
        
        photoBrowserView?.onZoomedWithDoubleTap()
    }
}
