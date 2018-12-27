//
//  gameMode.swift
//  THONAR
//
//  Created by Kevin Gardner on 12/16/18.
//  Copyright © 2018 THON. All rights reserved.
//

import Foundation
import ARKit
import SceneKit
import UIKit
import CoreAudio
import AVFoundation


class GameMode: Mode {

    var imageView:UIImageView!
    let bubble = Bubble()
    var avgNoise:Float?
    var bubblesOut = 1000
    var arReady = false



    override func renderer(nodeFor anchor: ARAnchor) -> SCNNode? {
        return nil
    }

    override func viewWillAppear(forView view: ARSCNView) {
        super.viewWillAppear(forView: view)
        initMicrophone(forView: view)

        // Run the view's session
        view.session.run(self.configuration)
        
        let calibrationView = calibrateView(frame:view.bounds)
        view.addSubview(calibrationView)
        calibrationView.calibrationDone = { [weak self] done in
            if done {
                self?.initView(forsceneView: view)
                //self?.sceneView.debugOptions = []
                self?.arReady = true
                
            }
            
        }
        
    }

    override func handleTap(sender: UITapGestureRecognizer) {
        let sceneView = sender.view as! SCNView
        let touchLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(touchLocation, options: nil)
        if !hitTest.isEmpty {
            // remove the tapped bubble
            let result = hitTest.first!
            let bubbleNode = result.node
            bubbleNode.removeFromParentNode()
        } else {
            // make a new bubble
            newBubble(forView: sceneView as! ARSCNView)
        }
    }
    
    func newBubble(forView sceneView: ARSCNView) {
        setProgress(Double(bubblesOut)/2.0)
        
        if bubblesOut <= 0 {
            return
            
        } else {
            bubblesOut -= 1
            
        }
        guard let frame = sceneView.session.currentFrame else {
            return
            
        }
        
        let mat = SCNMatrix4(frame.camera.transform)
        let dir = SCNVector3(-1 * mat.m31, -1 * mat.m32, -1 * mat.m33)
        
        let position = getNewPosition(forView: sceneView)
        let newBubble = bubble.clone()
        newBubble.position = position
        newBubble.scale = SCNVector3(1,1,1) * floatBetween(0.6, and: 1)
        
        
        let firstAction = SCNAction.move(by: dir.normalized() * 0.5 + SCNVector3(0,0.15,0), duration: 0.5)
        firstAction.timingMode = .easeOut
        let secondAction = SCNAction.move(by: dir + SCNVector3(floatBetween(-1.5, and:1.5 ),floatBetween(0, and: 1.5),0), duration: TimeInterval(floatBetween(5, and: 12)))
        secondAction.timingMode = .easeOut
        newBubble.runAction(firstAction)
        newBubble.runAction(secondAction, completionHandler: {
            newBubble.runAction(SCNAction.fadeOut(duration: 0), completionHandler: {
                DispatchQueue.main.async {
                    
                }
                newBubble.removeFromParentNode()
                
            })
            
        })
        sceneView.scene.rootNode.addChildNode(newBubble)
        
    }
    
    func getNewPosition(forView sceneView: ARSCNView) -> (SCNVector3) {
        if let frame = sceneView.session.currentFrame {
            let mat = SCNMatrix4(frame.camera.transform)
            let dir = SCNVector3(-1 * mat.m31, -1 * mat.m32, -1 * mat.m33)
            let pos = SCNVector3(mat.m41, mat.m42, mat.m43)
            return pos + SCNVector3(0,-0.07,0) + dir.normalized() * 0.5
            
        }
        return SCNVector3(0, 0, -1)
        
    }
    
    override func renderer(updateAtTime time: TimeInterval, forView sceneView: ARSCNView) {
        guard let frame = sceneView.session.currentFrame else {
            return
        }
        
        let mat = SCNMatrix4(frame.camera.transform)
        let pos = SCNVector3(mat.m41, mat.m42, mat.m43)
        
        
        for node in sceneView.scene.rootNode.childNodes {
            node.look(at: pos)
            
        }
        
    }
    
    func setProgress(_ progress:Double){
        print(progress)
        let mutablePath = CGMutablePath()
        mutablePath.addRect(CGRect(x: 0, y: 0, width: imageView.frame.size.width, height: imageView.frame.size.height*CGFloat(progress)))
        let mask = CAShapeLayer()
        mask.path = mutablePath
        mask.fillColor = UIColor.white.cgColor
        imageView.layer.mask = mask
        
    }
    
