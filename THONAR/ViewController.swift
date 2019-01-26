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
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var smallAlertIsDisplayed: Bool = false
    var largeAlertIsDisplayed: Bool = false

    @IBOutlet weak var menuButton: UIButton!
    
    @IBOutlet var sceneView: ARSCNView!
    
    // Crashes when initial mode is set to GameMode()
    var arMode: Mode = Mode() {
        didSet {
            // Update view
            if oldValue.description != "Mode" {
                oldValue.clean()
                reloadView()
                arMode.updateView()
            }
        }
    }
    
    var resources = NSMutableArray(array: []) {
        didSet {
            //print("viewController resources set")
        }
    }
    
    var effect:UIVisualEffect!
    
    private lazy var menuViewController: MenuViewController = {
        let storyBoard = UIStoryboard(name: "Main", bundle: Bundle.main)
        
        // Set the viewController to a specific viewController from the Storyboard
        // Choose which menu to configure
        var viewController = storyBoard.instantiateViewController(withIdentifier: "FinalRolloutMenuStoryboard") as! FinalRolloutMenuViewController
        
        viewController.menuDelegate = self
        viewController.sceneView = sceneView
        viewController.resourceGroup = resources
        self.add(asChildViewController: viewController, animated: true)
        
        return viewController
    }()
    
    private lazy var largeMessageViewController: LargeMessageViewController = {
        let storyBoard = UIStoryboard(name: "Main", bundle: Bundle.main)
        
        // Set the viewController to a specific viewController from the Storyboard
        // Choose which menu to configure
        var viewController = storyBoard.instantiateViewController(withIdentifier: "LargeMessageAlertStoryboard") as! LargeMessageViewController
        
        self.add(asChildViewController: viewController, animated: true)
        
        return viewController
    }()
    
    private lazy var smallMessageViewController: SmallMessageViewController = {
        let storyBoard = UIStoryboard(name: "Main", bundle: Bundle.main)
        
        // Set the viewController to a specific viewController from the Storyboard
        // Choose which menu to configure
        var viewController = storyBoard.instantiateViewController(withIdentifier: "SmallMessageAlertStoryboard") as! SmallMessageViewController
        
        self.add(asChildViewController: viewController, animated: true)
        
        return viewController
    }()
    
    func add(asChildViewController viewController: UIViewController, animated: Bool) {
        addChild(viewController)
        
        DispatchQueue.main.async {
            self.view.addSubview(viewController.view)
            
            viewController.view.frame = self.view.bounds
            viewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            viewController.didMove(toParent: self)
        }
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        //sceneView.showsStatistics = false
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        // Set text of modeLabel
        modeLabel?.text = mode
        modeLabel?.alpha = 0.0
        
        // Set default Mode
        arMode = GameMode(forView: sceneView, forResourceGroup: resources)
        
        let cloudkitHandler = CloudKitHandler()
        // Start querying data from server
        cloudkitHandler.fetchEstablishments()
        
        // Set up cloudkit subscriptions
        cloudkitHandler.setUpSubscription()
        
        // Set arMode's alert message delegate
        arMode.alertMessageDelegate = self
        
        // Make menu button a circle
        menuButton.layer.cornerRadius = menuButton.frame.width/2
    }
    
    func reloadView() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        //sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
        
        // Set text of modeLabel
        modeLabel?.text = mode
        
        // Set arMode's alert message delegate
        arMode.alertMessageDelegate = self
        
        // Make menu button a circle
        menuButton.layer.cornerRadius = menuButton.frame.width/2
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("viewWillAppear on main viewController called")
        arMode.viewWillAppear()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        //arMode.viewWillDisappear()
    }
    
    func setUpView(forMenuViewController viewController: MenuViewController, forButton pressedButton: MenuButton) {
        if pressedButton.arMode != nil {
            UIView.animate(withDuration: 0.3, delay: 0.0, options: UIView.AnimationOptions.curveEaseInOut, animations: {
                viewController.backgroundMenuView.blurRadius = 30
                viewController.backgroundMenuView.colorTintAlpha = 1.0
            }) { (success) in
                self.arMode = pressedButton.arMode!
                self.mode = pressedButton.mode
                self.modeLabel?.text = self.mode
                UIView.animate(withDuration: 0.4, delay: 0.05, options: UIView.AnimationOptions.curveEaseIn, animations: {
                    for button in viewController.buttons! {
                        button.alpha = 0
                    }
                    viewController.backgroundMenuView.blurRadius = 0
                    viewController.backgroundMenuView.colorTintAlpha = 0
                }, completion: { (success) in
                    self.remove(asChildViewController: viewController, animated: false)
                    for button in viewController.buttons! {
                        button.alpha = 1
                    }
                })
            }
        }
    }
    
    func dismissMenu(forViewController viewController: MenuViewController) {
        UIView.animate(withDuration: 0.3, animations: {
            viewController.menuView.alpha = 0
        }) { (success) in
            self.remove(asChildViewController: viewController, animated: false)
        }
        
    }
    
    // MARK: - ARSCNViewDelegate
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        return arMode.renderer(nodeFor: anchor)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        return arMode.renderer(updateAtTime:time)
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        arMode.didFailWithError(error) { (success) in
            reloadView()
            arMode.update()
        }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        arMode.sessionWasInterrupted(session)
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        arMode.sessionInterruptionEnded(session) { (success) in
            reloadView()
            arMode.update()
        }
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        arMode.session(forCamera: camera)
    }

