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
    var record: Bool = true
    var recorder: AVAudioRecorder?
    var timer: Timer?
    var audioSession: AVAudioSession?
    
    override func clean() {
        print("gameMode cleaned")
        record = false
        recorder?.stop()
        recorder = nil
        //timer!.invalidate()
        //timer = nil
        do {
            //try audioSession?.setActive(false)
        } catch {
            print("error with deactivating the audioSession")
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        record = true
        // initialize microphone for bubble
        initMicrophone()
        
        // Set up the view that calibrates the camera for the AR Session
        print("Set up calibration view")
        setUpCalibrationView()
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        
        record = false
        print("record: \(record)")
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
                print(bubblesOut)
            }
        }
    }
    
    private func setUpCalibrationView() {
        sceneView.isUserInteractionEnabled = false
        print("sceneView.isUserInteractionEnabled: \(sceneView.isUserInteractionEnabled)")
        let calibrationView = calibrateView(frame: sceneView.superview!.bounds)
        calibrationView.alpha = 1
        sceneView.addSubview(calibrationView)
        UIView.animate(withDuration: 0.3) {
            calibrationView.alpha = 1
        }
        calibrationView.calibrationDone = { [weak self] done in
            if done {
                self?.initView()
                //self?.sceneView.debugOptions = []
                self?.arReady = true
                self!.sceneView.isUserInteractionEnabled = true
                //print("sceneView.isUserInteractionEnabled completion: \(self!.sceneView.isUserInteractionEnabled)")
            }
        }
    }
    
    func initMicrophone() {
        audioSession = AVAudioSession.sharedInstance()
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [])
            try audioSession!.setActive(true)
            
        } catch {}
        
        let url = URL(fileURLWithPath:"/dev/null")
        
        var settings = Dictionary<String, NSNumber>()
        settings[AVSampleRateKey] = 44100.0
        settings[AVFormatIDKey] = kAudioFormatAppleLossless as NSNumber
        settings[AVNumberOfChannelsKey] = 1
        settings[AVEncoderAudioQualityKey] = 0x7F //max quality hex
        
        do {
            try recorder = AVAudioRecorder(url: url, settings: settings)
            recorder!.prepareToRecord()
            recorder!.isMeteringEnabled = true
            recorder!.record()
            let bubbleTimerData = timerData(recorder: recorder!, view: sceneView)
            timer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: #selector(timerCallBack(timer:)), userInfo: bubbleTimerData, repeats: true)
            print("timer set")
        } catch {}
        
    }
    
    override func session(forCamera camera: ARCamera) {
        switch camera.trackingState {
        case .notAvailable:
            print("Not available")
            break
        case .limited(.excessiveMotion):
            print("Excessive motion")
            alertMessageDelegate?.showAlert(forMessage: "Excessive Motion - Please steady the camera", ofSize: AlertSize.large, withDismissAnimation: false)
            break
        case .limited(.initializing):
            print("initializing")
            if ARTrackingIsReady { ARTrackingIsReady = false }
            break
        case .limited(.insufficientFeatures):
            print("Insufficient features")
            alertMessageDelegate?.showAlert(forMessage: "Insufficient features", ofSize: AlertSize.large, withDismissAnimation: false)
            break
        case .limited(.relocalizing):
            print("Relocalizing")
            break
        case .normal:
            print("normal")
            alertMessageDelegate?.dismissAlert(ofSize: AlertSize.large)
            ARTrackingIsReady = true
            break
        }
    }
    
    var avgMic = [Float]()
    var lastdB = Float()
    
    @objc func timerCallBack( timer: Timer) {
        //print("timerCallBack \n record: \(record)")
        if record {
            let bubbleTimerData: timerData = timer.userInfo as! timerData
            let recorder = bubbleTimerData.recorder
            recorder.updateMeters()
            let avgPower: Float = 160+recorder.averagePower(forChannel: 0)
            if(!arReady){
                //print("avgMic: \(avgMic)")
                avgMic.append(avgPower)
                avgNoise = avgMic.average
                lastdB = avgPower
            } else {
                //print("avgPower: \(avgPower)     avgNoise: \(avgNoise)")
                if avgPower > 150 {
                    newBubble()
                    Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false, block: { (timer) in
                        self.newBubble()
                    })
                }
            }
        } else {
            timer.invalidate()
            print("Timer \(timer) invalidated")
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
    
    public init(forView view: ARSCNView, forResourceGroup resources: NSMutableDictionary) {
        super.init(forView: view, withDescription: "Game Mode")
        self.resources = resources
    }
    
    var ARTrackingIsReady:Bool = false {
        didSet{
            if ARTrackingIsReady {
                print("# of subviews: \(sceneView.subviews.count)")
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "arTrackingReady"), object: nil)
            }
        }
    }
    
    // MARK: - ARSCNViewDelegate
    override func renderer(updateAtTime time: TimeInterval) {
        //print("Renderer updateAtTime")
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




