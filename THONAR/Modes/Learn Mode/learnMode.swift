//
//  learnMode.swift
//  THONAR
//
//  Created by Isabelle Biase on 2/4/19.
//  Copyright © 2019 THON. All rights reserved.
//

import Foundation
import UIKit
import ARKit
import SceneKit

final class LearnMode: Mode {
    
    var placedDiamondAlready: Bool
    var noDiamondSelected: Bool
    var descImageView = UIImageView()
    
    public override init() {
        self.noDiamondSelected = true
        self.placedDiamondAlready = false
        super.init()
    }
    
    public init(forView view: ARSCNView) {
        self.noDiamondSelected = true
        self.placedDiamondAlready = false
        super.init(forView: view, withDescription: "Learn Mode")
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        print("Learn Mode viewWillAppear")
        self.noDiamondSelected = true
        self.placedDiamondAlready = false
        setUpConfiguration()
        configureLighting()
        displayInstructions()
    }
    
    private func setUpConfiguration() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
//        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        sceneView.session.run(configuration) // add the configuration
    }
    
    func configureLighting() {
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
    }
    
    func displayInstructions() {
        sceneView.
    }
    
    @objc override func handleTap(sender: UIGestureRecognizer) {
        print("Note: User tapped screen")
        
        let tapLocation = sender.location(in: sceneView)
        
        if (self.placedDiamondAlready) {
            print("Note: There was a diamond placed already")
            let diamondHitTestResults = sceneView.hitTest(tapLocation, options: [SCNHitTestOption.searchMode: 1])
            
            guard let hit = diamondHitTestResults.last else { return }
            
            // I think this might fix the fatal nil error i was getting sometimes when trying to select a diamond
            guard let hitName = hit.node.name else { return }
            print(hitName)
            
            
            if (hitName.range(of:"selected") == nil) {
                // if no other diamond is selected, select diamond that was hit
                if (self.noDiamondSelected) {
                    
                    // select diamond
                    hit.node.parent?.runAction(SCNAction.moveBy(x: 0, y: 0, z: 0.2, duration: 1))
                    
                    // add text node
                    addTextToDiamond(hit: hit, hitName: hitName)
                    
                    // add description
                    addDiamondDescription(hitName: hitName)
                    
                    self.noDiamondSelected = false
                    hit.node.name = hit.node.name! + " selected"
                }
            }
            else {
                // unselect diamond that was hit
                let endOfOriginalName = hit.node.name!.index(hit.node.name!.endIndex, offsetBy: -9)
                let rangeOfOriginalName = hit.node.name!.startIndex ..< endOfOriginalName
                hit.node.name = String(hit.node.name![rangeOfOriginalName])
                self.noDiamondSelected = true
                
                // Move diamond back
                hit.node.parent?.runAction(SCNAction.moveBy(x: 0, y: 0, z: -0.2, duration: 1))
                
                // Remove text from diamond
                hit.node.parent?.childNode(withName: "text", recursively: true)?.runAction(SCNAction.fadeOut(duration: 0.1), completionHandler: {hit.node.parent?.childNode(withName: "text", recursively: true)?.runAction(SCNAction.removeFromParentNode())})
                
                // Remove diamond description
                UIView.animate(withDuration: 1, animations: { self.descImageView.alpha = 0.0 })
            }
            
        }
        
        else {
            print("Note: There was no diamond placed yet")
            let planeHitTestResults = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
            
            guard let hitTestResult = planeHitTestResults.last else { return }
            let hitTransform = hitTestResult.worldTransform
            
            let x = hitTransform.columns.3.x
            let y = hitTransform.columns.3.y
            let z = hitTransform.columns.3.z
            
            createFDLogo(touch_x:x, touch_y:y, touch_z:z)
            self.placedDiamondAlready = true
            
            // Turn off feature points
            sceneView.debugOptions = []
            
            // Turn off plane detection
            let configuration = ARWorldTrackingConfiguration();
            configuration.planeDetection = []
            sceneView.session.run(configuration)
            
            // Remove all the horizontal plane nodes
            sceneView.scene.rootNode.enumerateChildNodes() {
                (node, stop) in
                
                if (node.name == "plane") {
                    node.removeFromParentNode()
                }
            }
            
            
        }
        
    } // end handleTap
    
    func addTextToDiamond(hit: SCNHitTestResult, hitName: String) {
        
        var imageName: String = ""
        
        switch hitName {
        case "Top":
            imageName = "courage.png"
        case "Left":
            imageName = "strength.png"
        case "Right":
            imageName = "wisdom.png"
        case "Bottom":
            imageName = "honesty.png"
        default:
            print("Didn't match any of the cases")
        }
        
        
        let textImage = UIImage(named: imageName)
        let textNode = SCNNode(geometry: SCNPlane(width: 1.05, height: 0.75))
        textNode.name = "text"
        textNode.geometry?.firstMaterial?.diffuse.contents = textImage
        textNode.scale = SCNVector3(x: 0.11, y: 0.11, z: 0.11)
        textNode.position = SCNVector3(x: 0, y: 0, z: 0.01)
        textNode.opacity = 0.0
        hit.node.parent?.addChildNode(textNode)
        textNode.runAction(SCNAction.fadeIn(duration: 1))
        
    } // end addTextToDiamond
    
        func addDiamondDescription(hitName: String){
            var imageName: String = ""
            
            switch hitName {
                case "Top":
                    imageName = "courage-desc"
                case "Left":
                    imageName = "strength-desc"
                case "Right":
                    imageName = "wisdom-desc"
                case "Bottom":
                    imageName = "honesty-desc"
                default:
                    print("Didn't match any of the cases")
            }
            print("THE HIT NAME WAS: ", hitName)
            print("THE NAME WAS: ", imageName)
            let descImage = UIImage(named: imageName)
            descImageView.image = descImage!
            descImageView.frame = CGRect(x: 32, y: 497, width: 310, height: 150)
            descImageView.contentMode = .scaleAspectFit
            descImageView.alpha = 0.0
            sceneView.addSubview(descImageView)
            descImageView.translatesAutoresizingMaskIntoConstraints = false
            
            descImageView.leadingAnchor.constraint(equalTo: sceneView.leadingAnchor, constant: 32).isActive = true
            descImageView.trailingAnchor.constraint(equalTo: sceneView.trailingAnchor, constant: -32).isActive = true
            descImageView.bottomAnchor.constraint(equalTo: sceneView.bottomAnchor, constant: 20).isActive = true
            descImageView.topAnchor.constraint(equalTo: sceneView.topAnchor, constant: 350).isActive = true
            
            UIView.animate(withDuration: 1, animations: { self.descImageView.alpha = 1.0 })
    
        } // end addDiamondDescription
    
    func createFDLogo(touch_x x: Float, touch_y y: Float, touch_z z: Float) {
        
        // Make parent node
        let fourDiamondsLogo = SCNNode()
        
        // Position parent node
        fourDiamondsLogo.position = SCNVector3(x, y + 0.3, z - 0.1)
        
        // Create four diamonds
        let topDiamond = createDiamond(name: "Top", parent: fourDiamondsLogo)
        let leftDiamond = createDiamond(name: "Left", parent: fourDiamondsLogo)
        let rightDiamond = createDiamond(name: "Right", parent: fourDiamondsLogo)
        let bottomDiamond = createDiamond(name: "Bottom", parent: fourDiamondsLogo)
        
        // Position four diamonds within parent node
        topDiamond.position = SCNVector3(0, 0.3, 0)
        leftDiamond.position = SCNVector3(-0.1, 0.15, 0)
        rightDiamond.position = SCNVector3(0.1, 0.15, 0)
        bottomDiamond.position = SCNVector3(0, 0, 0)
        
        // Rotate parent node so that it faces camera when placed
        fourDiamondsLogo.eulerAngles = SCNVector3(x: 0, y: sceneView.session.currentFrame!.camera.eulerAngles.y, z: 0)
        
        // Bounce In Effect
        let prevScale = fourDiamondsLogo.scale
        fourDiamondsLogo.scale = SCNVector3(0.01, 0.01, 0.01)
        let scaleAction = SCNAction.scale(to: CGFloat(prevScale.x), duration: 1.5)
        scaleAction.timingMode = .linear
        
        // Use a custom timing function
        scaleAction.timingFunction = { (p: Float) in
            return self.easeOutElastic(p)
        }
        
        // Add parent node to scene
        sceneView.scene.rootNode.addChildNode(fourDiamondsLogo)
        fourDiamondsLogo.runAction(scaleAction, forKey: "scaleAction")
        
    } // end createFDLogo
    
    // Timing function that has a "bounce in" effect
    func easeOutElastic(_ t: Float) -> Float {
        let p: Float = 0.3
        let x: Float = (t - (p / 4.0)) * (2.0 * Float.pi) / p
        let result = powf(2.0, -10*t) * sin(x) + 1.0
        return result
    }
    
    func createDiamond(name: String, parent: SCNNode) -> SCNNode {
        guard let diamondScene = SCNScene(named: "art.scnassets/ship.scn") else {
            return SCNNode()
        }
        
        let diamond: SCNNode = diamondScene.rootNode.childNode(withName: "diamondObject", recursively: true)!
        
        // Here I am naming each diamond "Top", "Bottom", "Left", or "Right"
        // This name is used later in the handleTap function (to know which word to display on the diamond)
        // When you tap on a diamond, the hit test is returning pCube1, the child of the diamondObject
        // That's why the name is given to the diamond's child node
        guard let pCube1 = diamond.childNodes.first else { return diamond }
        pCube1.name = name
        
        parent.addChildNode(diamond)
        
        return diamond
    } // end createDiamond
    
        override func renderer(nodeFor anchor: ARAnchor) -> SCNNode? {
            print("Note: found a plane")
//            print("SUUUUUUUUUUUURFS UP BRO ------------------------")
//            guard let planeAnchor = anchor as? ARPlaneAnchor else { return nil }
//
//            let width = CGFloat(planeAnchor.extent.x)
//            let height = CGFloat(planeAnchor.extent.z)
//            let plane = SCNPlane(width: width, height: height)
//
//            plane.materials.first?.diffuse.contents = UIColor.transparentLightBlue
//
//            let planeParentNode = SCNNode()
//            planeParentNode.name = "plane"
//            let planeNode = SCNNode(geometry: plane)
//
//            let x = CGFloat(planeAnchor.center.x)
//            let y = CGFloat(planeAnchor.center.y)
//            let z = CGFloat(planeAnchor.center.z)
//
//            planeNode.position = SCNVector3(x,y,z)
//            planeNode.eulerAngles.x = -.pi / 2
//
//            planeParentNode.addChildNode(planeNode)
//
//            return planeParentNode
            return SCNNode()
        } // end renderer
