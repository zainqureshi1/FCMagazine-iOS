//
//  ReaderViewController.swift
//  FCMagazine
//
//  Created by Zain on 2/27/17.
//  Copyright © 2017 e2esp. All rights reserved.
//

import UIKit

class ReaderViewController: UIViewController, DJKFlipperDataSource, UIScrollViewDelegate {
    @IBOutlet weak var flipView: DJKFlipperView!
    
    @IBOutlet weak var thumbnailScrollView: UIScrollView!
    
    var magazineItem: Magazine?
    var pageViews = [UIScrollView]()
    
    var thumbnailsTimer : Timer?
    var thumbnailsVisible = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadPages()
        flipView.dataSource = self
        
        self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.lockOrientation(.allButUpsideDown, andRotateTo: .unknown)
        }
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showThumbnails)))
        thumbnailsVisible = true
        resetThumbnailsTimer()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        thumbnailsTimer?.invalidate()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {self.updateFrames(to: size)})
        //updateFrames(to: size)
//        if UIDevice.current.orientation.isLandscape {
//            print("Landscape")
//        } else {
//            print("Portrait")
//        }
    }
    
    func loadPages() {
        if let magazine = self.magazineItem {
            let frame = self.view.bounds
            let height = frame.width*1.4
            //let flipFrame = CGRect(x: 0, y: (frame.size.height - height)*0.5, width: frame.width, height: height)
            let imageFrame = CGRect(x: 0, y: 0, width: frame.width, height: height)
            flipView.frame = imageFrame
            
            var thumbnailXOffset:CGFloat = 0;
            var thumbnailWidth:CGFloat = 0
            var thumbnailHeight:CGFloat = 0
            
            let dirPath = magazine.dirPath
            for i in 1...magazine.pageCount {
                let imagePath = dirPath + "/\(i)"
                let image = UIImage(named: imagePath)
                
                let imageView = UIImageView(image: image)
                imageView.frame = imageFrame
                imageView.contentMode = .scaleAspectFit
                
                let scrollView = UIScrollView(frame: imageFrame)
                scrollView.minimumZoomScale = 1;
                scrollView.zoomScale = 1.01
                scrollView.maximumZoomScale = 3
                scrollView.bounces = true
                scrollView.delegate = self
                scrollView.showsVerticalScrollIndicator = false
                scrollView.showsHorizontalScrollIndicator = false
                scrollView.addSubview(imageView)
                
                pageViews.append(scrollView)
                
                let imageThumbnail = resizeImage(image: image!, newWidth: 50)
                thumbnailWidth = (imageThumbnail?.size.width)!
                thumbnailHeight = (imageThumbnail?.size.height)!
                let imageViewThumbnail = UIImageView(image: imageThumbnail!)
                imageViewThumbnail.tag = i
                imageViewThumbnail.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(thumbnailTapped(tapGestureRecognizer:))))
                imageViewThumbnail.isUserInteractionEnabled = true
                imageViewThumbnail.frame = CGRect(x: thumbnailXOffset, y: 0, width: thumbnailWidth, height: thumbnailHeight)
                imageViewThumbnail.contentMode = .scaleAspectFit
                thumbnailScrollView.addSubview(imageViewThumbnail)
                
                thumbnailXOffset += thumbnailWidth * 1.1
            }
            flipView.layoutSubviews()
            thumbnailScrollView.contentSize = CGSize(width: thumbnailXOffset, height: thumbnailHeight)
        }
    }
    
    func updateFrames(to size: CGSize) {
        let imageFrame = CGRect(x: 0, y: 0, width: size.width, height: size.width*1.4)
        let frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        flipView.updateFrame(to: size)
        for scrollView in pageViews {
            scrollView.frame = frame
            scrollView.zoomScale = 1.05
            scrollView.contentSize = imageFrame.size
            let imageView = scrollView.subviews[0] as! UIImageView
            imageView.frame = imageFrame
            //scrollView.layoutSubviews()
        }
        flipView.layoutSubviews()
    }
    
    func thumbnailTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        let thumbnail = tapGestureRecognizer.view as! UIImageView
        let page = thumbnail.tag
        self.flipView.moveToPage(page-1)
    }
    
    func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage? {
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
            image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
    
    //MARK: - Thumbnails Animations
    
    func hideThumbnails() {
        //print("hideThumbnails")
        UIView.animate(withDuration: 1.0, animations: {
            let superFrame = self.view.frame
            let selfFrame = self.thumbnailScrollView.frame
            self.thumbnailScrollView.frame = CGRect(x: selfFrame.origin.x, y: superFrame.size.height, width: selfFrame.width, height: selfFrame.height)
        }, completion: {(Bool) -> Void in
            self.thumbnailsVisible = false;
            //print("hideThumbnails Complete")
        })
    }
    
    func showThumbnails() {
        if thumbnailsVisible {
            return
        }
        //print("showThumbnails")
        thumbnailsVisible = true;
        UIView.animate(withDuration: 0.5, animations: {
            let superFrame = self.view.frame
            let selfFrame = self.thumbnailScrollView.frame
            self.thumbnailScrollView.frame = CGRect(x: selfFrame.origin.x, y: superFrame.size.height - selfFrame.size.height, width: selfFrame.width, height: selfFrame.height)
        })
        resetThumbnailsTimer()
    }
    
    func resetThumbnailsTimer() {
        //print("resetTimer")
        thumbnailsTimer?.invalidate()
        thumbnailsTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true, block: {_ in
            self.hideThumbnails()
        })
    }
    
    //MARK: - FlipperDataSource
    
    func numberOfPages(_ flipper: DJKFlipperView) -> NSInteger {
        return pageViews.count
    }
    
    func viewForPage(_ page: NSInteger, flipper: DJKFlipperView) -> UIView {
        pageViews[page].zoomScale = 1.01
        pageViews[page].scrollRectToVisible(CGRect(x: 1, y: 0, width: 1, height: 1), animated: false)
        return pageViews[page]
    }
    
    func pageTouched() {
        showThumbnails()
    }
    
    func flippedToPage(_ page: NSInteger) {
        let thumbnailWidth = thumbnailScrollView.subviews[0].frame.size.width
        let thumbnailXOffset:CGFloat = thumbnailWidth * 1.1 * CGFloat(page) - self.view.frame.size.width * 0.5;
        thumbnailScrollView.scrollRectToVisible(CGRect(x: thumbnailXOffset, y: 0, width: self.view.frame.size.width, height: 1), animated: true)
    }
    
    //MARK: - ScrollViewDelegate
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return scrollView.subviews[0]
    }
    
}

