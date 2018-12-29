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


final class GameMode: Mode {

    var imageView:UIImageView!
    var bubblesOut = 1000
    var avgNoise:Float?
    var arReady = false
    
    override func viewWillAppear(forView view: ARSCNView) {
        super.viewWillAppear(forView: view)
        
        // initialize microphone for bubbl
        initMicrophone(forView: view)
        
        // Run the view's session
        view.session.run(self.configuration)
        
        // Set up the view that calibrates the camera for the AR Session
        setUpCalibrationView(forView: view)
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
            bubblesOut += 1
        } else {
            // make a new bubble if possible
            let arSceneView = sender.view as! ARSCNView
            newBubble(forView: arSceneView)
        }
    }

    override func renderer(nodeFor anchor: ARAnchor) -> SCNNode? {
        return nil
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

    private func newBubble(forView view: ARSCNView) {
        if let frame = view.session.currentFrame {
            if bubblesOut <= 0 {
                return
            } else {
                let bubble = Bubble(forFrame: frame, forImageView: imageView)
                view.scene.rootNode.addChildNode(bubble)
                setProgress(Double(bubblesOut)/2.0)
                bubblesOut -= 1
            }
        }
    }
    
    private func setUpCalibrationView(forView view: ARSCNView) {
        view.isUserInteractionEnabled = false
        let calibrationView = calibrateView(frame:view.bounds)
        view.addSubview(calibrationView)
        calibrationView.calibrationDone = { [weak self] done in
            if done {
                self?.initView(forsceneView: view)
                //self?.sceneView.debugOptions = []
                self?.arReady = true
                view.isUserInteractionEnabled = true
            }
        }
    }
    
    private func setProgress(_ progress:Double) {
        print(progress)
        let mutablePath = CGMutablePath()
        mutablePath.addRect(CGRect(x: 0, y: 0, width: imageView.frame.size.width, height: imageView.frame.size.height*CGFloat(progress)))
        let mask = CAShapeLayer()
        mask.path = mutablePath
        mask.fillColor = UIColor.white.cgColor
        imageView.layer.mask = mask
    }
    
    func initMicrophone(forView sceneView: ARSCNView) {
        var recorder: AVAudioRecorder
        let audioSession: AVAudioSession = AVAudioSession.sharedInstance()
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [])
            try audioSession.setActive(true)
            
        } catch {}
        
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
        //bubble.setProgress(Double(bubble.bubblesOut/2), forImageView: imageView)
        sceneView.addSubview(imageView)
    }
    
    public override init() {
        super.init()
    }
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