//    func pageTurnAnimation() {
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

// MARK: - MenuViewControllerDelegate
extension ViewController: MenuViewControllerDelegate {
    func menuViewControllerMenuButtonTapped(forViewController viewController: MenuViewController, forSender sender: UIButton) {
        if let button = sender as? MenuButton {
            switch viewController.restorationIdentifier {
            case "InitialRolloutMenuStoryboard":
                // Set up view for Initial Rollout
                setUpView(forMenuViewController: viewController, forButton: button)
            case "FinalRolloutMenuStoryboard":
                // Set up view for Final Rollout
                setUpView(forMenuViewController: viewController, forButton: button)
            default:
                print("ERROR - viewController has no restorationIdentifier or \(String(describing: viewController.restorationIdentifier)) is not a switch case")
            }
        } else {
            dismissMenu(forViewController: viewController)
        }
    }
}

// MARK: - AlertMessageDelegate
extension ViewController: AlertMessageDelegate {
    
    // add(asChildViewController:,animated:) is done on the main thread, which means the implementation of the alertMessageViewController
    //  also needs to be on the main thread.
    func showAlert(forMessage message: String, ofSize size: AlertSize, withDismissAnimation animated: Bool) {
        switch size {
        case .large:
            add(asChildViewController: largeMessageViewController, animated: false)
            DispatchQueue.main.async {
                self.largeMessageViewController.message.text = message
                self.largeAlertIsDisplayed = true
                if animated {
                    self.dismissAlert(ofSize: size)
                    self.largeAlertIsDisplayed = false
                }
            }
        case .small:
            add(asChildViewController: smallMessageViewController, animated: false)
            DispatchQueue.main.async {
                self.smallMessageViewController.message.text = message
                self.smallAlertIsDisplayed = true
                if animated {
                    self.dismissAlert(ofSize: size)
                    self.smallAlertIsDisplayed = false
                }
            }
        }
        
    }
    
    func showAlert(forMessage message: String, ofSize size: AlertSize, withDismissAnimation animated: Bool, withDelay delay: Double) {
        switch size {
        case .large:
            DispatchQueue.main.async {
                self.largeMessageViewController.delay = delay
            }
            
            add(asChildViewController: largeMessageViewController, animated: false)
            
            DispatchQueue.main.async {
                self.largeMessageViewController.message.text = message
                self.largeAlertIsDisplayed = true
                if animated {
                    self.dismissAlert(ofSize: size)
                    self.largeAlertIsDisplayed = false
                    self.largeMessageViewController.delay = 0.0
                }
            }
        case .small:
            DispatchQueue.main.async {
                self.smallMessageViewController.delay = delay
            }
            
            add(asChildViewController: smallMessageViewController, animated: false)
            
            DispatchQueue.main.async {
                self.smallMessageViewController.message.text = message
                self.smallAlertIsDisplayed = true
                if animated {
                    self.dismissAlert(ofSize: size)
                    self.smallAlertIsDisplayed = false
                    self.smallMessageViewController.delay = 0.0
                }
            }
        }
    }
    
    func dismissAlert(ofSize size: AlertSize) {
        switch size {
        case .large:
            if largeAlertIsDisplayed {
                UIView.animate(withDuration: 0.2, delay: 2.0, options: UIView.AnimationOptions.curveEaseIn, animations: {
                    self.largeMessageViewController.view.alpha = 0
                }) { (success) in
                    self.remove(asChildViewController: self.largeMessageViewController, animated: false)
                    self.largeAlertIsDisplayed = false
                }
            }
        case .small:
            if smallAlertIsDisplayed {
                UIView.animate(withDuration: 0.2, delay: 2.0, options: UIView.AnimationOptions.curveEaseIn, animations: {
                    self.smallMessageViewController.view.alpha = 0
                }) { (success) in
                    self.remove(asChildViewController: self.smallMessageViewController, animated: false)
                    self.smallAlertIsDisplayed = false
                }
            }
        }
    }
    
}

