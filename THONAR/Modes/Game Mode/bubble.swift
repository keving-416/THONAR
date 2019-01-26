//
//  bubble.swift
//  THONAR
//
//  Created by Ruchi on 12/26/18.
//  Copyright © 2018 THON. All rights reserved.
//

import Foundation
import UIKit
import SceneKit
import ARKit
import CoreAudio
import AVFoundation


class Bubble: SCNNode {
    
    override init() {
        super.init()
        setGeometry()
    }
    
    init(forFrame frame: ARFrame, forImageView imageView: UIImageView) {
        super.init()
        setGeometry()
        newBubble(forFrame: frame, forImageView: imageView)
    }
    
    private func setGeometry() {
        let bubble = SCNPlane(width: 0.25, height: 0.25)
        let bubbleMaterial = SCNMaterial()
        bubbleMaterial.diffuse.contents = #imageLiteral(resourceName: "transparent-bubble")
        
        let redValue = CGFloat.random(in: 0...1)
        let greenValue = CGFloat.random(in: 0...1)
        let blueValue = CGFloat.random(in: 0...1)
        bubbleMaterial.multiply.contents = UIColor(red: redValue, green: greenValue, blue: blueValue, alpha: 1)
        
        bubbleMaterial.isDoubleSided = true
        bubbleMaterial.writesToDepthBuffer = false
        bubbleMaterial.blendMode = .screen
        bubble.materials = [bubbleMaterial]
        self.geometry = bubble
    }
    
    private func newBubble(forFrame frame: ARFrame, forImageView imageView: UIImageView) {
        let mat = SCNMatrix4(frame.camera.transform)
        let dir = SCNVector3(-1 * mat.m31, -1 * mat.m32, -1 * mat.m33)
        
        let position = getPosition(forFrame: frame)
        self.position = position
        self.scale = SCNVector3(1,1,1) * floatBetween(0.6, and: 1)
        
        
        let firstAction = SCNAction.move(by: dir.normalized() * 0.5 + SCNVector3(0,0.15,0), duration: 0.5)
        firstAction.timingMode = .easeOut
        let secondAction = SCNAction.move(by: dir + SCNVector3(floatBetween(-1.5, and:1.5 ),floatBetween(0, and: 1.5),0), duration: TimeInterval(floatBetween(5, and: 12)))
        secondAction.timingMode = .easeOut
        self.runAction(firstAction)
        self.runAction(secondAction, completionHandler: {
            self.runAction(SCNAction.fadeOut(duration: 0), completionHandler: {
                DispatchQueue.main.async {}
                self.removeFromParentNode()
            })
        })
    }
    
    private func getPosition(forFrame frame: ARFrame) -> (SCNVector3) {
        let mat = SCNMatrix4(frame.camera.transform)
        let dir = SCNVector3(-1 * mat.m31, -1 * mat.m32, -1 * mat.m33)
        let pos = SCNVector3(mat.m41, mat.m42, mat.m43)
        return pos + SCNVector3(0,-0.07,0) + dir.normalized() * 0.5
        //return SCNVector3(0, 0, -1)
    }
    
    private func floatBetween(_ first: Float, and second: Float) -> Float {
        // random float between upper and lower bound (inclusive)
        return (Float(arc4random()) / Float(UInt32.max)) * (first - second) + second
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
        
    }
    
}

// MARK: - SCNVector3 extension
extension SCNVector3 {
    func length() -> Float {
        return sqrtf(x * x + y * y + z * z)
        
    }
    
    func normalized() -> SCNVector3 {
        if self.length() == 0 {
            return self
            
        }
        return self / self.length()
        
    }
}

func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}

func * (left: SCNVector3, right: Float) -> SCNVector3 {
    return SCNVector3Make(left.x * right, left.y * right, left.z * right)
}

func / (left: SCNVector3, right: Float) -> SCNVector3 {
    return SCNVector3Make(left.x / right, left.y / right, left.z / right)
}

