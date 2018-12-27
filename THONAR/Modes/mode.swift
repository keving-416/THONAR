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
    var videoPlayers = [String?:AVPlayer]()
    
    // Override in subclasses
    func renderer(nodeFor anchor: ARAnchor) -> SCNNode? { return nil }
    
    //Override in subclasses
    func renderer(updateAtTime time:TimeInterval, forView sceneView: ARSCNView) {}
    
    func viewWillAppear(forView view: ARSCNView) {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tapGestureRecognizer)
        
        view.session.run(self.configuration)
    }
    
    func updateView(view: UIView) {
        viewWillAppear(forView: view as! ARSCNView)
        removeAllSubviews(forView: view)
    }
    
    
    func removeAllSubviews(forView view: UIView) {
        for view in view.subviews {
            print("view: \(view.description)")
            view.removeFromSuperview()
        }
    }
    
    // Override in subclasses
    @objc func handleTap(sender: UITapGestureRecognizer) {}
        
    public init() { self.configuration = ARWorldTrackingConfiguration() }
    
    // Creates a node that displays a video when a certain image is detected
    func createVideoPlayerPlaneNode(forResourceDictionary resourceNames: [String:(String,String)], forImageAnchor imageAnchor: ARImageAnchor, fromImageName name: String?) -> SCNNode {
        let videoPlayer : AVPlayer = {
            //Load video from bundle
            guard let url = getURL(forResourceDictionary: resourceNames, forImageName: name!) else {
                
                print("Could not find video file.")
                
                return AVPlayer()
            }
            
            return AVPlayer(url: url)
        }()
        videoPlayers[name!] = videoPlayer
        let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
        plane.firstMaterial?.diffuse.contents = videoPlayer
        videoPlayer.play()
        
        let planeNode = SCNNode(geometry: plane)
        planeNode.eulerAngles.x = -.pi / 2
        return planeNode
    }
    
    func getURL(forResourceDictionary resourceNames: [String: (String,String)], forImageName imageName: String) -> URL? {
        // if imageName exists in the videoPlayer dictionary
        if let resourceName = resourceNames[imageName] {
            return Bundle.main.url(forResource: resourceName.0, withExtension: resourceName.1)
        } else {
            print("Could not find image named \(imageName) in resourceNames")
            return nil
        }
    }
}
