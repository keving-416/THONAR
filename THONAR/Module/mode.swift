//
//  mode.swift
//  THONAR
//
//  Created by Kevin Gardner on 12/15/18.
//  Copyright © 2018 THON. All rights reserved.
//

import Foundation
import ARKit

protocol Mode {
    var configuration: ARWorldTrackingConfiguration { get }
    
    func render(nodeFor anchor: ARAnchor) -> SCNNode?
    
    func viewWillAppear(forView view: UIView)
    
}
