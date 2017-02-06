//
//  OTTOPhotoBrowserView.swift
//  OTTOPhotoBrowser
//
//  Created by Lukas Zielinski on 22/12/2016.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import SDWebImage

public class OTTOPhotoBrowserView: UIView, UIScrollViewDelegate {
    
    private let tagOffset = 1000
    private let pagingScrollView: UIScrollView
    private var visiblePages = Set<OTTOZoomingScrollView>()
    private var _currentPageIndex = 0
    private var isLastEventDoubleTapZoom = false
    private var _photos = [OTTOPhoto]()
    private var _passedPhotos = [OTTOPhoto]()
    
    public var margin: CGFloat = 0
    public var padding: CGFloat = 10
    
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
    
    public var currentPageIndex: Int {
        if numberOfPhotos() == 0 { return 0 }
        return _currentPageIndex % realNumberOfPhotos()
    }
    
    public func showImage(index: Int) {
        _currentPageIndex = index
        centerContentOffsetToMiddleSegment()
        didStartViewingPage(atIndex: index)
    }
    
    public weak var delegate: OTTOPhotoBrowserDelegate?
    
    public override init(frame: CGRect) {
        pagingScrollView = UIScrollView()
        super.init(frame: frame)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        pagingScrollView = UIScrollView()
        super.init(coder: aDecoder)
    }
    
    private func load() {
        backgroundColor = UIColor.white
        clipsToBounds = true
        
        pagingScrollView.isPagingEnabled = true
        pagingScrollView.delegate = self
        pagingScrollView.showsVerticalScrollIndicator = false
        pagingScrollView.showsHorizontalScrollIndicator = false
        pagingScrollView.backgroundColor = UIColor.clear
        addSubview(pagingScrollView)
        
        setNeedsLayout()
        layoutIfNeeded()
        
        centerContentOffsetToMiddleSegment()
        didStartViewingPage(atIndex: _currentPageIndex)
    }

    override public func layoutSubviews() {
        super.layoutSubviews()
        
        pagingScrollView.frame = frameForPagingScrollView()
        pagingScrollView.contentSize = contentSizeForPagingScrollView()
        
        for page in visiblePages {
            page.removeFromSuperview()
        }
        
        visiblePages.removeAll()
        
        pagingScrollView.contentOffset = contentOffsetForPage(atIndex: _currentPageIndex)
        createPages()
    }
    
    private func createPages() {
        if numberOfPhotos() == 0 { return }
        
        let visibleBounds = pagingScrollView.bounds
        
        var firstIndex = Int(floor(visibleBounds.minX + margin * 2) / visibleBounds.width)
        var lastIndex = Int(floor(visibleBounds.maxX - margin * 2 - 1) / visibleBounds.width)
        
        firstIndex = max(0, min(numberOfPhotos() - 1, firstIndex))
        lastIndex = max(0, min(numberOfPhotos() - 1, lastIndex))

        var pageIndex = 0
        for page in visiblePages {
            pageIndex = page.tag - tagOffset
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
        if let image = photo.image {
            return image
        } else {
            loadAndDisplay(photo: photo)
            return nil
        }
    }
    
    private func configurePage(_ page: OTTOZoomingScrollView, forIndex index: Int) {
        page.frame = frameForPage(atIndex: index)
        page.tag = tagOffset + index
        page.photo = _photos[index]
    }
    
    private func didStartViewingPage(atIndex index: Int) {
        if numberOfPhotos() == 0 { return }
        
        let photo = _photos[index]
        if photo.image == nil {
            loadAndDisplay(photo: photo)
        } else {
            loadAdjacentPhotosIfNecessary(forPhoto: photo)
        }
        
        delegate?.photoBrowser(self, firedEvent: .didSwipeToImage)
    }
    
    private func loadAdjacentPhotosIfNecessary(forPhoto photo: OTTOPhoto) {
        guard let page = pageDisplayingPhoto(photo) else { return }
        
        let pIndex = pageIndex(page)
        if _currentPageIndex == pIndex {
            if pIndex > 0 {
                let photoAtIndex = _photos[pIndex - 1]
                if photoAtIndex.image == nil {
                    loadAndDisplay(photo: photoAtIndex)
                }
            }
            
            if pIndex < numberOfPhotos() - 1 {
                let photoAtIndex = _photos[pIndex+1]
                if photoAtIndex.image == nil {
                    loadAndDisplay(photo: photoAtIndex)
                }
            }
        }
    }
    
    private func loadAndDisplay(photo: OTTOPhoto) {
        let manager = SDWebImageManager.shared()!
        let _ = manager.downloadImage(with: photo.url, options: .retryFailed, progress: nil, completed: { (image, error, cacheType, finished, imageUrl) in
            guard let image = image else { return }
            photo.image = image
            
            if let page = self.pageDisplayingPhoto(photo) {
                page.displayImage()
                self.loadAdjacentPhotosIfNecessary(forPhoto: photo)
            }
        })
    }
    
    private func pageDisplayingPhoto(_ photo: OTTOPhoto) -> OTTOZoomingScrollView? {
        return visiblePages.filter {
            if let pagePhoto = $0.photo, pagePhoto == photo {
                return true
            }
            return false
        }.first
    }
    
    private func pageIndex(_ page: OTTOZoomingScrollView) -> Int {
        return page.tag - tagOffset
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
    
    private func frameForPage(atIndex index: Int) -> CGRect {
        let bounds = pagingScrollView.bounds
        var pageFrame = bounds
        pageFrame.size.width -= 2 * margin
        pageFrame.origin.x = (bounds.size.width * CGFloat(index)) + margin;
        return pageFrame
    }
    
    private func frameForPagingScrollView() -> CGRect {
        var frame = bounds
        frame.origin.x += padding
        frame.size.width -= 2 * padding
        return frame
    }
    
    private func contentSizeForPagingScrollView() -> CGSize {
        let bounds = pagingScrollView.bounds
        return CGSize(width: bounds.size.width * CGFloat(numberOfPhotos()), height: bounds.size.height)
    }
    
    private func contentOffsetForPage(atIndex index: Int) -> CGPoint {
        let pageWidth = pagingScrollView.bounds.size.width
        let newOffset = CGFloat(index) * pageWidth
        return CGPoint(x: newOffset, y: 0)
    }
    
    private func centerContentOffsetToMiddleSegment() {
        if numberOfPhotos() == 0 { return }
        
        _currentPageIndex = (_currentPageIndex % realNumberOfPhotos()) + realNumberOfPhotos()
        let pageFrame = frameForPage(atIndex: _currentPageIndex)
        
        pagingScrollView.setContentOffset(CGPoint(x: pageFrame.origin.x - margin, y: 0), animated: false)
    }
    
    // MARK: UIScrollViewDelegate
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        createPages()
        
        let visibleBounds = pagingScrollView.bounds
        var index = Int(floor(visibleBounds.midX / visibleBounds.width))
        index = max(0, min(numberOfPhotos() - 1, index))
        
        let previousCurrentPageIndex = _currentPageIndex
        _currentPageIndex = index
        
        if _currentPageIndex != previousCurrentPageIndex {
            didStartViewingPage(atIndex: index)
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
