//
//  FlipperReDo.swift
//  DJKSwiftFlipper
//
//  Created by Koza, Daniel on 7/13/15.
//  Copyright (c) 2015 Daniel Koza. All rights reserved.
//

import UIKit

public enum FlipperState {
    case began
    case active
    case inactive
}

public protocol DJKFlipperDataSource {
    func numberOfPages(_ flipper:DJKFlipperView) -> NSInteger
    func viewForPage(_ page:NSInteger, flipper:DJKFlipperView) -> UIView
    func pageTouched()
    func flippedToPage(_ page:NSInteger)
}

open class DJKFlipperView: UIView, UIGestureRecognizerDelegate {
    
    //MARK: - Property Declarations
    
    var viewControllerSnapShots:[UIImage?] = []
    open var dataSource:DJKFlipperDataSource? {
        didSet {
            reload()
        }
    }
    
    lazy var staticView:DJKStaticView = {
        let view = DJKStaticView(frame: self.frame)
        return view
        }()
    
    var flipperState = FlipperState.inactive
    var activeView:UIView?
    var currentPage = 0
    var animatingLayers:[DJKAnimationLayer] = []
    
    //MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initHelper()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initHelper()
    }
    
    func initHelper() {
        NotificationCenter.default.addObserver(self, selector: #selector(DJKFlipperView.deviceOrientationDidChangeNotification), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(DJKFlipperView.clearAnimations), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tap))
        self.addGestureRecognizer(tapGesture)
        
        let leftEdgeGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(self.pan(gesture:)))
        leftEdgeGesture.edges = UIRectEdge.left
        leftEdgeGesture.delegate = self
        self.addGestureRecognizer(leftEdgeGesture)
        
        let rightEdgeGesture = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(self.pan(gesture:)))
        rightEdgeGesture.edges = UIRectEdge.right
        rightEdgeGesture.delegate = self
        self.addGestureRecognizer(rightEdgeGesture)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIApplicationWillResignActive, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }
    
    func updateFrame(to size: CGSize) {
        let frame = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        self.frame = frame
        self.staticView.updateFrame(frame)
    }
    
    func moveToPage(_ page: Int) {
        self.currentPage = page
        updateTheActiveView()
    }
    
    func updateTheActiveView() {
        
        if let dataSource = self.dataSource {
            if dataSource.numberOfPages(self) > 0 {
                
                if let activeView = self.activeView {
                    if activeView.isDescendant(of: self) {
                        activeView.removeFromSuperview()
                    }
                }
                
                self.activeView = dataSource.viewForPage(self.currentPage, flipper: self)
                self.addSubview(self.activeView!)
                
                //set up the constraints
//                self.activeView!.translatesAutoresizingMaskIntoConstraints = false
//                let viewDictionary = ["activeView":self.activeView!]
//                let constraintTop = NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[activeView]-0-|", options: NSLayoutFormatOptions.alignAllTop, metrics: nil, views: viewDictionary)
//                let constraintLeft = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[activeView]-0-|", options: NSLayoutFormatOptions.alignAllLeft, metrics: nil, views: viewDictionary)
//                
//                self.addConstraints(constraintTop)
//                self.addConstraints(constraintLeft)
                
                dataSource.flippedToPage(self.currentPage)
            }
        }
    }
    
    func enableActiveView(_ enable: Bool) {
        if let activeView : UIScrollView = self.activeView! as? UIScrollView {
            activeView.isScrollEnabled = enable
        }
    }
    
    //MARK: - Gesture Recognizer Delegate
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    //MARK: - Tap Gesture
    
    func tap() {
        dataSource?.pageTouched()
    }
    
    //MARK: - Pan Gesture States
    
    func pan(gesture:UIPanGestureRecognizer) {
        let translation = gesture.translation(in: gesture.view!).x
        let progress = translation / gesture.view!.bounds.size.width
        
        switch (gesture.state) {
        case .began:
            enableActiveView(false)
            panBegan(gesture: gesture)
        case .changed:
            panChanged(gesture: gesture, translation: translation, progress: progress)
        case .ended:
            panEnded(gesture: gesture, translation: translation)
            enableActiveView(true)
        case .cancelled:
            enableGesture(gesture: gesture, enable: true)
            enableActiveView(true)
        case .failed:
            print("Failed")
        case .possible:
            print("Possible")
        }
    }
    
    //MARK: Pan Gesture State Began
    
    func panBegan(gesture:UIPanGestureRecognizer) {
        if checkIfAnimationsArePassedHalfway() != true {
            enableGesture(gesture: gesture, enable: false)
        } else {
            if flipperState == .inactive {
                flipperState = .began
            }
            
            let animationLayer = DJKAnimationLayer(frame: self.staticView.rightSide.bounds, isFirstOrLast:false)
            
            //if an animation has a lower zPosition then it will not be visible throughout the entire animation cycle
            if let hiZAnimLayer = getHighestZIndexDJKAnimationLayer() {
                animationLayer.zPosition = hiZAnimLayer.zPosition + animationLayer.bounds.size.height
            } else {
                animationLayer.zPosition = 0
            }
            
            animatingLayers.append(animationLayer)
        }
    }
    
    //MARK: Pan Began Helpers
    
    func checkIfAnimationsArePassedHalfway() -> Bool{
        var passedHalfWay = false
        
        if flipperState == .inactive {
            passedHalfWay = true
        } else if animatingLayers.count > 0 {
            //LOOP through this and check the new animation layer with current animations to make sure we dont allow the same animation to happen on a flip up
            for animLayer in animatingLayers {
                let animationLayer = animLayer as DJKAnimationLayer
                var layerIsPassedHalfway = false
                
                let rotationX = animationLayer.presentation()?.value(forKeyPath: "transform.rotation.x") as! CGFloat
                
                if animationLayer.flipDirection == .right && rotationX > 0 {
                    layerIsPassedHalfway = true
                } else if animationLayer.flipDirection == .left && rotationX == 0 {
                    layerIsPassedHalfway = true
                }
                
                if layerIsPassedHalfway == false {
                    passedHalfWay = false
                    break
                } else {
                    passedHalfWay = true
                }
            }
        } else {
            passedHalfWay = true
        }
        
        return passedHalfWay
    }
    
    //MARK:Pan Gesture State Changed
    
    func panChanged(gesture:UIPanGestureRecognizer, translation:CGFloat, progress:CGFloat) {
        
        let progress = progress
        if let currentDJKAnimationLayer = animatingLayers.last {
            if currentDJKAnimationLayer.flipAnimationStatus == .beginning {
                animationStatusBeginning(currentDJKAnimationLayer: currentDJKAnimationLayer, translation: translation, progress: progress, gesture: gesture)
            } else if currentDJKAnimationLayer.flipAnimationStatus == .active {
                animationStatusActive(currentDJKAnimationLayer: currentDJKAnimationLayer, translation: translation, progress: progress)
            } else if currentDJKAnimationLayer.flipAnimationStatus == .completing {
                enableGesture(gesture: gesture, enable: false)
                animationStatusCompleting(animationLayer: currentDJKAnimationLayer)
            }
        }
    }
    
    //MARK: Pan Gesture State Ended
    
    func panEnded(gesture:UIPanGestureRecognizer, translation:CGFloat) {
        
        if let currentDJKAnimationLayer = animatingLayers.last {
            currentDJKAnimationLayer.flipAnimationStatus = .completing
            
            if didFlipToNewPage(animationLayer: currentDJKAnimationLayer, gesture: gesture, translation: translation) == true {
                setUpForFlip(animationLayer: currentDJKAnimationLayer, progress: 1.0, animated: true, clearFlip: true)
            } else {
                if currentDJKAnimationLayer.isFirstOrLastPage == false {
                    handleDidNotFlipToNewPage(animationLayer: currentDJKAnimationLayer)
                }
                setUpForFlip(animationLayer: currentDJKAnimationLayer, progress: 0.0, animated: true, clearFlip: true)
            }
        }
    }
    
    //MARK: Pan Ended Helpers
    
    func didFlipToNewPage(animationLayer:DJKAnimationLayer, gesture:UIPanGestureRecognizer, translation:CGFloat) -> Bool {
        
        let releaseSpeed = getReleaseSpeed(translation: translation, gesture: gesture)
        
        var didFlipToNewPage = false
        if animationLayer.flipDirection == .left && fabs(releaseSpeed) > DJKFlipperConstants.SpeedThreshold && !animationLayer.isFirstOrLastPage && releaseSpeed < 0 ||
            animationLayer.flipDirection == .right && fabs(releaseSpeed) > DJKFlipperConstants.SpeedThreshold && !animationLayer.isFirstOrLastPage && releaseSpeed > 0 {
                didFlipToNewPage = true
        }
        return didFlipToNewPage
    }
    
    func getReleaseSpeed(translation:CGFloat, gesture:UIPanGestureRecognizer) -> CGFloat {
        return (translation + gesture.velocity(in: self).x/4) / self.bounds.size.width
    }
    
    func handleDidNotFlipToNewPage(animationLayer:DJKAnimationLayer) {
        if animationLayer.flipDirection == .left {
            animationLayer.flipDirection = .right
            self.currentPage = self.currentPage - 1
        } else {
            animationLayer.flipDirection = .left
            self.currentPage = self.currentPage + 1
        }
    }
    
    //MARK: - DJKAnimationLayer States
    
    //MARK: DJKAnimationLayer State Began
    
    func animationStatusBeginning(currentDJKAnimationLayer:DJKAnimationLayer, translation:CGFloat, progress:CGFloat, gesture:UIPanGestureRecognizer) {
        if currentDJKAnimationLayer.flipAnimationStatus == .beginning {
            
            flipperState = .active
            
            //set currentDJKAnimationLayers direction
            currentDJKAnimationLayer.updateFlipDirection(getFlipDirection(translation: translation))
            
            if handleConflictingAnimationsWithDJKAnimationLayer(animationLayer: currentDJKAnimationLayer) == false {
                //check if swipe is fast enough to be considered a complete page swipe
                if isIncrementalSwipe(gesture: gesture, animationLayer: currentDJKAnimationLayer) {
                    currentDJKAnimationLayer.flipAnimationStatus = .active
                } else {
                    currentDJKAnimationLayer.flipAnimationStatus = .completing
                }
                
                updateViewControllerSnapShotsWithCurrentPage(currentPage: self.currentPage)
                setUpDJKAnimationLayerFrontAndBack(animationLayer: currentDJKAnimationLayer)
                setUpStaticLayerForTheDJKAnimationLayer(animationLayer: currentDJKAnimationLayer)
                
                self.layer.addSublayer(currentDJKAnimationLayer)
                //you need to perform a flush otherwise the animation duration is not honored.
                //more information can be found here http://stackoverflow.com/questions/8661355/implicit-animation-fade-in-is-not-working#comment10764056_8661741
                CATransaction.flush()
                
                //add the animation layer to the view
                addDJKAnimationLayer()
                
                if currentDJKAnimationLayer.flipAnimationStatus == .active {
                    animationStatusActive(currentDJKAnimationLayer: currentDJKAnimationLayer, translation: translation, progress: progress)
                }
            } else {
                enableGesture(gesture: gesture, enable: false)
            }
        }
    }
    
    //MARK: DJKAnimationLayer State Begin Helpers
    
    func getFlipDirection(translation:CGFloat) -> FlipDirection {
        if translation > 0 {
            return .right
        } else {
            return .left
        }
    }
    
    func isIncrementalSwipe(gesture:UIPanGestureRecognizer, animationLayer:DJKAnimationLayer) -> Bool {
        
        var incrementalSwipe = false
        if fabs(gesture.velocity(in: self).x) < 500 || animationLayer.isFirstOrLastPage == true {
            incrementalSwipe = true
        }
        
        return incrementalSwipe
    }
    
    func updateViewControllerSnapShotsWithCurrentPage(currentPage:Int) {
        if let numberOfPages = dataSource?.numberOfPages(self) {
            if  currentPage <= numberOfPages - 1 {
                //set the current page snapshot
                viewControllerSnapShots[currentPage] = dataSource?.viewForPage(currentPage, flipper: self).takeSnapshot()
                
                if currentPage + 1 <= numberOfPages - 1  {
                    //set the right page snapshot, if there already is a screen shot then dont update it
                    //if viewControllerSnapShots[currentPage + 1] == nil {
                        viewControllerSnapShots[currentPage + 1] = dataSource?.viewForPage(currentPage + 1, flipper: self).takeSnapshot()
                    //}
                }
                
                if currentPage - 1 >= 0 {
                    //set the left page snapshot, if there already is a screen shot then dont update it
                    //if viewControllerSnapShots[currentPage - 1] == nil {
                        viewControllerSnapShots[currentPage - 1] = dataSource?.viewForPage(currentPage - 1, flipper: self).takeSnapshot()
                    //}
                }
            }
        }
    }
    
    func setUpDJKAnimationLayerFrontAndBack(animationLayer:DJKAnimationLayer) {
        if animationLayer.flipDirection == .left {
            if self.currentPage + 1 > dataSource!.numberOfPages(self) - 1 {
                //we are at the end
                animationLayer.flipProperties.endFlipAngle = -1.5
                animationLayer.isFirstOrLastPage = true
                animationLayer.setTheFrontLayer(self.viewControllerSnapShots[currentPage]!)
            } else {
                //next page flip
                animationLayer.setTheFrontLayer(self.viewControllerSnapShots[currentPage]!)
                currentPage = currentPage + 1
                animationLayer.setTheBackLayer(self.viewControllerSnapShots[currentPage]!)
            }
        } else {
            if currentPage - 1 < 0 {
                //we are at the end
                animationLayer.flipProperties.endFlipAngle = CGFloat(-M_PI) + 1.5
                animationLayer.isFirstOrLastPage = true
                animationLayer.setTheBackLayer(viewControllerSnapShots[currentPage]!)
                
            } else {
                //previous page flip
                animationLayer.setTheBackLayer(self.viewControllerSnapShots[currentPage]!)
                currentPage = currentPage - 1
                animationLayer.setTheFrontLayer(self.viewControllerSnapShots[currentPage]!)
            }
        }
    }
    
    func setUpStaticLayerForTheDJKAnimationLayer(animationLayer:DJKAnimationLayer) {
        if animationLayer.flipDirection == .left {
            if animationLayer.isFirstOrLastPage == true && animatingLayers.count <= 1 {
                staticView.setTheLeftSide(self.viewControllerSnapShots[currentPage]!)
            } else {
                staticView.setTheLeftSide(self.viewControllerSnapShots[currentPage - 1]!)
                staticView.setTheRightSide(self.viewControllerSnapShots[currentPage]!)
            }
        } else {
            if animationLayer.isFirstOrLastPage == true && animatingLayers.count <= 1 {
                staticView.setTheRightSide(self.viewControllerSnapShots[currentPage]!)
            } else {
                staticView.setTheRightSide(self.viewControllerSnapShots[currentPage + 1]!)
                staticView.setTheLeftSide(self.viewControllerSnapShots[currentPage]!)
            }
        }
    }
    
    func addDJKAnimationLayer() {
        self.layer.addSublayer(staticView)
        CATransaction.flush()
        
        if let activeView = self.activeView {
            activeView.removeFromSuperview()
        }
    }
    
    //MARK: DJKAnimationLayer State Active
    
    func animationStatusActive(currentDJKAnimationLayer:DJKAnimationLayer, translation:CGFloat, progress:CGFloat) {
        performIncrementalAnimationToLayer(animationLayer: currentDJKAnimationLayer, translation: translation, progress: progress)
    }
    
    //MARK: DJKAnimationLayer State Active Helpers
    
    func performIncrementalAnimationToLayer(animationLayer:DJKAnimationLayer, translation:CGFloat, progress:CGFloat) {
        
        var progress = progress
        if translation > 0 {
            progress = max(progress, 0)
        } else {
            progress = min(progress, 0)
        }
        
        progress = fabs(progress)
        setUpForFlip(animationLayer: animationLayer, progress: progress, animated: false, clearFlip: false)
    }
    
    //MARK DJKAnimationLayer State Complete
    
    func animationStatusCompleting(animationLayer:DJKAnimationLayer) {
        performCompleteAnimationToLayer(animationLayer: animationLayer)
    }
    
    //MARK: Animation State Complete Helpers
    
    func performCompleteAnimationToLayer(animationLayer:DJKAnimationLayer) {
        setUpForFlip(animationLayer: animationLayer, progress: 1.0, animated: true, clearFlip: true)
    }
    
    //MARK: - Animation Conflict Detection
    
    func handleConflictingAnimationsWithDJKAnimationLayer(animationLayer:DJKAnimationLayer) -> Bool {
        
        //check if there is an animation layer before that is still animating at the opposite swipe direction
        var animationConflict = false
        if animatingLayers.count > 1 {
            
            if let oppositeDJKAnimationLayer = getHighestDJKAnimationLayerFromDirection(flipDirection: getOppositeAnimationDirectionFromLayer(animationLayer: animationLayer)) {
                if oppositeDJKAnimationLayer.isFirstOrLastPage == false {
                    
                    animationConflict = true
                    //we now need to remove the newly added layer
                    removeDJKAnimationLayer(animationLayer: animationLayer)
                    reverseAnimationForLayer(animationLayer: oppositeDJKAnimationLayer)
                    
                }
            }
        }
        return animationConflict
    }
    
    func getHighestDJKAnimationLayerFromDirection(flipDirection:FlipDirection) -> DJKAnimationLayer? {
        
        var animationsInSameDirection:[DJKAnimationLayer] = []
        
        for animLayer in animatingLayers {
            if animLayer.flipDirection == flipDirection {
                animationsInSameDirection.append(animLayer)
            }
        }
        
        if animationsInSameDirection.count > 0 {
            _ = animationsInSameDirection.sorted(by: {$0.zPosition > $1.zPosition})
            return animationsInSameDirection.first
        }
        return nil
    }
    
    func getOppositeAnimationDirectionFromLayer(animationLayer:DJKAnimationLayer) -> FlipDirection {
        var animationLayerOppositeDirection = FlipDirection.left
        if animationLayer.flipDirection == .left {
            animationLayerOppositeDirection = .right
        }
        
        return animationLayerOppositeDirection
    }
    
    func removeDJKAnimationLayer(animationLayer:DJKAnimationLayer) {
        animationLayer.flipAnimationStatus = .fail
        
        var zPos = animationLayer.bounds.size.height
        
        if let highestZPosAnimLayer = getHighestZIndexDJKAnimationLayer() {
            zPos = zPos + highestZPosAnimLayer.zPosition
        } else {
            zPos = 0
        }
        
        _ = animatingLayers.removeObject(animationLayer)
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(0)
        animationLayer.zPosition = zPos
        CATransaction.commit()
    }
    
    func reverseAnimationForLayer(animationLayer:DJKAnimationLayer) {
        animationLayer.flipAnimationStatus = .interrupt
        
        if animationLayer.flipDirection == .left {
            currentPage = currentPage - 1
            animationLayer.updateFlipDirection(.right)
            setUpForFlip(animationLayer: animationLayer, progress: 1.0, animated: true, clearFlip: true)
        } else if animationLayer.flipDirection == .right {
            currentPage = currentPage + 1
            animationLayer.updateFlipDirection(.left)
            setUpForFlip(animationLayer: animationLayer, progress: 1.0, animated: true, clearFlip: true)
        }
    }
    
    //MARK: - Flip Animation Methods
    
    func setUpForFlip(animationLayer:DJKAnimationLayer, progress:CGFloat, animated:Bool, clearFlip:Bool) {
        
        let newAngle:CGFloat = animationLayer.flipProperties.startAngle + progress * (animationLayer.flipProperties.endFlipAngle - animationLayer.flipProperties.startAngle)
        
        var duration:CGFloat
        
        if animated == true {
            duration = getAnimationDurationFromDJKAnimationLayer(animationLayer: animationLayer, newAngle: newAngle)
        } else {
            duration = 0
        }
        
        animationLayer.flipProperties.currentAngle = newAngle
        
        if animationLayer.isFirstOrLastPage == true {
            setMaxAngleIfDJKAnimationLayerIsFirstOrLast(animationLayer: animationLayer, newAngle: newAngle)
        }
        
        performFlipWithDJKAnimationLayer(animationLayer: animationLayer, duration: duration, clearFlip: clearFlip)
    }
    
    func performFlipWithDJKAnimationLayer(animationLayer:DJKAnimationLayer, duration:CGFloat, clearFlip:Bool) {
        var t = CATransform3DIdentity
        t.m34 = 1.0/850
        t = CATransform3DRotate(t, animationLayer.flipProperties.currentAngle, 0, 1, 0)
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(CFTimeInterval(duration))
        
        //if the flip animationLayer should be cleared after its animation is completed
        if clearFlip {
            clearFlipAfterCompletion(animationLayer: animationLayer)
        }
        
        animationLayer.transform = t
        CATransaction.commit()
    }
    
    func clearFlipAfterCompletion(animationLayer:DJKAnimationLayer) {
        weak var weakSelf = self
        CATransaction.setCompletionBlock({
            DispatchQueue.main.async {
                if animationLayer.flipAnimationStatus == .interrupt {
                    animationLayer.flipAnimationStatus = .completing
                    
                } else if animationLayer.flipAnimationStatus == .completing {
                    animationLayer.flipAnimationStatus = .none
                    
                    if animationLayer.isFirstOrLastPage == false {
                        CATransaction.begin()
                        CATransaction.setAnimationDuration(0)
                        if animationLayer.flipDirection == .left {
                            weakSelf?.staticView.leftSide.contents = animationLayer.backLayer.contents
                        } else {
                            weakSelf?.staticView.rightSide.contents = animationLayer.frontLayer.contents
                        }
                        CATransaction.commit()
                    }
                    
                    _ = weakSelf?.animatingLayers.removeObject(animationLayer)
                    animationLayer.removeFromSuperlayer()
                    
                    if weakSelf?.animatingLayers.count == 0 {
                        
                        weakSelf?.flipperState = .inactive
                        weakSelf?.updateTheActiveView()
                        weakSelf?.staticView.removeFromSuperlayer()
                        CATransaction.flush()
                        weakSelf?.staticView.leftSide.contents = nil
                        weakSelf?.staticView.rightSide.contents = nil
                    } else {
                        CATransaction.flush()
                    }
                }
            }
            
        })
    }
    
    //MARK: Flip Animation Helper Methods
    
    func getAnimationDurationFromDJKAnimationLayer(animationLayer:DJKAnimationLayer, newAngle:CGFloat) -> CGFloat {
        var durationConstant = DJKFlipperConstants.DurationConstant
        
        if animationLayer.isFirstOrLastPage == true {
            durationConstant = 0.5
        }
        return durationConstant * fabs((newAngle - animationLayer.flipProperties.currentAngle) / (animationLayer.flipProperties.endFlipAngle - animationLayer.flipProperties.startAngle))
    }
    
    func setMaxAngleIfDJKAnimationLayerIsFirstOrLast(animationLayer:DJKAnimationLayer, newAngle:CGFloat) {
        if animationLayer.flipDirection == .right {
            if newAngle < -1.4 {
                animationLayer.flipProperties.currentAngle = -1.4
            }
        } else {
            if newAngle > -1.8 {
                animationLayer.flipProperties.currentAngle = -1.8
            }
        }
    }
    
    //MARK: - Helper Methods
    
    func enableGesture(gesture:UIPanGestureRecognizer, enable:Bool) {
        gesture.isEnabled = enable
    }
    
    func getHighestZIndexDJKAnimationLayer() -> DJKAnimationLayer? {
        
        if animatingLayers.count > 0 {
            let copyOfAnimatingLayers = animatingLayers
            _ = copyOfAnimatingLayers.sorted(by: {$0.zPosition > $1.zPosition})
            
            let highestDJKAnimationLayer = copyOfAnimatingLayers.first
            return highestDJKAnimationLayer
        }
        return nil
    }
    
    func clearAnimations() {
        if flipperState != .inactive {
            //remove all animation layers and update the static view
            updateTheActiveView()
            
            for animation in animatingLayers {
                animation.flipAnimationStatus = .fail
                animation.removeFromSuperlayer()
            }
            animatingLayers.removeAll(keepingCapacity: false)
            
            self.staticView.removeFromSuperlayer()
            CATransaction.flush()
            self.staticView.leftSide.contents = nil
            self.staticView.rightSide.contents = nil
            
            flipperState = .inactive
        }
    }
    
    func deviceOrientationDidChangeNotification() {
        clearAnimations()
    }
    
    //MARK: - Public Methods
    
    public func reload() {
        updateTheActiveView()
        //set an array with capacity for total amount of possible pages
        viewControllerSnapShots.removeAll(keepingCapacity: false)
        for _ in 1...dataSource!.numberOfPages(self) {
            viewControllerSnapShots.append(nil)
        }
    }
}
