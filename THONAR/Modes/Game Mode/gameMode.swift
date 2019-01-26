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
    var recorder: AVAudioRecorder?
    var timer: Timer?
    var audioSession: AVAudioSession?
    
    override func clean() {
        recorder?.stop()
        recorder = nil
        timer?.invalidate()
        timer = nil
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        // initialize microphone for bubble
        initMicrophone()
        
        // Set up the view that calibrates the camera for the AR Session
        setUpCalibrationView()
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
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
            newBubble()
        }
    }

    private func newBubble() {
        if let frame = sceneView.session.currentFrame {
            if bubblesOut <= 0 {
                return
            } else {
                let bubble = Bubble(forFrame: frame, forImageView: imageView)
                sceneView.scene.rootNode.addChildNode(bubble)
                bubblesOut -= 1
            }
        }
    }
    
    private func setUpCalibrationView() {
        sceneView.isUserInteractionEnabled = false
        let calibrationView = calibrateView(frame: sceneView.superview!.bounds)
        calibrationView.alpha = 1
        sceneView.addSubview(calibrationView)
        UIView.animate(withDuration: 0.3) {
            calibrationView.alpha = 1
        }
        calibrationView.calibrationDone = { [weak self] done in
            if done {
                self?.initView()
                self?.arReady = true
                self!.sceneView.isUserInteractionEnabled = true
            }
        }
    }
    
    func initMicrophone() {
        audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession?.setCategory(.playAndRecord, mode: .default, options: [])
            try audioSession?.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {}
        
        /*
         * Main Thread Checker: UI API called on a background thread: -[UIApplication applicationState]
         * PID: 25982, TID: 8931726, Thread name: com.apple.CoreMotion.MotionThread, Queue name: com.apple.root.default-qos.overcommit, QoS: com.apple.CoreMotion.MotionThread
         */
        
        //let url = URL(fileURLWithPath:"/dev/null")
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let audioFilename = paths[0].appendingPathComponent("record.m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatAppleLossless),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue // max quality hex
        ]
        
        do {
            try recorder = AVAudioRecorder(url: audioFilename, settings: settings)
            recorder!.prepareToRecord()
            recorder!.isMeteringEnabled = true
            recorder?.prepareToRecord()
            recorder!.record()
            let bubbleTimerData = timerData(recorder: recorder!, view: sceneView)
            timer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(timerCallBack(timer:)), userInfo: bubbleTimerData, repeats: true)
        } catch {
            print("Error - recorder was not initialized")
        }
        
    }
    
    override func session(forCamera camera: ARCamera) {
        switch camera.trackingState {
        case .notAvailable:
            print("camera not available")
            break
        case .limited(.excessiveMotion):
            alertMessageDelegate?.showAlert(forMessage: "Excessive Motion - Please steady the camera", ofSize: AlertSize.large, withDismissAnimation: false)
            break
        case .limited(.initializing):
            if ARTrackingIsReady { ARTrackingIsReady = false }
            break
        case .limited(.insufficientFeatures):
            alertMessageDelegate?.showAlert(forMessage: "Insufficient features", ofSize: AlertSize.large, withDismissAnimation: false)
            break
        case .limited(.relocalizing):
            break
        case .normal:
            alertMessageDelegate?.dismissAlert(ofSize: AlertSize.large)
            ARTrackingIsReady = true
            break
        }
    }
    
    var avgMic = [Float]()
    var lastdB = Float()
    
    @objc func timerCallBack( timer: Timer) {
            let bubbleTimerData: timerData = timer.userInfo as! timerData
            let recorder = bubbleTimerData.recorder
            recorder.updateMeters()
            let avgPower: Float = 160+recorder.averagePower(forChannel: 0)
            if(!arReady){
                avgMic.append(avgPower)
                avgNoise = avgMic.average
                lastdB = avgPower
            } else {
                if avgPower > 150 {
                    newBubble()
                    Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false, block: { (timer) in
                        self.newBubble()
                    })
                }
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
    
    func initView() {
        imageView = UIImageView(frame: CGRect(x: 0, y: sceneView.frame.size.height*0.5, width: sceneView.frame.size.width, height: sceneView.frame.size.height*0.5))
        imageView.contentMode = .scaleAspectFit
        imageView.image = #imageLiteral(resourceName: "white-bubble-wand")
        imageView.alpha = 0.9
        sceneView.addSubview(imageView)
    }
    
    public override init() {
        super.init()
    }
    
    public init(forView view: ARSCNView, forResourceGroup resources: NSMutableArray) {
        super.init(forView: view, withDescription: "Game Mode")
        self.resources = resources
    }
    
    var ARTrackingIsReady:Bool = false {
        didSet{
            if ARTrackingIsReady {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "arTrackingReady"), object: nil)
            }
        }
    }
    
    // MARK: - ARSCNViewDelegate
    override func renderer(updateAtTime time: TimeInterval) {
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

func dbToGain(dB:Float) -> Float {
    return pow(2, dB/6)
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




