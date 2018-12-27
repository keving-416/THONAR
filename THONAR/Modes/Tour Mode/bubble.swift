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
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
        
    }
    
}
