//
//  mode.swift
//  THONAR
//
//  Created by Kevin Gardner on 12/15/18.
//  Copyright © 2018 THON. All rights reserved.
//

import Foundation
import ARKit
import AVFoundation

/// Default mode to be subclassed for specific types of modes
class Mode {
    var configuration: ARWorldTrackingConfiguration
    let sceneView: ARSCNView
    
    // Stores the node and ARImageAnchor for each node containing a video
    var videoNodes = [String?:(SCNNode,ARImageAnchor)]()
    
    
    // Stores the NSManagedObjects containing image and video data
    var resources: NSMutableArray? {
        didSet {
            //updateForNewResources()
            print("resources has been updated ----- resources.count: \(String(describing: resources?.count))")
        }
    }
    
    // Identifier for the current mode
    let description: String
    
    // Delegate that can present a message to the user
    var alertMessageDelegate: AlertMessageDelegate?
    
    // Instance of the CoreDataHandler that handles querying from CoreData
    let coreDataHandler = CoreDataHandler()
    
    
    // Override in subclasses
    func session(forCamera camera: ARCamera) {
        
    }
    
    // Override in subclasses
    func updateForNewResources() {
        
    }
    
    func viewWillAppear() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
        
        sceneView.session.run(self.configuration, options: [.resetTracking,.removeExistingAnchors])
    }
    
    func printNSManagedObjects(forArray array: NSMutableArray?) {
        if let resourceArray = array {
            for resource in resourceArray {
                print("-----------------------------------------")
                print("object named \(String(describing: coreDataHandler.getStringData(forNSManagedObject: resource, forKey: "name")))")
                print("has image? \(String(describing: coreDataHandler.getData(forNSManagedObject: resource, forKey: "photo") != nil))")
                print("has video? \(String(describing: coreDataHandler.getData(forNSManagedObject: resource, forKey: "video")  != nil))")
                print("-----------------------------------------")
            }
        } else {
            print("Array not initialized yet")
        }
    }
    
    // Override in subclasses
    @objc func handleTap(sender: UITapGestureRecognizer) {
        print("super view ran handle tap")
        
    }
    
    // Called when a mode changes since viewController's viewWillAppear will not be called
    func updateView() {
        removeAllSubviews()
        viewWillAppear()
    }
    
    func viewWillDisappear() {
        // Pause the view's session
        sceneView.session.pause()
        print("viewWillDisappear (from Mode)")
    }
    
    // Removes any extraneous subviews present from previous modes
    func removeAllSubviews() {
        let view = sceneView as UIView
        for view in view.subviews {
            view.removeFromSuperview()
        }
    }
    
    // Generic initializer
    public init() {
        self.configuration = ARWorldTrackingConfiguration()
        self.sceneView = ARSCNView()
        self.description = "Mode"
    }
    
    // Initializer for each mode
    public init(forView view: ARSCNView, withDescription description: String = "Mode") {
        self.configuration = ARWorldTrackingConfiguration()
        self.sceneView = view
        self.description = description
    }
    
    // Creates a node that displays a video when a certain image is detected using video URL
    func createVideoPlayerPlaneNode(forResourceDictionary resourceNames: [String:(String,String)], forImageAnchor imageAnchor: ARImageAnchor, fromImageName name: String?) -> SCNNode {
        let videoPlayer : AVPlayer = {
            //Load video from bundle
            guard let url = getURL(forResourceDictionary: resourceNames, forImageName: name!) else {
                
                alertMessageDelegate?.showAlert(forMessage: "Could not find video file.", ofSize: AlertSize.large, withDismissAnimation: true)
                
                return AVPlayer()
            }
            
            return AVPlayer(url: url)
        }()
        //videoPlayers[name!] = videoPlayer
        let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
        plane.firstMaterial?.diffuse.contents = videoPlayer
        videoPlayer.play()
        
        let planeNode = SCNNode(geometry: plane)
        planeNode.eulerAngles.x = -.pi / 2
        return planeNode
    }
    
    // Returns a URL from the string representation of a URL
    func getURL(forResourceDictionary resourceNames: [String: (String,String)], forImageName imageName: String) -> URL? {
        // if imageName exists in the videoPlayer dictionary
        if let resourceName = resourceNames[imageName] {
            return Bundle.main.url(forResource: resourceName.0, withExtension: resourceName.1)
        } else {
            print("Could not find image named \(imageName) in resourceNames")
            return nil
        }
    }
    
    // Creates a node that displays a video when a certain is detected using video Data
    func createVideoPlayerPlaneNode(forData data: Data, forResourceName resourceName: String, forImageAnchor imageAnchor: ARImageAnchor) -> SCNNode {
        let videoPlayer : AVPlayer = {
            // Load video from bundle
            print("create video player node for resourceName: \(resourceName)")
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let destinationPath = documentsPath + "/filename.mp4"
            FileManager.default.createFile(atPath: destinationPath, contents: data, attributes: nil)
            let player = AVPlayer(url: URL(fileURLWithPath: destinationPath))
            return player
        }()
        
        // Create plane with the dimensions of the reference image
        let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
        
        // Add videoPlayer to the material of the plane
        plane.firstMaterial?.diffuse.contents = videoPlayer
        
        // Create plane node with the plane previously created as its geometry
        let planeNode = SCNNode(geometry: plane)
        
        // Rotate node by -.pi / 2 to make it facing the camera and vertical
        planeNode.eulerAngles.x = -.pi / 2
        
        // Add observer that is called when the video finishes playing
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying(_:)), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: (planeNode.geometry?.firstMaterial?.diffuse.contents as! AVPlayer).currentItem)
        
        // Add video options that display after the video finishes as child nodes of the planeNode
        planeNode.addChildNodes(createOptionPlayerNodes(forNumOptions: 3, imageAnchorHeight: imageAnchor.referenceImage.physicalSize.height, imageAnchorWidth: imageAnchor.referenceImage.physicalSize.width, imageAnchorCenterX: planeNode.position.x, imageAnchorCenterY: planeNode.position.y, imageAnchorCenterZ: planeNode.position.z, forResourceName: resourceName))
        
        return planeNode
    }
    
    func createOptionPlayerNodes(forNumOptions numOptions: Int, forTopMargin topMargin: CGFloat = 0.005, forSideMargin sideMargin: CGFloat = 0.005, imageAnchorHeight iaHeight: CGFloat,
                                 imageAnchorWidth iaWidth: CGFloat, imageAnchorCenterX iaX: Float, imageAnchorCenterY iaY: Float, imageAnchorCenterZ iaZ: Float, forResourceName resourceName: String) -> [SCNNode] {
        var nodes: [SCNNode] = []
        
        let numVideoOptions = numOptions
        let widthDivisions: Float = 3
        
        let topMargin: CGFloat = topMargin
        let sideMargin: CGFloat = sideMargin
        
        let height = CGFloat(iaHeight / CGFloat(numVideoOptions)) - topMargin
        let width = CGFloat(iaWidth / 3) - sideMargin
        
        let rightX = (iaX + Float(iaWidth / 2))
        let centerX = rightX - ((Float(iaWidth) / (widthDivisions*2)))
        let centerZ = iaZ + 0.002
        
        for videoNum in 0..<numVideoOptions {
            let bottomY = (iaY - Float(iaHeight / 2))
            let centerY = bottomY + (Float(iaHeight) / Float(numVideoOptions * 2)) * (2 * Float(videoNum) + 1)
            
            // Create plane with dimensions proportions relative to size of the imageAnchor (or encompassing node),
            //  the number of video options, and the margins
            let optionPlane = SCNPlane(width: width, height: height)
            
            // Set material of plane
            optionPlane.firstMaterial?.multiply.contents = UIColor.red
            
            // Create option plane node with the previously created plane as its geometry
            let optionPlaneNode = SCNNode(geometry: optionPlane)
            
            // Set the opacity to 0.0 so it is not visible while the video is playing
            // -> run node.runAction(SCNAction.fadeIn(duration: TimeInterval) to present it
            optionPlaneNode.opacity = 0.0
            
            // Set the node's name to the name of the referenceImage with the option number appended to it
            optionPlaneNode.name = resourceName + " option " + String(videoNum)
            
            // Set the node's position relative to the imageAnchor's position taking into account the number of video options
            optionPlaneNode.position = SCNVector3Make(centerX, centerY, centerZ)
            
            // Add plane node to the nodes array
            nodes.append(optionPlaneNode)
        }
        
        return nodes
    }
    
    // Override in subclasses
    @objc func playerDidFinishPlaying(_ note: Notification) {
        print("Video Finished")
    }
    
    // Resets the ARSCNView
    func update() {
        let referenceImages = getImages()
        self.configuration.detectionImages = referenceImages
        self.configuration.maximumNumberOfTrackedImages = 3
        
        // Run the view's session
        sceneView.session.run(self.configuration)
    }
    
    // Override in subclasses
    // Called when the mode changes to invalidate any timers or stop AVPlayers
    func clean() {}
    
    // Gets images from CoreData and returns a set of ARReferenceImages for ARKit's detection images
    func getImages() -> Set<ARReferenceImage>? {
        var set = Set<ARReferenceImage>()
        
        // Safely unwrap resources
        guard let dataArray = resources else {
            return nil
        }
        
        // Loop through NSManagedObjects to create a set of reference images
        for resource in dataArray {
            // Calls on the coreDataHandler to query from CoreData objects
            if let imageData = coreDataHandler.getData(forNSManagedObject: resource, forKey: "photo") {
                let image = UIImage(data: imageData)
                
                let ciImage = CIImage(image: image!)
                let context = CIContext(options: nil)
                let cgImage = context.createCGImage(ciImage!, from: ciImage!.extent)
                let referenceImage = ARReferenceImage(cgImage!, orientation: CGImagePropertyOrientation.up, physicalWidth: 0.2)
                referenceImage.name = coreDataHandler.getStringData(forNSManagedObject: resource, forKey: "name")
                set.insert(referenceImage)
            } else {
                print("error with image data")
            }
        }
        return set
    }
    
    
    func didFailWithError(_ error: Error, completion: (Bool) -> Void) {
        alertMessageDelegate?.showAlert(forMessage: "Error - \(error)", ofSize: AlertSize.large, withDismissAnimation: true)
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        alertMessageDelegate?.showAlert(forMessage: "Session has been interrupted", ofSize: AlertSize.large, withDismissAnimation: true)
        session.pause()
    }
    
    func sessionInterruptionEnded(_ session: ARSession, completion: (Bool) -> Void) {
        alertMessageDelegate?.showAlert(forMessage: "Session has resumed and will reset", ofSize: AlertSize.large, withDismissAnimation: true)
    }
    
    // MARK: - ARSCNViewDelegate
    // Override in subclasses
    func renderer(nodeFor anchor: ARAnchor) -> SCNNode? { return nil }
    
    // Override in subclasses
    func renderer(updateAtTime time:TimeInterval) {}
    
    // Override in subclasses
    func renderer(didAdd node: SCNNode, for anchor: ARAnchor) {}
}

extension SCNNode {
    // Add a child node for each node in an array of SCNNodes
    func addChildNodes(_ nodes: [SCNNode]) {
        for node in nodes {
            self.addChildNode(node)
        }
    }
}
