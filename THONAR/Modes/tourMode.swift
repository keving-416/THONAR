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
    
    var collectionView: UICollectionView?
    let cellID = "ExampleCell"
    let cellSpacing: CGFloat = 10
    
    override func renderer(nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
        
        if let imageAnchor = anchor as? ARImageAnchor {
            // Do something when an image is detected
            
            pauseAllOtherVideos()
            
            let referenceImageName = imageAnchor.referenceImage.name
            print("detected \(String(describing: referenceImageName))")
            
            // Sets node's name property to the referenceImageName to later identify the tapped node
            node.name = referenceImageName
            
            node.addChildNode(self.createVideoPlayerPlaneNode(forResourceName: referenceImageName!, forImageAnchor: imageAnchor))
            
            for bool in nodePresent {
                nodePresent[bool.key] = false
            }
            
            nodePresent[referenceImageName] = true
            
            for videoNode in videoNodes {
                if videoNode.key != referenceImageName! {
                    updateNodesOutOfView(forPresentNode: videoNode.value.0)
                }
            }
            
            // Add node for anchor and anchor to videoNodes dictionary
            self.videoNodes[referenceImageName] = (node, imageAnchor)
            
            // Sets opacity to 0.0 to fade in the node and create a smooth transition
            node.opacity = 0.0
        }
        
        return node
    }
    
    var nodePresent = [String?:Bool]()
    
    override func renderer(didUpdate node: SCNNode, for anchor: ARAnchor) {
        //print("didUpdate: \(String(describing: node.name))")
        // If the node in view is
        /*
        if !nodePresent[node.name]! {
            node.runAction(SCNAction.wait(duration: 0.1)) {
                node.runAction(SCNAction.fadeIn(duration: 0.2))
            }
            
            if let videoPlayer = node.childNodes[0].geometry?.firstMaterial?.diffuse.contents as? AVPlayer {
                print("Main video player for \(String(describing: node.name)) has resumed")
                videoPlayer.play()
            } else if let optionVideoPlayer = node.childNodes[0].childNodes[0].geometry?.firstMaterial?.diffuse.contents as? AVPlayer {
                print("Option video player \(String(describing: node.childNodes[0].childNodes[0])) has resumed")
                optionVideoPlayer.play()
            }
            
            nodePresent[node.name] = true
            
            for videoNode in videoNodes {
                if videoNode.key != node.name {
                    updateNodesOutOfView(forPresentNode: videoNode.value.0)
                    nodePresent[videoNode.key] = false
                }
            }
        }
 */
    }
    
    func updateNodesOutOfView(forPresentNode node: SCNNode) {
        /*
        node.runAction(SCNAction.fadeOut(duration: 0.2))
        if let videoPlayer = node.childNodes[0].geometry?.firstMaterial?.diffuse.contents as? AVPlayer {
            print("Main video player for \(String(describing: node.name)) has paused")
            videoPlayer.pause()
        }
        
        if let optionVideoPlayer = node.childNodes[0].childNodes[0].geometry?.firstMaterial?.diffuse.contents as? AVPlayer {
            print("Option video player \(String(describing: node.childNodes[0].childNodes[0].name)) has paused")
            optionVideoPlayer.pause()
        }
 */
    }
    
    override func renderer(didAdd node: SCNNode, for anchor: ARAnchor) {
        print("renderer did add ran")
        // Accessing video data from CoreData is an extensive task and must NOT be done on the main thread.
        //  Task is instead performed on the global thread with Quality-Of-Service (qos) .userInitiated, which is
        //  the highest queue priority.
        DispatchQueue.global(qos: .userInitiated).async {
            // Create AVPlayer storing the video for the associated name
            let videoPlayer: AVPlayer = self.getVideoPlayer(forResourceName: node.name!, false)
            
            // Updates the UI in the main thread
            DispatchQueue.main.async {
                // Add videoPlayer to the material of the plane
                node.childNodes[0].geometry?.firstMaterial?.diffuse.contents = videoPlayer
                
                // Add observer that is called when the video finishes playing
                NotificationCenter.default.addObserver(self, selector: #selector(self.playerDidFinishPlaying(_:)), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: (node.childNodes[0].geometry?.firstMaterial?.diffuse.contents as! AVPlayer).currentItem)
                
                // Present the video node
                node.runAction(SCNAction.fadeIn(duration: 0.3), completionHandler: {
                    // When a node is added, starting the video attached to it. The node is accessed from the videoNodes array
                    videoPlayer.play()
                    
                    let pprNode = node.childNodes[0].childNodes[1]
                    self.runPlayPauseAction(forNode: pprNode, for: "Play")
                })
            }
        }
        
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
                case "Lizzy 1", "Maddy 1", "Mary 1", "Zach 1", "Tim 1":
                    createOptions(forNode: node.value.0.childNodes[0], forImageAnchor: node.value.1, forVideoName: node.key!)
                default:
                    // Show option to reset video
                    //runRepeatAction(forNode: node.value.0.childNodes[0].childNodes[1])
                    
                    // Remove from scene
                    sceneView.session.remove(anchor: node.value.1)
                }
                break
            }
        }
    }
    
    @objc func optionPlayerDidFinishPlaying(_ note: Notification) {
        for node in videoNodes {
            // *****ONLY WORKS IF THERE IS ONE OPTION*****
            if let currentPlayer = node.value.0.childNodes[0].childNodes[0].geometry?.firstMaterial?.diffuse.contents as? AVPlayer {
                if currentPlayer.currentItem == note.object as? AVPlayerItem {
                    makeSmallSize(forOptionNode: node.value.0.childNodes[0].childNodes[0], forImageAnchor: node.value.1)
                    videoSelected = false
                }
            } else {
                print("current node: \(String(describing: node.value.0.childNodes[0].childNodes[0].name))")
            }
            
        }
    }
    
    func createOptions(forNode node: SCNNode, forImageAnchor imageAnchor: ARImageAnchor, forVideoName name: String) {
        print("create Options")
        DispatchQueue.global(qos: .userInitiated).async {
            // Set videoPlayer for the current video
            let videoPlayer: AVPlayer = self.getVideoPlayer(forResourceName: name, true)
            
            //for theNode in node.childNodes {
            let theNode = node.childNodes[0]
                DispatchQueue.main.async {
                    self.runRepeatAction(forNode: node.childNodes[1])
                    
                    theNode.runAction(SCNAction.fadeIn(duration: 0.1))
                    
                    // Set material of the option node's geometry to the video player
                    theNode.geometry?.firstMaterial?.diffuse.contents = videoPlayer
                    
                    // Add observer that is called when the video finishes playing
                    NotificationCenter.default.addObserver(self, selector: #selector(self.optionPlayerDidFinishPlaying(_:)), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: videoPlayer.currentItem)
                }
            //}
        }
    }
    
    func getVideoPlayer(forResourceName name: String,_ isOptionNode: Bool) -> AVPlayer {
        let newName: String
        if isOptionNode {
            newName = name.replacingOccurrences(of: "1", with: "2")
        } else {
            newName = name
        }
        
        print("newName: \(newName)")
        var videoPlayer: AVPlayer = AVPlayer()
        
        // Find resource in resources array for the option image
        for resource in resources! {
            print("loop")
            //Calls on coreDataHandler to get data from CoreData object
            if coreDataHandler.getStringData(forNSManagedObject: resource, forKey: "name") == newName {
                print("found")
                print("\(newName) found within the resources array")
                if coreDataHandler.getData(forNSManagedObject: resource, forKey: "video") ?? nil != nil {
                    videoPlayer = {
                        // Load video from bundle
                        //print("create option video player node for resourceName: \(newName)")
                        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
                        let destinationPath = documentsPath + "/filename.mp4"
                        FileManager.default.createFile(atPath: destinationPath, contents: coreDataHandler.getData(forNSManagedObject: resource, forKey: "video")!, attributes: nil)
                        let player = AVPlayer(url: URL(fileURLWithPath: destinationPath))
                        return player
                    }()
                }
                print("loaded")
                break
            }
        }
        
        return videoPlayer
    }
    
    override func updateForNewResources() {
        DispatchQueue.global(qos: .userInitiated).async {
            let referenceImages = self.getImages()
            
            DispatchQueue.main.async {
                self.configuration.detectionImages = referenceImages
                self.configuration.maximumNumberOfTrackedImages = 3
                
                // Run the view's session
                self.sceneView.session.run(self.configuration, options: [.resetTracking, .removeExistingAnchors])
            }
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        DispatchQueue.global(qos: .userInitiated).async {
            if !self.coreDataHandler.dataHasFetched() {
                DispatchQueue.main.async {
                    self.alertMessageDelegate?.showAlert(forMessage: "Videos are currently downloading", ofSize: .small, withDismissAnimation: true)
                }
            }
            // Calls on coreDataHandler to query objects from CoreData and update the resources array
            self.coreDataHandler.getCoreData(forResourceArray: &self.resources)
            
            let referenceImages = self.getImages()
            
            DispatchQueue.main.async {
                // Sets up the audio session on the main thread
                self.setUpAudioSession()
                
                // Ensures that the sceneView's isUserInteractedEnabled property is true for this mode
                self.sceneView.isUserInteractionEnabled = true
                
                self.configuration.detectionImages = referenceImages
                self.configuration.maximumNumberOfTrackedImages = 3
                
                self.sceneView.session.run(self.configuration, options: [.resetTracking,.removeExistingAnchors])
                
                // Prints out the CoreData objects to show what detectionImages and videos have loaded in
                self.printNSManagedObjects(forArray: self.resources)
            }
        }
    }
    
    func runRepeatAction(forNode node: SCNNode) {
        node.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "Replay")
        
        node.runAction(SCNAction.fadeIn(duration: 0.3))
        
        node.name = "Repeat"
    }
    
    func runPlayPauseAction(forNode node: SCNNode, for action: String) {
        
        node.geometry?.firstMaterial?.diffuse.contents = UIImage(named: action)
        
        node.name = action
        
        node.runAction(SCNAction.fadeIn(duration: 0.3), completionHandler: {
            node.runAction(SCNAction.wait(duration: 0.5), completionHandler: {
                node.runAction(SCNAction.fadeOut(duration: 0.3))
            })
        })
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
    
    var videoSelected: Bool = false
    
    @objc func updateVideoPlayer(result: SCNHitTestResult) {
        // The nodes of the images are the parent of the SCNHitTestResult node
        print("node tapped: \(result.node.name)")
        print("parent node of node tapped: \(result.node.parent?.name)")
        var name = result.node.name
        let parentName = result.node.parent?.name
        
        var optionNum: Int? = 0
        
        if parentName == nil && name != nil && name != "Repeat" {
            guard let num = Int(String((name?.last)!)) else {
                print("Not a valid option number")
                return
            }
            optionNum = num
            name = String((name?.dropLast(9))!)
        }
        
        print("\(name) equals \"Repeat\": \(name == "Repeat")")
        
        if name == "Repeat" {
            print("parent of parent \(result.node.parent?.parent?.name)")
            if let videoPlayer: AVPlayer = videoNodes[result.node.parent?.parent?.name]?.0.childNodes[0].geometry?.firstMaterial?.diffuse.contents as? AVPlayer {
                videoNodes[result.node.parent?.parent?.name]!.0.childNodes[0].childNodes[0].runAction(SCNAction.fadeOut(duration: 0.3)) {
                    self.videoNodes[result.node.parent?.parent?.name]!.0.childNodes[0].childNodes[0].runAction(SCNAction.move(by: SCNVector3Make(0, 0, 0.004), duration: 0.01))
                }
                videoPlayer.seek(to: CMTime.zero)
                
                runPlayPauseAction(forNode: videoNodes[result.node.parent?.parent?.name]!.0.childNodes[0].childNodes[1], for: "Play")
                videoPlayer.play()
            } else {
                print("not a player")
            }
        } else if parentName != nil, let videoPlayer: AVPlayer = videoNodes[parentName]?.0.childNodes[0].geometry?.firstMaterial?.diffuse.contents as? AVPlayer {
            if videoPlayer.isPlaying {
                runPlayPauseAction(forNode: videoNodes[parentName]!.0.childNodes[0].childNodes[1], for: "Pause")
                videoPlayer.pause()
            } else {
                runPlayPauseAction(forNode: videoNodes[parentName]!.0.childNodes[0].childNodes[1], for: "Play")
                videoPlayer.play()
            }
        } else if let videoPlayer: AVPlayer = videoNodes[name]?.0.childNodes[0].childNodes[optionNum!].geometry?.firstMaterial?.diffuse.contents as? AVPlayer {
            if videoPlayer.isPlaying {
                //runPlayPauseAction(forNode: videoNodes[parentName]!.0.childNodes[0].childNodes[1], for: "Pause")
                videoPlayer.pause()
            } else {
                //runPlayPauseAction(forNode: videoNodes[parentName]!.0.childNodes[0].childNodes[1], for: "Play")
                videoPlayer.play()
                
                if !videoSelected {
                    makeFullSize(forOptionNode: (videoNodes[name]?.0.childNodes[0].childNodes[optionNum!])!)
                    videoSelected = true
                }
            }
        } else {
            print("No video players present")
        }
    }
    
    func makeFullSize(forOptionNode node: SCNNode) {
        let scale: CGFloat = 3.0
        let group = SCNAction.group([SCNAction.scale(by: scale, duration: 0.3), SCNAction.move(to: SCNVector3Make(((node.parent?.position.x)! + Float(0.06)), (node.parent?.position.y)!
            , (node.parent?.position.z)! + 0.002), duration: 0.3)])
        
        node.runAction(group)
    }
    
    func makeSmallSize(forOptionNode node: SCNNode, forImageAnchor imageAnchor: ARImageAnchor) {
        let scale: CGFloat = 1/3
        
        let iaX = (node.parent?.position.x)! + Float(0.06)
        let iaY = node.parent?.position.y
        let iaZ = node.parent?.position.z
        
        let iaWidth = imageAnchor.referenceImage.physicalSize.width * 4
        let rightX = (iaX - Float(iaWidth / 2))
        let centerX = rightX + ((Float(iaWidth) / (3*2)))
        let centerY = iaY!
        let centerZ = iaZ! + 0.002
        
        let group = SCNAction.group([SCNAction.scale(by: scale, duration: 0.3), SCNAction.move(to: SCNVector3Make(centerX, centerY
            , centerZ), duration: 0.3)])
        
        node.runAction(group)
    }
    
    override func infoButtonPressed() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewLayout())
        collectionView?.translatesAutoresizingMaskIntoConstraints = false
        sceneView.addSubview(collectionView!)
        
        collectionView?.leadingAnchor.constraint(equalTo: sceneView.leadingAnchor).isActive = true
        collectionView?.trailingAnchor.constraint(equalTo: sceneView.trailingAnchor).isActive = true
        collectionView?.topAnchor.constraint(equalTo: sceneView.topAnchor).isActive = true
        collectionView?.bottomAnchor.constraint(equalTo: sceneView.bottomAnchor).isActive = true
        
        collectionView?.backgroundColor = UIColor(red: 0.996, green: 0.796, blue: 0.102, alpha: 1)
        
        let collectionViewFlowLayout = UICollectionViewFlowLayout()
        collectionView?.setCollectionViewLayout(collectionViewFlowLayout, animated: true)
        collectionViewFlowLayout.scrollDirection = .vertical
        collectionViewFlowLayout.sectionInset = UIEdgeInsets(top: 0, left: cellSpacing, bottom: 0, right: cellSpacing)
        
        collectionView?.register(DetectionImageCollectionCell.self, forCellWithReuseIdentifier: cellID)
        collectionView?.delegate = self
        collectionView?.dataSource = self
    }
    
    // Generic Initializer
    public override init() {
        super.init()
    }
    
    // Main initializer for Tour Mode
    public init(forView view: ARSCNView) {
        print("TourMode initialized")
        super.init(forView: view, withDescription: "Tour Mode")
    }
    
    // Invalidates and deletes all AVPlayers
    override func clean() {
        for node in videoNodes {
            let videoPlayerNode = node.value.0 as SCNNode
            if let videoPlayer = videoPlayerNode.childNodes[0].geometry?.firstMaterial?.diffuse.contents as? AVPlayer {
                videoPlayer.pause()
                videoPlayer.replaceCurrentItem(with: nil)
            }
            let optionVideoPlayerNode = videoPlayerNode.childNodes[0]
            for optionNode in optionVideoPlayerNode.childNodes {
                if let optionVideoPlayer = optionNode.geometry?.firstMaterial?.diffuse.contents as? AVPlayer {
                    optionVideoPlayer.pause()
                    optionVideoPlayer.replaceCurrentItem(with: nil)
                }
            }
        }
    }
}

extension TourMode: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return resources?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath) as! DetectionImageCollectionCell
        
        DispatchQueue.global(qos: .userInitiated).async {
            let image = UIImage(data: self.coreDataHandler.getData(forNSManagedObject: self.resources![indexPath.row], forKey: "photo")!)!
            DispatchQueue.main.async {
                cell.image = image
                cell.autolayoutCell()
            }
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (UIScreen.main.bounds.size.width - 3 * cellSpacing) / 2
        let heigth = width
        return CGSize(width: width, height: heigth)
    }
}

extension AVPlayer {
    var isPlaying: Bool {
        return (self.rate != 0 && self.error == nil)
    }
}

extension String {
    subscript(_ range: CountableRange<Int>) -> String {
        let idx1 = index(startIndex, offsetBy: max(0, range.lowerBound))
        let idx2 = index(startIndex, offsetBy: min(self.count, range.upperBound))
        return String(self[idx1..<idx2])
    }
}