    func initMicrophone(forView sceneView: ARSCNView){
        var recorder: AVAudioRecorder
        let audioSession: AVAudioSession = AVAudioSession.sharedInstance()
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [])
            try audioSession.setActive(true)
            
        } catch {}
        
        func setProgress(_ progress:Double){
            print(progress)
            let mutablePath = CGMutablePath()
            mutablePath.addRect(CGRect(x: 0, y: 0, width: imageView.frame.size.width, height: imageView.frame.size.height*CGFloat(progress)))
            let mask = CAShapeLayer()
            mask.path = mutablePath
            mask.fillColor = UIColor.white.cgColor
            imageView.layer.mask = mask
            
        }
        
        let url = URL(fileURLWithPath:"/dev/null")
        
        var settings = Dictionary<String, NSNumber>()
        settings[AVSampleRateKey] = 44100.0
        settings[AVFormatIDKey] = kAudioFormatAppleLossless as NSNumber
        settings[AVNumberOfChannelsKey] = 1
        settings[AVEncoderAudioQualityKey] = 0x7F //max quality hex
        
        do {
            try recorder = AVAudioRecorder(url: url, settings: settings)
            recorder.prepareToRecord()
            recorder.isMeteringEnabled = true
            recorder.record()
            let bubbleTimerData = timerData(recorder: recorder, view: sceneView)
            _ = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(timerCallBack(timer:)), userInfo: bubbleTimerData, repeats: true)
            
        } catch {}
        
    }
    
    struct timerData {
        var recorder = AVAudioRecorder()
        var view = ARSCNView()
    }
    
    var avgMic = [Float]()
    
    @objc func timerCallBack(timer:Timer){
        let bubbleTimerData: timerData = timer.userInfo as! timerData
        let recorder = bubbleTimerData.recorder
        recorder.updateMeters()
        let avgPower: Float = 160+recorder.averagePower(forChannel: 0)
        if(!arReady){
            avgMic.append(avgPower)
            avgNoise = avgMic.average
            
        } else {
            
            if avgPower > 150 && avgNoise! < Float(120) {
                newBubble(forView: bubbleTimerData.view)
                Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false, block: { (timer) in
                    self.newBubble(forView: bubbleTimerData.view)
                    
                })
                
            } else if avgNoise! > 150 && avgPower > 136 {
                newBubble(forView: bubbleTimerData.view)
                Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false, block: { (timer) in
                    self.newBubble(forView: bubbleTimerData.view)
                    
                })
                
            }
            
        }
        
    }
    
    func initView(forsceneView sceneView:ARSCNView){
        imageView = UIImageView(frame: CGRect(x: 0, y: sceneView.frame.size.height*0.5, width: sceneView.frame.size.width, height: sceneView.frame.size.height*0.5))
        imageView.contentMode = .scaleAspectFit
        imageView.image = #imageLiteral(resourceName: "white-bubble-wand")
        imageView.alpha = 0.9
        setProgress(Double(bubblesOut/2))
        sceneView.addSubview(imageView)
    }
    
    public override init() {
        super.init()
        
    }
    
}


private func floatBetween(_ first: Float, and second: Float) -> Float {
    // random float between upper and lower bound (inclusive)
    return (Float(arc4random()) / Float(UInt32.max)) * (first - second) + second
    
}

// MARK: - SCNVector3 extension
extension SCNVector3 {
    func length() -> Float {
        return sqrtf(x * x + y * y + z * z)
        
    }
    
    func normalized() -> SCNVector3 {
        if self.length() == 0 {
            return self
            
        }
        return self / self.length()
        
    }
}

func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}

func * (left: SCNVector3, right: Float) -> SCNVector3 {
    return SCNVector3Make(left.x * right, left.y * right, left.z * right)
}

func / (left: SCNVector3, right: Float) -> SCNVector3 {
    return SCNVector3Make(left.x / right, left.y / right, left.z / right)
}

// MARK: - Array extension
extension Array where Element: FloatingPoint {
    /// Returns the sum of all elements in the array
    var total: Element {
        return reduce(0, +)
        
    }
    /// Returns the average of all elements in the array
    var average: Element {
        return isEmpty ? 0 : total / Element(count)
        
    }
}

func dbToGain(dB:Float) -> Float {
    return pow(2, dB/6)
}