//
//    override func renderer(didAdd node: SCNNode, for anchor: ARAnchor) {
//        print("SURRRRRRFSSSSS UPPPP BROOOOOOOO++++++++++++++++++++++")
//    }
//
//    override func renderer(didUpdate node: SCNNode, for anchor: ARAnchor) {
//        print("i am here $$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$")
//    }
    
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
/* Old renderer functions */
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
    override func renderer(didAdd node: SCNNode, for anchor: ARAnchor) {
        print("Note: adding a plane")
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }

        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: width, height: height)

        plane.materials.first?.diffuse.contents = UIColor.transparentLightBlue

        let planeNode = SCNNode(geometry: plane)

        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)

        planeNode.position = SCNVector3(x,y,z)
        planeNode.eulerAngles.x = -.pi / 2

        node.addChildNode(planeNode)


    } // end renderer
    
    override func renderer(didUpdate node: SCNNode, for anchor: ARAnchor) {
        // 1
        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }

        // 2
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        plane.width = width
        plane.height = height

        // 3
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x, y, z)
        planeNode.name = "plane"

    } // end renderer

} // end LearnMode class

extension UIColor {
    open class var transparentLightBlue: UIColor {
        return UIColor(red: 90/255, green: 200/255, blue: 250/255, alpha: 0.50)
    }
}

