//
//  OTTOPhotoBrowserView.swift
//  OTTOPhotoBrowser
//
//  Created by Lukas Zielinski on 22/12/2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit

public class OTTOPhotoBrowserView: UIView, UIScrollViewDelegate {
    
    private let PADDING: CGFloat = 10
    private let TAG_OFFSET = 1000
    
    private let pagingScrollView: UIScrollView
    private var visiblePages = Set<OTTOZoomingScrollView>()
    private var _currentPageIndex = 0
    private var isLastEventDoubleTapZoom = false
    private var _photos = [OTTOPhoto]()
    private var _passedPhotos = [OTTOPhoto]()
    
    public var photos: [OTTOPhoto] {
        set {
            _passedPhotos = newValue
            _photos = newValue + newValue + newValue
            load()
        }
        
        get {
            return _passedPhotos
        }
    }
    
    public var currentPageIndexStartingAtOne: Int {
        get {
            return (_currentPageIndex % realNumberOfPhotos()) + 1
        }
    }
    
    public weak var delegate: OTTOPhotoBrowserDelegate?
    
    override init(frame: CGRect) {
        pagingScrollView = UIScrollView()
        super.init(frame: frame)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onImageLoadedNotification(notification:)), name: Notifications.ImageLoadingFinishedNotification, object: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        pagingScrollView = UIScrollView()
        super.init(coder: aDecoder)
        
        NotificationCenter.default.addObserver(self, selector: #selector(onImageLoadedNotification(notification:)), name: Notifications.ImageLoadingFinishedNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func load() {
        
        backgroundColor = UIColor.white
        clipsToBounds = true
        
        pagingScrollView.isPagingEnabled = true
        pagingScrollView.delegate = self
        pagingScrollView.showsVerticalScrollIndicator = false
        pagingScrollView.showsHorizontalScrollIndicator = false
        pagingScrollView.backgroundColor = UIColor.clear
        
        
        addSubview(pagingScrollView)
        
        centerContentOffsetToMiddleSegment()
        didStartViewingPage(AtIndex: _currentPageIndex)
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        
        pagingScrollView.frame = frameForPagingScrollView()
        pagingScrollView.contentSize = contentSizeForPagingScrollView()
        
        // "performLayout"
        
        for page in visiblePages {
            page.removeFromSuperview()
        }
        
        visiblePages.removeAll()
        //recycledPages.removeAll()
        
        pagingScrollView.contentOffset = contentOffsetForPage(AtIndex: _currentPageIndex)
        tilePages()
        
        debugPrint("layoutSubviews completed")
    }
    
    private func tilePages() {
        let visibleBounds = pagingScrollView.bounds
        
        var firstIndex = Int(floor(visibleBounds.minX + PADDING * 2) / visibleBounds.width)
        var lastIndex = Int(floor(visibleBounds.maxX - PADDING * 2 - 1) / visibleBounds.width)
        
        if firstIndex < 0 {
            firstIndex = 0
        }
        
        if firstIndex > (numberOfPhotos() - 1) {
            firstIndex = numberOfPhotos() - 1
        }
        
        if lastIndex < 0 {
            lastIndex = 0
        }
        
        if lastIndex > (numberOfPhotos() - 1) {
            lastIndex = numberOfPhotos() - 1
        }

        var pageIndex = 0
        for page in visiblePages {
            pageIndex = page.tag - TAG_OFFSET
            if (pageIndex < firstIndex || pageIndex > lastIndex) {
                visiblePages.remove(page)
                page.prepareForReuse()
                page.removeFromSuperview()
            }
        }
        
        // Add missing pages
        (firstIndex...lastIndex).forEach { (index) in
            if !isDisplayingPageForIndex(index: index) {
                // Add new page
                
                let page = OTTOZoomingScrollView(photoBrowserView: self)
                page.backgroundColor = UIColor.clear
                page.isOpaque = true
                
                configurePage(page, forIndex: index)
                visiblePages.insert(page)
                pagingScrollView.addSubview(page)
                debugPrint("Added page at index \(index)")
            }
        }
    }
    
    func onTap() {
        delegate?.photoBrowser(self, firedEvent: .tap)
    }
    
    func onZoomedWithDoubleTap() {
        delegate?.photoBrowser(self, firedEvent: .doubleTapZoom)
        isLastEventDoubleTapZoom = true
    }
    
    func onPinchout() {
        delegate?.photoBrowser(self, firedEvent: .pinchout)
    }
    
    func imageForPhoto(photo: OTTOPhoto) -> UIImage? {
        if let underlyingImage = photo.underlyingImage {
            return underlyingImage
        } else {
            photo.loadUnterlyingImageAndNotify()
            return nil
        }
    }
    
