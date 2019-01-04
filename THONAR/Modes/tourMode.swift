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

struct Establishment {
    let record: CKRecord
    let database: CKDatabase
}

struct resource {
    let image: URL
    let video: URL
}

var container: CKContainer = CKContainer.default()
public var publicDatabase: CKDatabase  = container.publicCloudDatabase

/// The mode that handles the functionality of the augmented reality tour during THON weekend
class TourMode: Mode {
    let resourceNames = [
        "FootballPepRally":("Football Pep Rally","mp4"),
        "THON2019Logo":("THON2019LogoARVideo","mp4"),
        "HumansUnited":("HumansUnitedARVideo","mov"),
        "LineDance":("Line Dance","mov"),
        "LineDanceFull":("Line Dance Full","MP4")
    ]
    
    var resources: [String: resource] = [:]
    
    var items: [Establishment] = []
    
    override func renderer(nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
        
        if let imageAnchor = anchor as? ARImageAnchor {
            // Do something when an image is detected
            let referenceImageName = imageAnchor.referenceImage.name
            print("referenceImageName: \(referenceImageName)")
            node.name = referenceImageName
            node.addChildNode(createVideoPlayerPlaneNode(forResourceName: referenceImageName!, forImageAnchor: imageAnchor))
            //node.addChildNode(createVideoPlayerPlaneNode(forResourceDictionary: resourceNames, forImageAnchor: imageAnchor, fromImageName: referenceImageName))
            }
        return node
    }
    
    func createVideoPlayerPlaneNode(forResourceName resourceName: String, forImageAnchor imageAnchor: ARImageAnchor) -> SCNNode {
        let videoPlayer : AVPlayer = {
            //Load video from bundle
            guard let url = resources[resourceName]?.video else {
                
                print("Could not find video file.")
                
                return AVPlayer()
                
            }
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
    
    override func viewWillAppear() {
        fetchEstablishments()
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    func getImages() -> Set<ARReferenceImage>? {
        var set = Set<ARReferenceImage>()
        for resource in resources {
            let imageData: Data
            do {
                imageData = try Data(contentsOf: resource.value.image)
            } catch {
                return nil
            }
            
            let image = UIImage(data: imageData)
            print(image)
            
            let ciImage = CIImage(image: UIImage(data: imageData)!)
            let context = CIContext(options: nil)
            let cgImage = context.createCGImage(ciImage!, from: ciImage!.extent)
            let referenceImage = ARReferenceImage(cgImage!, orientation: CGImagePropertyOrientation.up, physicalWidth: 0.2)
            referenceImage.name = resource.key
            set.insert(referenceImage)
        }
        return set
    }
    
    func fetchEstablishments() {
        print("begin")
        let predicate = NSPredicate(value: true)
        let establishmentType = "videos"
        let query = CKQuery(recordType: establishmentType, predicate: predicate)
        // 4
        publicDatabase.perform(query, inZoneWith: nil) { (results, error) in
            if let error = error {
                DispatchQueue.main.async {
                    //self.delegate?.errorUpdating(error as NSError)
                    print("Cloud Query Error - Fetch Establishments: \(error)")
                }
                return
            }
            
            self.items.removeAll(keepingCapacity: true)
            results?.forEach({ (record: CKRecord) in
                self.items.append(Establishment(record: record,
                                                database: publicDatabase))
                print(record.recordID.recordName)
                guard let imageAsset = record["Image"] as? CKAsset else {
                    return
                }
                
                let newResource = resource(image: imageAsset.fileURL, video: (record["Video"] as? CKAsset)!.fileURL)
                self.resources[record["Name"]!] = newResource
            })
            
            DispatchQueue.main.async {
                //self.delegate?.modelUpdated()
                self.update()
            }
        }
    }
    
    func update() {
        let referenceImages = getImages()
        self.configuration.detectionImages = referenceImages!
        self.configuration.maximumNumberOfTrackedImages = 3
        
        // Run the view's session
        sceneView.session.run(self.configuration)
        print("Update")
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
    
    public override init(forView view: ARSCNView) {
        super.init(forView: view)
    }
}

extension AVPlayer {
    var isPlaying: Bool {
        return (self.rate != 0 && self.error == nil)
    }
}
