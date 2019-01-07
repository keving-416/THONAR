//
//  tourMode.swift
//  THONAR
//
//  Created by Kevin Gardner on 12/15/18.
//  Copyright © 2018 THON. All rights reserved.
//

import Foundation
import ARKit
import CloudKit
import AVFoundation



var container: CKContainer = CKContainer.default()
public var publicDatabase: CKDatabase  = container.publicCloudDatabase

/// The mode that handles the functionality of the augmented reality tour during THON weekend
final class TourMode: Mode {
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
            // Do something when an image is detected
            let referenceImageName = imageAnchor.referenceImage.name
            print("referenceImageName: \(referenceImageName)")
            node.name = referenceImageName
            
            let url = (resources![referenceImageName!] as! resource).video
            
            node.addChildNode(createVideoPlayerPlaneNode(forURL: url, forResourceName: referenceImageName!, forImageAnchor: imageAnchor))
        }
        return node
    }
    
    override func updateForNewResources() {
        let referenceImages = getImages()
        self.configuration.detectionImages = referenceImages
        self.configuration.maximumNumberOfTrackedImages = 3

        // Run the view's session
        sceneView.session.run(self.configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    override func viewWillAppear() {
        record = false
        print("!resources.isEmpty: \(resources?.underestimatedCount)")
        let referenceImages = getImages()
        self.configuration.detectionImages = referenceImages
        self.configuration.maximumNumberOfTrackedImages = 3
        
        super.viewWillAppear()
    }
    
    override func handleTap(sender: UITapGestureRecognizer) {
        let tappedView = sender.view as! SCNView
        let touchLocation = sender.location(in: tappedView)
        let hitTest = tappedView.hitTest(touchLocation, options: nil)
        print("hitTest: \(hitTest)")
        if !hitTest.isEmpty {
            let result = hitTest.first!
            updateVideoPlayer(result: result)
        }
    }
    
    @objc func updateVideoPlayer(result: SCNHitTestResult) {
        // The nodes of the images are the parent of the SCNHitTestResult node
        let name = result.node.parent?.name
        print("videoPlayer name: \(name)")
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
    
    public init(forView view: ARSCNView, forResourceGroup resources: NSMutableDictionary) {
        super.init(forView: view)
        self.resources = resources
    }
}

extension AVPlayer {
    var isPlaying: Bool {
        return (self.rate != 0 && self.error == nil)
    }
}
