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

final class ViewController: UIViewController, ARSCNViewDelegate {
    
    // Would be an object that defines what that mode does, but for now, to test the passing of data
    //  from one ViewController to another, it is a simple string
    var mode: String = "Default"
    var arMode: Mode = TourMode() {
        didSet {
            // Update view
            print("update view to \(arMode)")
        }
    }

    @IBOutlet weak var menuButton: UIButton!
    
    @IBOutlet var sceneView: ARSCNView!
    
    var effect:UIVisualEffect!
    
    private lazy var menuViewController: MenuViewController = {
        let storyBoard = UIStoryboard(name: "Main", bundle: Bundle.main)
        
        var viewController = storyBoard.instantiateViewController(withIdentifier: "MenuStoryboard") as! MenuViewController
        
        viewController.menuDelegate = self
        
        self.add(asChildViewController: viewController, animated: true)
        
        return viewController
    }()
    
    func add(asChildViewController viewController: UIViewController, animated: Bool) {
        addChild(viewController)
        
        view.addSubview(viewController.view)
        
        viewController.view.frame = view.bounds
        viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        viewController.didMove(toParent: self)
    }
    
    func remove(asChildViewController viewController: UIViewController, animated: Bool) {
        viewController.willMove(toParent: self)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
    }
    
    @IBOutlet weak var modeLabel: UILabel?
    
    @IBAction func MenuButtonPressed(_ sender: Any) {
        add(asChildViewController: menuViewController, animated: true)
    }
//    @IBAction func dismissMenu(_ sender: Any) {
//        if let button = sender as? MenuButton {
//            self.mode = button.mode
//            self.arMode = button.arMode!
//        }
//        updateView()
//        animateMenuOut()
//    }
    
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
        
        // Set text of modeLabel
        modeLabel?.text = mode
        
        menuButton.layer.cornerRadius = menuButton.frame.width/2
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        print("appear")
        
        arMode.viewWillAppear(forView: sceneView)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func viewWillLayoutSubviews() {
        arMode.viewWillAppear(forView: sceneView)
    }
    
    
    // MARK: - ARSCNViewDelegate
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        return arMode.renderer(nodeFor: anchor)
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
    
//    func updateView() {
//        modeLabel?.text = self.mode
//        [self.view .setNeedsDisplay()]
//    }
    
//    func animateMenuIn() {
//        self.view.addSubview(menuView)
//        menuView.center = self.view.center
//
//        menuView.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
//        menuView.alpha = 0
//
//        UIView.animate(withDuration: 0.4) {
//            self.menuButton.isHidden = true
//            self.visualEffectView.isHidden = false
//            self.visualEffectView.effect = self.effect
//            self.menuView.alpha = 1
//            self.menuView.transform = CGAffineTransform.identity
//        }
//    }
    
//    func animateMenuOut() {
//        /*
//        UIView.animate(withDuration: 0.3, animations: {
//            self.menuView.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
//            self.menuView.alpha = 0
//
//            self.visualEffectView.effect = nil
//            self.menuButton.isHidden = false
//
//        }) { (success:Bool) in
//            self.menuView.removeFromSuperview()
//        }
//         */
//        UIView.animate(withDuration: 1.0, animations: {
//            let animation = CATransition()
//            animation.duration = 1.2
//            animation.startProgress = 0.0
//            animation.endProgress = 1.2
//            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
//            animation.type = CATransitionType(rawValue: "pageCurl")
//            animation.subtype = CATransitionSubtype(rawValue: "fromRight")
//            animation.isRemovedOnCompletion = false
//            animation.fillMode = CAMediaTimingFillMode(rawValue: "extended")
//            self.visualEffectView.layer.add(animation, forKey: "pageFlipAnimation")
//            //var tempView = UIView()
//            //tempView.backgroundColor = UIColor.blue
//            //self.visualEffectView.addSubview(tempView)
//        }) { (success:Bool) in
//            self.menuView.alpha = 0
//            self.visualEffectView.effect = nil
//            self.menuButton.isHidden = false
//            self.menuView.removeFromSuperview()
//        }
//    }
}


extension ViewController: MenuViewControllerDelegate {
    func menuViewControllerMenuButtonTapped(forViewController viewController: UIViewController, forSender sender: MenuButton) {
        print("called")
        if sender.arMode != nil {
            print("mode: \(sender.arMode)")
            self.arMode = sender.arMode!
            self.mode = sender.mode
            self.modeLabel?.text = self.mode
            remove(asChildViewController: viewController, animated: true)
            //animateMenuOut()
        }
    }
}
