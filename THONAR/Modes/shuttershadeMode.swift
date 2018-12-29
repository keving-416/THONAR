//
//  shuttershadeMode.swift
//  THONAR
//
//  Created by Kevin Gardner on 12/29/18.
//  Copyright © 2018 THON. All rights reserved.
//

import Foundation
import ARKit

class ShuttershadeMode: Mode {
    override func viewWillAppear(forView view: ARSCNView) {
        super.viewWillAppear(forView: view)
        view.autoenablesDefaultLighting = true
    }
    
    override func renderer(nodeFor anchor: ARAnchor) -> SCNNode? {
        // Can do this when it detects a flat surface or when it detects an image
//        let text = SCNText(string: "THON", extrusionDepth: 2)
//
//        let material = SCNMaterial()
//        material.diffuse.contents = UIColor.blue
//        text.materials = [material]
//
//
        let node = SCNNode()
//        node.position = SCNVector3(x: 0, y: 0.02, z: -0.1)
//        node.scale = SCNVector3(x: 0.01, y: 0.01, z: 0.01)
//        node.geometry = text
//
//        view.scene.rootNode.addChildNode(node)
        return node
    }
    
    public override init() {
        super.init()
    }
}
