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
    var arMode = TourMode()
    @IBOutlet weak var gameButton: MenuButton!
    @IBOutlet weak var storybookButton: MenuButton!
    @IBOutlet weak var menuButton: UIButton!
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var menuView: UIView!
    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    
    var effect:UIVisualEffect!
    
    @IBOutlet weak var modeLabel: UILabel?
    
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
        
        menuButton.layer.cornerRadius = menuButton.frame.width/2
    }
    
    func setButtonModes() {
        gameButton.mode = "Game"
        storybookButton.mode = "Storybook"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = arMode.configuration
        
        arMode.viewWillAppear(forView: sceneView)
        
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
        return arMode.render(nodeFor: anchor)
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
    
    func updateView() {
        modeLabel?.text = self.mode
    }
    
    func animateMenuIn() {
        self.view.addSubview(menuView)
        menuView.center = self.view.center
        
        menuView.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
        menuView.alpha = 0
        
        UIView.animate(withDuration: 0.4) {
            self.menuButton.isHidden = true
            self.visualEffectView.isHidden = false
            self.visualEffectView.effect = self.effect
            self.menuView.alpha = 1
            self.menuView.transform = CGAffineTransform.identity
        }
    }
    
    func animateMenuOut() {
        /*
        UIView.animate(withDuration: 0.3, animations: {
            self.menuView.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
            self.menuView.alpha = 0
            
            self.visualEffectView.effect = nil
            self.menuButton.isHidden = false
            
        }) { (success:Bool) in
            self.menuView.removeFromSuperview()
        }
         */
        UIView.animate(withDuration: 1.0, animations: {
            let animation = CATransition()
            animation.duration = 1.2
            animation.startProgress = 0.0
            animation.endProgress = 1.2
            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
            animation.type = CATransitionType(rawValue: "pageCurl")
            animation.subtype = CATransitionSubtype(rawValue: "fromRight")
            animation.isRemovedOnCompletion = false
            animation.fillMode = CAMediaTimingFillMode(rawValue: "extended")
            self.visualEffectView.layer.add(animation, forKey: "pageFlipAnimation")
            //var tempView = UIView()
            //tempView.backgroundColor = UIColor.blue
            //self.visualEffectView.addSubview(tempView)
        }) { (success:Bool) in
            self.menuView.alpha = 0
            self.visualEffectView.effect = nil
            self.menuButton.isHidden = false
            self.menuView.removeFromSuperview()
        }
    }
}
