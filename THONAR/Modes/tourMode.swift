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
        // When a node is added, starting the video attached to it. The node is accessed from the videoNodes array
        (videoNodes[node.name]?.0.childNodes[0].geometry?.firstMaterial?.diffuse.contents as! AVPlayer).play()
    }
    
    func pauseAllOtherVideos() {
        for node in videoNodes {
            if !node.value.0.childNodes.isEmpty {
                // node.value is a tuple with the node at index 0 and the image anchor at index 1
                // Safely unwraps the player because if there is a node with a video that has already finished,
                //  the video will have been removed from the node's material
                if let player = node.value.0.childNodes[0].geometry?.firstMaterial?.diffuse.contents as? AVPlayer {
                    if player.isPlaying {
                        player.pause()
                    }
                }
            }
        }
    }
    
    // Called from the observer set in createVideoPlayerPlaneNode
    @objc override func playerDidFinishPlaying(_ note: Notification) {
        super.playerDidFinishPlaying(note)
        for node in videoNodes {
            if (node.value.0.childNodes[0].geometry?.firstMaterial?.diffuse.contents as! AVPlayer).currentItem == note.object as? AVPlayerItem {
                // Switch case for the name of the video currently playing
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
        // Removes node's video player
        node.geometry?.firstMaterial?.diffuse.contents = nil
        
        node.opacity = 0.5
        
        for theNode in node.childNodes {
            // Presents the option plane nodes
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
        
        // Calls on coreDataHandler to query objects from CoreData and update the resources array
        coreDataHandler.getCoreData(forResourceArray: &resources)
        
        DispatchQueue.main.async {
            // Sets up the audio session on the main thread
            self.setUpAudioSession()
        }
        
        // Ensures that the sceneView's isUserInteractedEnabled property is true for this mode
        sceneView.isUserInteractionEnabled = true
        
        let referenceImages = getImages()
        self.configuration.detectionImages = referenceImages
        self.configuration.maximumNumberOfTrackedImages = 3
        
        sceneView.session.run(self.configuration, options: [.resetTracking,.removeExistingAnchors])
        
        // Prints out the CoreData objects to show what detectionImages and videos have loaded in
        printNSManagedObjects(forArray: resources)
    }
    
    func setUpAudioSession() {
        do {
            // Sets the audio session to play video audio from the main speaker
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, policy: .default, options: .defaultToSpeaker)
        } catch {
            print("error with AVAudioSession")
        }
    }
    
    override func handleTap(sender: UITapGestureRecognizer) {
        // Get view that was tapped
        let tappedView = sender.view as! SCNView
        
        // Get the location of the tap within the tapped view
        let touchLocation = sender.location(in: tappedView)
        
        // Get the location with the 3D AR scene based on the location of the tap within the tapped view
        let hitTest = tappedView.hitTest(touchLocation, options: nil)
        if !hitTest.isEmpty {
            // Get the first tapped node and update the video player on the tapped node
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
    
    // Generic Initializer
    public override init() {
        super.init()
    }
    
    // Main initializer for Tour Mode
    public init(forView view: ARSCNView, forResourceGroup resources: NSMutableArray) {
        print("TourMode initialized")
        super.init(forView: view, withDescription: "Tour Mode")
        self.resources = resources
    }
    
    // Invalidates and deletes all AVPlayers
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