    private func configurePage(_ page: OTTOZoomingScrollView, forIndex index: Int) {
        page.frame = frameForPage(AtIndex: index)
        page.tag = TAG_OFFSET + index
        page.photo = _photos[index];
        
        page.photo?.progressUpdateBlock = { [weak page] (progress) in
            page?.setProgress(progress)
        }
    }
    
    private func didStartViewingPage(AtIndex index: Int) {
        debugPrint("did start viewing page at: \(index)")
        let photo = _photos[index]
        if photo.underlyingImage != nil {
            loadAdjacentPhotosIfNecessary(ForPhoto: photo)
        } else {
            photo.loadUnterlyingImageAndNotify()
        }
        
        delegate?.photoBrowser(self, firedEvent: .didSwipeToImage)
    }
    
    private func loadAdjacentPhotosIfNecessary(ForPhoto photo: OTTOPhoto) {
        guard let page = pageDisplayingPhoto(photo) else { return }
        
        let pIndex = pageIndex(page)
        if _currentPageIndex == pIndex {
            if pIndex > 0 {
                let photoAtIndex = _photos[pIndex - 1]
                if photoAtIndex.underlyingImage == nil {
                    photoAtIndex.loadUnterlyingImageAndNotify()
                }
            }
            
            if pIndex < numberOfPhotos() - 1 {
                let photoAtIndex = _photos[pIndex+1]
                if photoAtIndex.underlyingImage == nil {
                    photoAtIndex.loadUnterlyingImageAndNotify()
                }
            }
        }
    }
    
    private func pageDisplayingPhoto(_ photo: OTTOPhoto) -> OTTOZoomingScrollView? {
        return visiblePages.filter {
            guard let pagePhoto = $0.photo else {
                return false
            }
            return pagePhoto == photo
        }.first
    }
    
    private func pageIndex(_ page: OTTOZoomingScrollView) -> Int {
        return page.tag - TAG_OFFSET
    }
    
    private func isDisplayingPageForIndex(index: Int) -> Bool {
        return visiblePages.map{ pageIndex($0) }.contains(index)
    }
    
    private func numberOfPhotos() -> Int {
        return _photos.count
    }
    
    private func realNumberOfPhotos() -> Int {
        return _photos.count / 3
    }
    
    private func frameForPage(AtIndex index: Int) -> CGRect {
        let bounds = pagingScrollView.bounds
        var pageFrame = bounds
        pageFrame.size.width -= 2 * PADDING
        pageFrame.origin.x = (bounds.size.width * CGFloat(index)) + PADDING;
        return pageFrame
    }
    
    private func frameForPagingScrollView() -> CGRect {
        var frame = bounds
        frame.origin.x -= PADDING
        frame.size.width += 2*PADDING
        return frame
    }
    
    private func contentSizeForPagingScrollView() -> CGSize {
        let bounds = pagingScrollView.bounds
        return CGSize(width: bounds.size.width * CGFloat(numberOfPhotos()), height: bounds.size.height)
    }
    
    private func contentOffsetForPage(AtIndex index: Int) -> CGPoint {
        let pageWidth = pagingScrollView.bounds.size.width
        let newOffset = CGFloat(index) * pageWidth
        return CGPoint(x: newOffset, y: 0)
    }
    
    private func centerContentOffsetToMiddleSegment() {
        _currentPageIndex = (_currentPageIndex % realNumberOfPhotos()) + realNumberOfPhotos()
        let pageFrame = frameForPage(AtIndex: _currentPageIndex)
        
        pagingScrollView.setContentOffset(CGPoint(x: pageFrame.origin.x - PADDING, y: 0), animated: false)
    }
    
    // MARK: Handle notifications
    
    func onImageLoadedNotification(notification: Notification) {
        debugPrint("onImageLoadedNotification")
        
        if let photo = notification.object as? OTTOPhoto,
            let page = pageDisplayingPhoto(photo)
        {
            if photo.underlyingImage != nil {
                page.displayImage()
                loadAdjacentPhotosIfNecessary(ForPhoto: photo)
            } else {
                debugPrint("TODO: Display image failure")
            }
        }
    }
    
    // MARK: UIScrollViewDelegate
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        tilePages()
        
        let visibleBounds = pagingScrollView.bounds
        var index = Int(floor(visibleBounds.midX / visibleBounds.width))
        if index < 0 {
            index = 0
        }
        if index > (numberOfPhotos() - 1) {
            index = numberOfPhotos() - 1
        }
        
        let previousCurrentPageIndex = _currentPageIndex
        _currentPageIndex = index
        
        if _currentPageIndex != previousCurrentPageIndex {
            didStartViewingPage(AtIndex: index)
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        centerContentOffsetToMiddleSegment()
    }
    
    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        if isLastEventDoubleTapZoom {
            isLastEventDoubleTapZoom = false
        } else {
            delegate?.photoBrowser(self, firedEvent: .pinchZoom)
        }
    }
}
