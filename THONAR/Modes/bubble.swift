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
                        let material = SCNMaterial()
                        material.diffuse.contents =  #imageLiteral(resourceName: "transparent-bubble")
                        material.isDoubleSided = true
                        material.writesToDepthBuffer = false
                        material.blendMode = .screen
                        bubble.materials = [material]
                        self.geometry = bubble
                }
            required init?(coder aDecoder: NSCoder) {
                        fatalError("init(coder:) has not been implemented")
                }
            
            
}
