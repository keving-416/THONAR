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
            
            // Sets node's name property to the referenceImageName to later identify the tapped node
            node.name = referenceImageName
            
            // Find resource in resources array for the image that was detected
            for resource in resources! {
                // Calls on coreDataHandler to get data from CoreData object
                if coreDataHandler.getStringData(forNSManagedObject: resource, forKey: "name") == referenceImageName {
                    node.addChildNode(createVideoPlayerPlaneNode(forData: coreDataHandler.getData(forNSManagedObject: resource, forKey: "video")!, forResourceName: referenceImageName!, forImageAnchor: imageAnchor))
                    break
                }
            }
            // Add node for anchor and anchor to videoNodes dictionary
            videoNodes[referenceImageName] = (node, imageAnchor)
            
            // Sets opacity to 0.0 to fade in the node and create a smooth transition
            node.opacity = 0.0
            node.runAction(SCNAction.wait(duration: 0.05)) {
                node.runAction(SCNAction.fadeIn(duration: 0.5))
            }
        }
        return node
    }
    
    override func renderer(didAdd node: SCNNode, for anchor: ARAnchor) {
        print("renderer did add ran")
        (videoNodes[node.name]?.0.childNodes[0].geometry?.firstMaterial?.diffuse.contents as! AVPlayer).play()
    }
    
    func pauseAllOtherVideos() {
        for node in videoNodes {
            if !node.value.0.childNodes.isEmpty {
                if let player = node.value.0.childNodes[0].geometry?.firstMaterial?.diffuse.contents as? AVPlayer {
                    if player.isPlaying {
                        player.pause()
                    }
                }
            }
        }
    }
    
    @objc override func playerDidFinishPlaying(_ note: Notification) {
        super.playerDidFinishPlaying(note)
        for node in videoNodes {
            if (node.value.0.childNodes[0].geometry?.firstMaterial?.diffuse.contents as! AVPlayer).currentItem == note.object as? AVPlayerItem {
                switch node.key {
                case "THON Logo Animation":
                    createOptions(forNode: node.value.0.childNodes[0], forImageAnchor: node.value.1)
                default:
                    // Remove from scene
                    sceneView.session.remove(anchor: node.value.1)
                }
                break
            }
        }
    }
    
    func createOptions(forNode node: SCNNode, forImageAnchor imageAnchor: ARImageAnchor) {
        print("create Options")
        node.geometry?.firstMaterial?.diffuse.contents = nil
        node.opacity = 0.5
        
        for theNode in node.childNodes {
            theNode.runAction(SCNAction.fadeIn(duration: 0.2))
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
                result.node.parent?.scale = SCNVector3(2, 1.5 , 1)
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
            if let videoPlayer = videoPlayerNode.childNodes[0].geometry?.firstMaterial?.diffuse.contents as? AVPlayer {
                videoPlayer.pause()
                videoPlayer.replaceCurrentItem(with: nil)
            }
        }
    }
}

extension AVPlayer {
    var isPlaying: Bool {
        return (self.rate != 0 && self.error == nil)
    }
}
