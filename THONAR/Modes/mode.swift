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
class Mode: NSObject {
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
    let modeDescription: String
    
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
                print("has video? \(String(describing: coreDataHandler.getData(forNSManagedObject: resource, forKey: "video") ?? nil  != nil))")
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
    override public init() {
        self.configuration = ARWorldTrackingConfiguration()
        self.sceneView = ARSCNView()
        self.modeDescription = "Mode"
    }
    
    // Initializer for each mode
    public init(forView view: ARSCNView, withDescription description: String = "Mode") {
        self.configuration = ARWorldTrackingConfiguration()
        self.sceneView = view
        self.modeDescription = description
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
    func createVideoPlayerPlaneNode(forResourceName resourceName: String, forImageAnchor imageAnchor: ARImageAnchor) -> SCNNode {
        let offset: Float
        let multiplier: CGFloat
        
        switch resourceName {
        case "Maddy 1":
            offset = 0.079
            multiplier = 4
        case "Zach 1":
            offset = 0.06
            multiplier = 4
        case "Lizzy 1":
            offset = 0.085
            multiplier = 4
        case "Mary 1":
            offset = 0.074
            multiplier = 4
        default:
            offset = 0.0
            multiplier = 1
        }
        
        let referenceImagePhysicalSizeWidth = imageAnchor.referenceImage.physicalSize.width * multiplier
        
        // Create plane with the dimensions of the reference image
        let plane = SCNPlane(width: referenceImagePhysicalSizeWidth, height: imageAnchor.referenceImage.physicalSize.height)
        
        // Create plane node with the plane previously created as its geometry
        let planeNode = SCNNode(geometry: plane)
        
        // Rotate node by -.pi / 2 to make it facing the camera and vertical
        planeNode.eulerAngles.x = -.pi / 2
        
        
        planeNode.position = SCNVector3Make(planeNode.position.x - offset, planeNode.position.y, planeNode.position.z)
        
        // Add video options that display after the video finishes as child nodes of the planeNode
        planeNode.addChildNodes(createOptionPlayerNodes(forNumOptions: 1, imageAnchorHeight: imageAnchor.referenceImage.physicalSize.height, imageAnchorWidth: referenceImagePhysicalSizeWidth, imageAnchorCenterX: planeNode.position.x + offset, imageAnchorCenterY: planeNode.position.y, imageAnchorCenterZ: planeNode.position.z, forResourceName: resourceName))
        
        planeNode.addChildNode(createPlayPauseRepeatNode(imageAnchorHeight: imageAnchor.referenceImage.physicalSize.height, imageAnchorWidth: referenceImagePhysicalSizeWidth, imageAnchorCenterX: planeNode.position.x + offset, imageAnchorCenterY: planeNode.position.y, imageAnchorCenterZ: planeNode.position.z))
        
        return planeNode
    }
    
    func createPlayPauseRepeatNode(imageAnchorHeight iaHeight: CGFloat, imageAnchorWidth iaWidth: CGFloat, imageAnchorCenterX iaX: Float, imageAnchorCenterY iaY: Float, imageAnchorCenterZ iaZ: Float) -> SCNNode {
        let smaller = [iaWidth,iaHeight].min()
        
        let plane = SCNPlane(width: smaller!/5, height: smaller!/5)
        
        let planeNode = SCNNode(geometry: plane)
        
        //planeNode.eulerAngles.x = -.pi / 2
        
        planeNode.position = SCNVector3Make(iaX, iaY, iaZ + 0.001)
        
        // PPR - PlayPauseRepeat
        planeNode.name = "Play"
        
        planeNode.opacity = 0.0
        
        return planeNode
        
    }
    
    func createOptionPlayerNodes(forNumOptions numOptions: Int, forTopMargin topMargin: CGFloat = 0.000, forSideMargin sideMargin: CGFloat = 0.000, imageAnchorHeight iaHeight: CGFloat,
                                 imageAnchorWidth iaWidth: CGFloat, imageAnchorCenterX iaX: Float, imageAnchorCenterY iaY: Float, imageAnchorCenterZ iaZ: Float, forResourceName resourceName: String) -> [SCNNode] {
        var nodes: [SCNNode] = []
        
        let numVideoOptions = numOptions
        let widthDivisions: Float = 3
        
        let topMargin: CGFloat = topMargin
        let sideMargin: CGFloat = sideMargin
        
        let height = CGFloat(iaHeight / 3) - topMargin
        let width = CGFloat(iaWidth / 3) - sideMargin
        
        let rightX = (iaX - Float(iaWidth / 2))
        let centerX = rightX + ((Float(iaWidth) / (widthDivisions*2)))
        let centerZ = iaZ + 0.002
        
        for videoNum in 0..<numVideoOptions {
            //let bottomY = (iaY + Float(iaHeight / 2))
            //let centerY = bottomY - (Float(iaHeight) / Float(numVideoOptions * 2)) * (2 * Float(videoNum) + 1)
            let centerY = iaY
            
            // Create plane with dimensions proportions relative to size of the imageAnchor (or encompassing node),
            //  the number of video options, and the margins
            let optionPlane = SCNPlane(width: width, height: height)
            
            // Set material of plane
            //optionPlane.firstMaterial?.multiply.contents = UIColor.red
            
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
    func infoButtonPressed() {
        
    }
    
    // Override in subclasses
    @objc func playerDidFinishPlaying(_ note: Notification) {
        print("Video Finished")
    }
    
    // Resets the ARSCNView
    func update() {
        DispatchQueue.global(qos: .userInitiated).async {
            let referenceImages = self.getImages()
            
            DispatchQueue.main.async {
                self.configuration.detectionImages = referenceImages
                self.configuration.maximumNumberOfTrackedImages = 3
                
                // Run the view's session
                self.sceneView.session.run(self.configuration)
            }
        }
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
                let referenceImage = ARReferenceImage(cgImage!, orientation: CGImagePropertyOrientation.up, physicalWidth: 0.1)
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
    
    // Override in subclasses
    func renderer(didUpdate node: SCNNode, for anchor: ARAnchor) {}
}

extension SCNNode {
    // Add a child node for each node in an array of SCNNodes
    func addChildNodes(_ nodes: [SCNNode]) {
        for node in nodes {
            self.addChildNode(node)
        }
    }
}
