//
//  mode.swift
//  THONAR
//
//  Created by Kevin Gardner on 12/15/18.
//  Copyright © 2018 THON. All rights reserved.
//

import Foundation
import ARKit

/// Default mode to be subclassed for specific types of modes
class Mode {
    var configuration: ARWorldTrackingConfiguration
    
    func renderer(nodeFor anchor: ARAnchor) -> SCNNode? {
        return nil
    }
    
    func viewWillAppear(forView view: ARSCNView) {
        view.session.run(self.configuration)
    }
        
    public init() {
        self.configuration = ARWorldTrackingConfiguration()
    }
        
}
