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

struct timerData {
    var recorder = AVAudioRecorder()
    var view = ARSCNView()
}

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
        print("Start")
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

    private func newBubble(forView view: ARSCNView) {
        if let frame = view.session.currentFrame {
            if bubblesOut <= 0 {
                return
            } else {
                let bubble = Bubble(forFrame: frame, forImageView: imageView)
                view.scene.rootNode.addChildNode(bubble)
                bubblesOut -= 1
                print(bubblesOut)
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
    
    var avgMic = [Float]()
    var lastdB = Float()
    
    @objc func timerCallBack(timer:Timer){
        let bubbleTimerData: timerData = timer.userInfo as! timerData
        let recorder = bubbleTimerData.recorder
        recorder.updateMeters()
        let avgPower: Float = 160+recorder.averagePower(forChannel: 0)
        if(!arReady){
            print("avgMic: \(avgMic)")
            avgMic.append(avgPower)
            avgNoise = avgMic.average
            lastdB = avgPower
        } else {
            print("avgPower: \(avgPower)     avgNoise: \(avgNoise)")
//            let minDiff: Float = setMinDiff(forlastdB: lastdB)
//            if avgPower >= lastdB + minDiff {
//                print("blow")
//                newBubble(forView: bubbleTimerData.view)
//                Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false, block: { (timer) in
//                    self.newBubble(forView: bubbleTimerData.view)
//                })
//            }
//            let minDiff: Float = setMinDiff(forlastdB: avgNoise!)
//            print(minDiff)
//            if avgPower > avgNoise! + minDiff {
//                //print("blow")
//                newBubble(forView: bubbleTimerData.view)
//                Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false, block: { (timer) in
//                    self.newBubble(forView: bubbleTimerData.view)
//                })
//            } else {
//                avgMic.append(avgPower)
//                avgNoise = avgMic.average
//            }
            if avgPower > 150 {
                newBubble(forView: bubbleTimerData.view)
                Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false, block: { (timer) in
                    self.newBubble(forView: bubbleTimerData.view)
                })
            }
//
//            } else if avgNoise! > 150 && avgPower > 136 {
//                newBubble(forView: bubbleTimerData.view)
//                Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false, block: { (timer) in
//                    self.newBubble(forView: bubbleTimerData.view)
//                })
//            }
        }
    }
    
    func setMinDiff(forlastdB dB: Float) -> Float {
        let min: Float = 120
        let diffForMin: Float = 20
        let max: Float = 146
        let diffForMax: Float = 8
        if dB < min {
            return diffForMin
        } else if dB > max {
            return diffForMax
        } else {
            // linear equation between values above
            /*
            let slope: Float = (diffForMax - diffForMin) / (max - min)
            let b: Float = diffForMax - (slope * max)
            return (slope * dB) + b
             */
            
            // logarithmic equation between values above
            let asymptoteX: Float = min - 1
            let B = diffForMin
            let logBase: Float = Float(M_E)
            let A = getA(forAsymptoteX: asymptoteX, forBase: logBase, forB: B, forPoint: (max, diffForMax))
            return (A * logC(val: (dB - asymptoteX), forBase: logBase)) + B
        }
    }
    
    func getA(forAsymptoteX asymptote: Float, forBase base: Float, forB B: Float, forPoint point: (Float, Float)) -> Float {
        return (point.1 - B) / logC(val: (point.0 - asymptote), forBase: base)
    }
    
    func logC(val: Float, forBase base: Float) -> Float {
        return log(val)/log(base)
    }
    
    func initView(forsceneView sceneView:ARSCNView){
        imageView = UIImageView(frame: CGRect(x: 0, y: sceneView.frame.size.height*0.5, width: sceneView.frame.size.width, height: sceneView.frame.size.height*0.5))
        imageView.contentMode = .scaleAspectFit
        imageView.image = #imageLiteral(resourceName: "white-bubble-wand")
        imageView.alpha = 0.9
        sceneView.addSubview(imageView)
    }
    
    public override init() {
        print("wrong init")
        super.init()
    }
    
    public init(forView view: ARSCNView) {
        print("right init")
        super.init()
        self.mySceneView = view
    }
    
    // MARK: - ARSCNViewDelegate
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


