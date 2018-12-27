//
//  CalibrateView.swift
//  BubbleGame
//
//  Created by Ruchi on 12/21/18.
//  Copyright © 2018 Ruchi. All rights reserved.
//

import Foundation
import UIKit
import CoreMotion
import AVFoundation

enum CalibrateStage {
    case none
    case holdUpright
    case moveLeft
    case moveRight
    case calibrated
}

class calibrateView: UIView{

    var containerView:UIView?
    var phoneImage:UIImageView?
    var dirImage:UIImageView?
    var instructions:UILabel?
    var imageViewsFrame:CGRect?
    var calibrationDone: ((Bool) -> Void)?
    var isHorizontal:Bool = false
    var isTrackingReady:Bool = false
    
    public var stages:CalibrateStage = .none {
        didSet{
            guard oldValue != stages else { return }
            switch stages {
            case .none: ()
            case .holdUpright:
                phoneImage!.image = #imageLiteral(resourceName: "ipad")
                rotateViewVertical(view: self.phoneImage!, angle:50)
                instructions?.text = "CALIBRATION"
                instructions?.text = "Please hold the device straight up!"
                UIView.animate(withDuration: 0.25, delay: 1, options: .curveEaseIn, animations: {
                    self.dirImage?.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                    
                }, completion: { (finished) in
                    if finished {
                        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseIn, animations: {
                            self.dirImage?.transform = .identity
                            
                        })
                        
                    }
                    
                })
                
                let motionManager = CMMotionManager()
                motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
                if motionManager.isDeviceMotionAvailable {
                    motionManager.startDeviceMotionUpdates(using: CMAttitudeReferenceFrame.xArbitraryZVertical, to: OperationQueue.main, withHandler: { (devMotion, error) -> Void in
                        let degree = min(max((motionManager.deviceMotion?.attitude.pitch)! * 180 / Double.pi, 40),90)
                        rotateViewVertical(view: self.phoneImage!, angle: 90-CGFloat(degree))
                        if degree > 70 {
                            print("vertical")
                            motionManager.stopDeviceMotionUpdates()
                            rotateViewVertical(view: self.phoneImage!, angle:0)
                            self.isHorizontal = true
                            if self.isHorizontal && self.isTrackingReady {
                                self.stages = .moveLeft
                                
                            }
                            
                        }
                        
                    })}
            case .moveLeft:
                self.phoneImage?.image = #imageLiteral(resourceName: "ipad")
                self.dirImage?.image = #imageLiteral(resourceName: "left")
                self.phoneImage?.backgroundColor = UIColor(white: 0, alpha: 0)
                self.dirImage?.layer.mask?.contents = (self.phoneImage?.backgroundColor)!
                instructions?.changeTextAnimated(text: "Please rotate the device to the left!")
                let motionManager = CMMotionManager()
                motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
                if motionManager.isDeviceMotionAvailable {
                    motionManager.startDeviceMotionUpdates(using: CMAttitudeReferenceFrame.xArbitraryZVertical, to: OperationQueue.main, withHandler: { (devMotion, error) -> Void in
                        let degree = min(max(-60, (motionManager.deviceMotion?.attitude.yaw)! * 180 / Double.pi),60)
                        rotateViewHorizontal(view: self.phoneImage!, angle: CGFloat(degree))
                        self.phoneImage?.frame = CGRect(origin: CGPoint(x:(self.imageViewsFrame?.origin.x)!+(-1.6)*CGFloat(degree),y:(self.imageViewsFrame?.origin.y)!), size: (self.imageViewsFrame?.size)!)
                        if degree > 45 {
                            self.stages = .moveRight
                            
                        }
                        if degree < -45 && self.stages == .moveRight{
                            motionManager.stopDeviceMotionUpdates()
                            self.stages = .calibrated
                            
                        }
                        
                    })}
            case .moveRight:()
                self.dirImage?.image = #imageLiteral(resourceName: "right")
                instructions?.changeTextAnimated(text: "Now rotate the device to the right!")
            case .calibrated:()
                instructions?.changeTextAnimated(text: "Done!")
                instructions?.changeTextAnimated(text: "Now, blow your screen to blow some bubbles!")
                //instructions?.text = ""
                dirImage?.changeImageAnimated(image: #imageLiteral(resourceName: "done"))
                phoneImage?.image = nil
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapHandle(_:)))
                self.addGestureRecognizer(tapGesture)
                Timer.scheduledTimer(timeInterval: 2, target: self, selector: #selector(removeSelfAnimated), userInfo: nil, repeats: false)
                
            }
            
        }
        
    }
    
    @objc func tapHandle(_ recognizer:UITapGestureRecognizer){
        removeSelfAnimated()
        
    }
    
    @objc func removeSelfAnimated(){
        UIView.setAnimationCurve(.easeIn)
        UIView.animate(withDuration: 0.2, animations: {
            self.alpha = 0
            self.containerView?.transform = CGAffineTransform(scaleX: 0.4, y: 0.8)
            
        }) { (finished) in
            if finished {
                self.removeFromSuperview()
                self.calibrationDone?(true)
                
            }
            
        }
        
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        containerView = UIView(frame: CGRect(x:0,y:self.frame.size.height/4,width:self.frame.size.width,height:self.frame.size.width*0.66))
        self.addSubview(containerView!)
        self.backgroundColor = UIColor(white: 0, alpha: 0.5)
        imageViewsFrame = CGRect(x:0,y:0,width:self.frame.size.width, height:(containerView?.frame.size.height)!*0.66)
        dirImage = UIImageView(frame: imageViewsFrame!)
        phoneImage = UIImageView(frame:imageViewsFrame!)
        phoneImage?.contentMode = .scaleAspectFit
        dirImage?.contentMode = .scaleAspectFit
        
        containerView?.addSubview(dirImage!)
        containerView?.addSubview(phoneImage!)
        
        instructions = UILabel(frame: CGRect(x: self.center.x-self.frame.size.width*0.33, y: (containerView?.frame.size.height)!*0.66+((containerView?.frame.size.height)!*0.33/2), width: self.frame.size.width*0.66, height: (containerView?.frame.size.height)!*0.33/2))
        instructions?.textAlignment = .center
        instructions?.textColor = UIColor(red:1.00, green:0.79, blue:0.08, alpha:1.0)
        instructions?.font = UIFont(name: "Gill-Sans-MT", size: 16)
        instructions?.numberOfLines = 2
        containerView?.addSubview(instructions!)
        
        NotificationCenter.default.addObserver(self, selector: #selector(arTracking(_:)), name: NSNotification.Name(rawValue: "arTrackingReady"), object: nil)
        startAnimation()
        
    }
    
    @objc func arTracking(_ notification:NSNotification){
        isTrackingReady = true
        if isTrackingReady && isHorizontal {
            stages = .moveLeft
            
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
        
    }
    
    func startAnimation(){
        stages = .holdUpright
        
    }
    
}

private func rotateViewHorizontal(view:UIView, angle:CGFloat) {
    let layer = view.layer
    var rotationAndPerspectiveTransform = CATransform3DIdentity
    rotationAndPerspectiveTransform.m34 = 1.0 / -500;
    rotationAndPerspectiveTransform = CATransform3DRotate(rotationAndPerspectiveTransform, angle * CGFloat.pi / 180.0, 0.0, 1.0, 0.0);
    layer.transform = rotationAndPerspectiveTransform;
}

private func rotateViewVertical(view:UIView, angle:CGFloat) {
    let layer = view.layer
    var rotationAndPerspectiveTransform = CATransform3DIdentity
    rotationAndPerspectiveTransform.m34 = 1.0 / -500;
    rotationAndPerspectiveTransform = CATransform3DRotate(rotationAndPerspectiveTransform, angle * CGFloat.pi / 180.0, 1.0, 0.0, 0.0);
    layer.transform = rotationAndPerspectiveTransform;
}

// MARK: - UILabel extension
extension UILabel {
    func changeTextAnimated(text:String){
        UIView.setAnimationCurve(.easeIn)
        UIView.animate(withDuration: 0.2, animations: {
            self.transform = CGAffineTransform(scaleX: 0.4, y: 0.8)
            self.alpha = 0.5
            
        }) { (finished) in
            if finished {
                self.text = text
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .curveEaseIn, animations: {
                    self.alpha = 1
                    self.transform = .identity
                    
                }, completion:nil)
                
            }
            
        }
        
    }
    
}

// MARK: - UIImageView extension
extension UIImageView {
    func changeImageAnimated(image:UIImage){
        UIView.setAnimationCurve(.easeIn)
        UIView.animate(withDuration: 0.2, animations: {
            self.transform = CGAffineTransform(scaleX: 0.4, y: 0.8)
            self.alpha = 0.5
            
        }) { (finished) in
            if finished {
                self.image = image
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .curveEaseIn, animations: {
                    self.alpha = 1
                    self.transform = .identity
                    
                }, completion:nil)
                
            }
            
        }
        
    }
    
}
