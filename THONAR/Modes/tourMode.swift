//
//  tourMode.swift
//  THONAR
//
//  Created by Kevin Gardner on 12/15/18.
//  Copyright © 2018 THON. All rights reserved.
//

import Foundation
import ARKit
import AVFoundation

/// The mode that handles the functionality of the augmented reality tour during THON weekend
final class TourMode: Mode {
    override func renderer(nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
        
        if let imageAnchor = anchor as? ARImageAnchor {
            // Do something when an image is detected
            
            pauseAllOtherVideos()
            
            let referenceImageName = imageAnchor.referenceImage.name
            print("detected \(String(describing: referenceImageName))")
            node.name = referenceImageName
            
            // Find resource in resources array for the image that was detected
            for resource in resources! {
                if coreDataHandler.getStringData(forNSManagedObject: resource, forKey: "name") == referenceImageName {
                    node.addChildNode(createVideoPlayerPlaneNode(forData: coreDataHandler.getData(forNSManagedObject: resource, forKey: "video")!, forResourceName: referenceImageName!, forImageAnchor: imageAnchor))
                    break
                }
            }
            // Add node for anchor and anchor to videoNodes dictionary
            videoNodes[referenceImageName] = (node, imageAnchor)
        }
        return node
    }
    
    func pauseAllOtherVideos() {
        for node in videoNodes {
            if !node.value.0.childNodes.isEmpty {
                let player = node.value.0.childNodes[0].geometry?.firstMaterial?.diffuse.contents as! AVPlayer
                if player.isPlaying {
                    player.pause()
                }
            }
        }
    }
    
    @objc override func playerDidFinishPlaying(_ note: Notification) {
        super.playerDidFinishPlaying(note)
        for node in videoNodes {
            if ((node.value.0 as SCNNode).childNodes[0].geometry?.firstMaterial?.diffuse.contents as! AVPlayer).currentItem == note.object as? AVPlayerItem {
                // Remove planeNode from node for image anchor
                node.value.0.childNodes[0].removeFromParentNode()
                
                // Remove node for image anchor to allow for images to be detected again
                //sceneView.session.remove(anchor: node.value.1)
                break
            }
        }
    }
    
    override func updateForNewResources() {
        let referenceImages = getImages()
        self.configuration.detectionImages = referenceImages
        self.configuration.maximumNumberOfTrackedImages = 3

        // Run the view's session
        sceneView.session.run(self.configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        coreDataHandler.getCoreData(forResourceArray: &resources)
        
        DispatchQueue.main.async {
            self.setUpAudioSession()
        }
        
        sceneView.isUserInteractionEnabled = true
        
        let referenceImages = getImages()
        self.configuration.detectionImages = referenceImages
        self.configuration.maximumNumberOfTrackedImages = 3
        
        sceneView.session.run(self.configuration, options: [.resetTracking,.removeExistingAnchors])
        
        printNSManagedObjects(forArray: resources)
    }
    
    func setUpAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, policy: .default, options: .defaultToSpeaker)
        } catch {
            print("error with AVAudioSession")
        }
    }
    
    override func handleTap(sender: UITapGestureRecognizer) {
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
        if let videoPlayer: AVPlayer = videoNodes[name]?.0.childNodes[0].geometry?.firstMaterial?.diffuse.contents as? AVPlayer {
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
    
    public init(forView view: ARSCNView, forResourceGroup resources: NSMutableArray) {
        print("TourMode initialized")
        super.init(forView: view, withDescription: "Tour Mode")
        self.resources = resources
    }
    
    override func clean() {
        for node in videoNodes {
            let videoPlayerNode = node.value.0 as SCNNode
            let videoPlayer = videoPlayerNode.childNodes[0].geometry?.firstMaterial?.diffuse.contents as! AVPlayer
            videoPlayer.pause()
            videoPlayer.replaceCurrentItem(with: nil)
        }
    }
}

extension AVPlayer {
    var isPlaying: Bool {
        return (self.rate != 0 && self.error == nil)
    }
}
