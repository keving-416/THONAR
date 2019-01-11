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
import CloudKit


struct resource {
    let image: URL
    let video: URL
}

/// Default mode to be subclassed for specific types of modes
class Mode {
    var configuration: ARWorldTrackingConfiguration
    var videoPlayers = [String?:AVPlayer]()
    let sceneView: ARSCNView
    var resources: NSMutableDictionary? {
        didSet {
            //updateForNewResources()
            print("resources has been updated \(resources)")
        }
    }
    let description: String
    var alertMessageDelegate: AlertMessageDelegate?
    
    
    // Override in subclasses
    func session(forCamera camera: ARCamera) {
        
    }
    
    // Override in subclasses
    func updateForNewResources() {
        
    }
    
    func viewWillAppear() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
        print("gestureRecognizer should have been added")
        //sceneView.isUserInteractionEnabled = true
        sceneView.session.run(self.configuration, options: [.resetTracking,.removeExistingAnchors])
    }
    
    // Override in subclasses
    @objc func handleTap(sender: UITapGestureRecognizer) {print("super view ran handle tap")}
    
    func updateView() {
        viewWillAppear()
        removeAllSubviews()
    }
    
    func viewWillDisappear() {
        // Pause the view's session
        sceneView.session.pause()
    }
    
    
    func removeAllSubviews() {
        let view = sceneView as UIView
        for view in view.subviews {
            print("view: \(view.description)")
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
                
                print("Could not find video file.")
                alertMessageDelegate?.showAlert(forMessage: "Could not find video file.", ofSize: AlertSize.large, withDismissAnimation: true)
                
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
    
    func createVideoPlayerPlaneNode(forURL url: URL, forResourceName resourceName: String, forImageAnchor imageAnchor: ARImageAnchor) -> SCNNode {
        let videoPlayer : AVPlayer = {
            //Load video from bundle
            print(url)
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            let destinationPath = documentsPath + "/filename.mp4"
            do {
                let data: Data = try Data(contentsOf: url)
                FileManager.default.createFile(atPath: destinationPath, contents: data, attributes: nil)
                let player = AVPlayer(url: URL(fileURLWithPath: destinationPath))
                print(player.status)
                return player
            } catch {
                print("error with video data/ url")
                alertMessageDelegate?.showAlert(forMessage: "Error with video data/ url", ofSize: AlertSize.large, withDismissAnimation: true)
                return AVPlayer()
            }
            
        }()
        videoPlayers[resourceName] = videoPlayer
        let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
        plane.firstMaterial?.diffuse.contents = videoPlayer
        videoPlayer.play()
        
        let planeNode = SCNNode(geometry: plane)
        planeNode.eulerAngles.x = -.pi / 2
        return planeNode
    }
    
    func fetchEstablishments() {
        print("begin")
        alertMessageDelegate?.showAlert(forMessage: "Querying Videos", ofSize: AlertSize.small, withDismissAnimation: true)
        let predicate = NSPredicate(value: true)
        let establishmentType = "videos"
        let query = CKQuery(recordType: establishmentType, predicate: predicate)
        // 4
        let queryOperation = CKQueryOperation()
        queryOperation.query = query
        queryOperation.resultsLimit = 2
        queryOperation.qualityOfService = .userInteractive
        queryOperation.recordFetchedBlock = { record in
            print(record.recordID.recordName)
            guard let imageAsset = record["Image"] as? CKAsset else {
                return
            }
            
            let newResource = resource(image: imageAsset.fileURL, video: (record["Video"] as? CKAsset)!.fileURL)
            print("video: \((record["Video"] as? CKAsset)!.fileURL)")
            print("image: \(imageAsset.fileURL)")
            print(self.resources)
            //let newResource = resource(image: URL(fileURLWithPath: record["imageURL"]!), video: URL(fileURLWithPath: record["videoURL"]!))
            self.resources![record["Name"]!] = newResource
        }
//        publicDatabase.perform(query, inZoneWith: nil) { (results, error) in
//            if let error = error {
//                DispatchQueue.main.async {
//                    //self.delegate?.errorUpdating(error as NSError)
//                    print("Cloud Query Error - Fetch Establishments: \(error)")
//                }
//                return
//            }
//
//            results?.forEach({ (record: CKRecord) in
//                print(record.recordID.recordName)
//                guard let imageAsset = record["Image"] as? CKAsset else {
//                    return
//                }
//
//                let newResource = resource(image: imageAsset.fileURL, video: (record["Video"] as? CKAsset)!.fileURL)
//                print("video: \((record["Video"] as? CKAsset)!.fileURL)")
//                print("image: \(imageAsset.fileURL)")
//                print(self.resources)
//                //let newResource = resource(image: URL(fileURLWithPath: record["imageURL"]!), video: URL(fileURLWithPath: record["videoURL"]!))
//                self.resources![record["Name"]!] = newResource
//            })
        queryOperation.queryCompletionBlock = { queryCursor, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.alertMessageDelegate?.showAlert(forMessage: "Cloud Query Error - Fetch Establishments: \(error)", ofSize: AlertSize.large, withDismissAnimation: true)
                }
            }
            DispatchQueue.main.async {
                //self.update()
                print("Query Complete")
                self.alertMessageDelegate?.showAlert(forMessage: "Query Complete", ofSize: AlertSize.large, withDismissAnimation: true)
            }
        }
        publicDatabase.add(queryOperation)
    }
    
    func update() {
        let referenceImages = getImages()
        self.configuration.detectionImages = referenceImages
        self.configuration.maximumNumberOfTrackedImages = 3
        
        // Run the view's session
        sceneView.session.run(self.configuration)
        print("Update")
    }
    
    // Override in subclasses
    func clean() {}
    
    func getImages() -> Set<ARReferenceImage>? {
        var set = Set<ARReferenceImage>()
        for resource in resources! {
            let imageData: Data
            do {
                print((resource.value as! resource).image)
                imageData = try Data(contentsOf: (resource.value as! resource).image)
            } catch {
                alertMessageDelegate?.showAlert(forMessage: "Error - imageData failed", ofSize: AlertSize.large, withDismissAnimation: true)
                return nil
            }
            
            let image = UIImage(data: imageData)
            print(image)
            
            let ciImage = CIImage(image: UIImage(data: imageData)!)
            let context = CIContext(options: nil)
            let cgImage = context.createCGImage(ciImage!, from: ciImage!.extent)
            let referenceImage = ARReferenceImage(cgImage!, orientation: CGImagePropertyOrientation.up, physicalWidth: 0.2)
            referenceImage.name = resource.key as? String
            set.insert(referenceImage)
        }
        return set
    }
    
    // MARK: - ARSCNViewDelegate
    // Override in subclasses
    func renderer(nodeFor anchor: ARAnchor) -> SCNNode? { return nil }
    
    //Override in subclasses
    func renderer(updateAtTime time:TimeInterval) {}
}
