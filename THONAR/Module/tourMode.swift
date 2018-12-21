//
//  tourMode.swift
//  THONAR
//
//  Created by Kevin Gardner on 12/15/18.
//  Copyright © 2018 THON. All rights reserved.
//

import Foundation
import ARKit

/// The mode that handles the functionality of the augmented reality tour during THON weekend
class TourMode: Mode {
    var videoPlayers = [String?:AVPlayer]()
    
    let resourceNames = [
        "FootballPepRally":("Football Pep Rally","mp4"),
        "THON2019Logo":("THON2019LogoARVideo","mp4"),
        "HumansUnited":("HumansUnitedARVideo","mov"),
        "LineDance":("Line Dance","mov"),
        "LineDanceFull":("Line Dance Full","MP4")
    ]
    
    override func renderer(nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
        
        
        
        if let imageAnchor = anchor as? ARImageAnchor {
            let referenceImageName = imageAnchor.referenceImage.name
            node.name = referenceImageName
            let videoPlayer : AVPlayer = {
                // Load video from bundle
                guard let url = getURL(imageName: referenceImageName!) else {
                    
                    print("Could not find video file.")
                    
                    return AVPlayer()
                }
                
                return AVPlayer(url: url)
            }()
            videoPlayers[referenceImageName] = videoPlayer
            let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
            plane.firstMaterial?.diffuse.contents = videoPlayer
            videoPlayer.play()
            
            let planeNode = SCNNode(geometry: plane)
            planeNode.eulerAngles.x = -.pi / 2
            node.addChildNode(planeNode)
        }
        
        return node
    }
    
    override func viewWillAppear(forView view: ARSCNView) {
        // Define a variable to hold all your reference images
        let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: Bundle.main)
        self.configuration.detectionImages = referenceImages!
        self.configuration.maximumNumberOfTrackedImages = 3
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tapGestureRecognizer)
        
        // Run the view's session
        view.session.run(self.configuration)
    }
    
    func getURL(imageName: String) -> URL? {
        // if imageName exists in the videoPlayer dictionary
        if let resourceName = resourceNames[imageName] {
            return Bundle.main.url(forResource: resourceName.0, withExtension: resourceName.1)
        } else {
            print("Could not find image named \(imageName) in resourceNames")
            return nil
        }
    }
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        let tappedView = sender.view as! SCNView
        let touchLocation = sender.location(in: tappedView)
        let hitTest = tappedView.hitTest(touchLocation, options: nil)
        if !hitTest.isEmpty {
            let result = hitTest.first!
            updateVideoPlayer(result: result)
        }
    }
    
    @objc func updateVideoPlayer(result: SCNHitTestResult) {
        // The nodes of the images are the parent of the SCNHitTestResult node
        let name = result.node.parent?.name
        if let videoPlayer = videoPlayers[name] {
            if videoPlayer.isPlaying {
                videoPlayer.pause()
            } else {
                videoPlayer.play()
            }
        }
    }
    
    public override init() {
        super.init()
    }
    
}

extension AVPlayer {
    var isPlaying: Bool {
        return (self.rate != 0 && self.error == nil)
    }
}
