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
    var videoNodes = [String?:(SCNNode,ARImageAnchor)]()
    let sceneView: ARSCNView
    var resources: NSMutableArray? {
        didSet {
            //updateForNewResources()
            print("resources has been updated ----- resources.count: \(String(describing: resources?.count))")
        }
    }
    let description: String
    var alertMessageDelegate: AlertMessageDelegate?
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
    
    func updateView() {
        removeAllSubviews()
        viewWillAppear()
    }
    
    func viewWillDisappear() {
        // Pause the view's session
        sceneView.session.pause()
    }
    
    
    func removeAllSubviews() {
        let view = sceneView as UIView
        for view in view.subviews {
            view.removeFromSuperview()
        }
    }
        
    public init() {
        self.configuration = ARWorldTrackingConfiguration()
        self.sceneView = ARSCNView()
        self.description = "Mode"
    }
    
    public init(forView view: ARSCNView, withDescription description: String = "Mode") {
        self.configuration = ARWorldTrackingConfiguration()
        self.sceneView = view
        self.description = description
    }
    
    // Creates a node that displays a video when a certain image is detected
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
    
    func getURL(forResourceDictionary resourceNames: [String: (String,String)], forImageName imageName: String) -> URL? {
        // if imageName exists in the videoPlayer dictionary
        if let resourceName = resourceNames[imageName] {
            return Bundle.main.url(forResource: resourceName.0, withExtension: resourceName.1)
        } else {
            print("Could not find image named \(imageName) in resourceNames")
            return nil
        }
    }
    
    func createVideoPlayerPlaneNode(forData data: Data, forResourceName resourceName: String, forImageAnchor imageAnchor: ARImageAnchor) -> SCNNode {
        let videoPlayer : AVPlayer = {
            //Load video from bundle
            print("create video player node for resourceName: \(resourceName)")
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let destinationPath = documentsPath + "/filename.mp4"
            FileManager.default.createFile(atPath: destinationPath, contents: data, attributes: nil)
            let player = AVPlayer(url: URL(fileURLWithPath: destinationPath))
            return player
        }()
        
        //videoPlayers[resourceName] = videoPlayer
        let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
        plane.firstMaterial?.diffuse.contents = videoPlayer
        videoPlayer.play()
        
        let planeNode = SCNNode(geometry: plane)
        planeNode.eulerAngles.x = -.pi / 2
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinishPlaying(_:)), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: (planeNode.geometry?.firstMaterial?.diffuse.contents as! AVPlayer).currentItem)
        //NotificationCenter.default.post(name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: videoPlayer.currentItem, userInfo: ["planeNode":planeNode])
        return planeNode
    }
    
    // Override in subclasses
    @objc func playerDidFinishPlaying(_ note: Notification) {
        print("Video Finished")
    }
    
    func update() {
        let referenceImages = getImages()
        self.configuration.detectionImages = referenceImages
        self.configuration.maximumNumberOfTrackedImages = 3
        
        // Run the view's session
        sceneView.session.run(self.configuration)
    }
    
    // Override in subclasses
    func clean() {}
    
    func getImages() -> Set<ARReferenceImage>? {
        var set = Set<ARReferenceImage>()
        
        // Safely unwrap resources
        guard let dataArray = resources else {
            return nil
        }
        
        // Loop through NSManagedObjects to create a set of reference images
        for resource in dataArray {
            
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
    
    //Override in subclasses
    func renderer(updateAtTime time:TimeInterval) {}
}
