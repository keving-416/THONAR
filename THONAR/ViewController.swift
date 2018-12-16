//
//  ViewController.swift
//  THONAR - TEST
//
//  Created by Kevin Gardner on 11/27/18.
//  Copyright © 2018 THON. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import AVFoundation
import Foundation

class ViewController: UIViewController, ARSCNViewDelegate {
    
    // Would be an object that defines what that mode does, but for now, to test the passing of data
    //  from one ViewController to another, it is a simple string
    var mode: String = "Default"
    @IBOutlet weak var gameButton: MenuButton!
    @IBOutlet weak var storybookButton: MenuButton!
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var menuView: UIView!
    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    
    var effect:UIVisualEffect!
    
    @IBOutlet weak var modeLabel: UILabel?
    
    var videoPlayers = [String?:AVPlayer]()
    let resourceNames = [
        "FootballPepRally":("Football Pep Rally","mp4"),
        "THON2019Logo":("THON2019LogoARVideo","mp4"),
        "HumansUnited":("HumansUnitedARVideo","mov"),
        "LineDance":("Line Dance","mov"),
        "LineDanceFull":("Line Dance Full","MP4")
    ]
    
    @IBAction func MenuButtonPressed(_ sender: Any) {
        animateMenuIn()
    }
    @IBAction func dismissMenu(_ sender: Any) {
        if let button = sender as? MenuButton {
            self.mode = button.mode
        }
        updateView()
        animateMenuOut()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        visualEffectView.isHidden = true
        
        effect = visualEffectView.effect
        visualEffectView.effect = nil
        
        setButtonModes()
        
        // Set text of modeLabel
        modeLabel?.text = mode
    }
    
    func setButtonModes() {
        gameButton.mode = "Game"
        storybookButton.mode = "Storybook"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Define a variable to hold all your reference images
        let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: Bundle.main)
        
        // Create a session configuration
        let configuration = ARImageTrackingConfiguration()
        configuration.trackingImages = referenceImages!
        configuration.maximumNumberOfTrackedImages = 3
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // MARK: - ARSCNViewDelegate
    
    
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
        
        if let imageAnchor = anchor as? ARImageAnchor {
            let referenceImageName = imageAnchor.referenceImage.name
            node.name = referenceImageName
            let videoPlayer : AVPlayer = {
                // Load video from bundle
                guard let url = getURL(imageName: referenceImageName!) else {
                    
                    print("Could not find video file.")
                    
                    return AVPlayer()
                }
                
                return AVPlayer(url: url)
            }()
            videoPlayers[referenceImageName] = videoPlayer
            let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
            plane.firstMaterial?.diffuse.contents = videoPlayer
            videoPlayer.play()
            
            let planeNode = SCNNode(geometry: plane)
            planeNode.eulerAngles.x = -.pi / 2
            node.addChildNode(planeNode)
        }
        
        return node
    }
    
    func getURL(imageName: String) -> URL? {
        // if imageName exists in the videoPlayer dictionary
        if let resourceName = resourceNames[imageName] {
            return Bundle.main.url(forResource: resourceName.0, withExtension: resourceName.1)
        } else {
            print("Could not find image named \(imageName) in resourceNames")
            return nil
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
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
    
    func updateView() {
        modeLabel?.text = self.mode
    }
    
    func animateMenuIn() {
        self.view.addSubview(menuView)
        menuView.center = self.view.center
        
        menuView.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
        menuView.alpha = 0
        
        UIView.animate(withDuration: 0.4) {
            self.visualEffectView.isHidden = false
            self.visualEffectView.effect = self.effect
            self.menuView.alpha = 1
            self.menuView.transform = CGAffineTransform.identity
        }
    }
    
    func animateMenuOut() {
        UIView.animate(withDuration: 0.3, animations: {
            self.menuView.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
            self.menuView.alpha = 0
            
            self.visualEffectView.effect = nil
            
        }) { (success:Bool) in
            self.menuView.removeFromSuperview()
        }
    }
}

extension AVPlayer {
    var isPlaying: Bool {
        return (self.rate != 0 && self.error == nil)
    }
}
