//
//  BubbleScene.swift
//  bubbles
//
//  Created by Ramin Ghorashi on 18/09/2016.
//  Copyright © 2016 Ramin Ghorashi. All rights reserved.
//

import CoreMotion
import SpriteKit
import AVFoundation

class BubbleScene: SKScene {
    private var contentCreated = false
    private let cmm = CMMotionManager()
    
    var radius: Double!
    var background: SKSpriteNode!
    
    let bubbleSize = 200.0
    
    var bubblesReserve: [BubbleView] = []
    
    var burstEmitters: [SKEmitterNode] = []
    
    var gravityAngle = -Double.pi / 2
    let gravityMagnitude = 0.4
    let bubbleSpawnDelay = 0.1
    
    let popSound = SKAction.playSoundFileNamed("pop.wav", waitForCompletion: true)
    
    var recorder: AVAudioRecorder?
    
    override func didMove(to view: SKView) {
        if !contentCreated {
            createContent()
            contentCreated = true
        }
    }
    
    private func createContent() {
        radius = (hypo(x: size.width, y: size.height) + bubbleSize) * 0.5
        
        let hour = Calendar.current.component(.hour, from: Date())
        let image = hour >= 19 || hour < 7 ? "StarsBackground" : "Background"
            
        background = SKSpriteNode(imageNamed: image)
        background.size = CGSize(width: size.height / 4 * 3, height: size.height)
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background.zPosition = -1
        addChild(background)
        
        physicsWorld.gravity = CGVector(dx: 0, dy: gravityMagnitude)

        cmm.startDeviceMotionUpdates()
        
        let recorderSettings = [
            AVFormatIDKey : Int(kAudioFormatAppleIMA4),
            AVSampleRateKey : Int(44100),
            AVNumberOfChannelsKey : Int(1),
            AVLinearPCMBitDepthKey : Int(16),
            AVLinearPCMIsBigEndianKey : Int(false),
            AVLinearPCMIsFloatKey : Int(false)
        ]
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
            recorder = try AVAudioRecorder(url: URL(string: URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("tmp.caf").absoluteString)!, settings: recorderSettings)
            recorder?.isMeteringEnabled = true
            recorder?.record()
        } catch {
            print(error)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let touchLocation = touch.location(in: self)
            processTouch(touchLocation: touchLocation)
        }
    }

    private func processTouch(touchLocation: CGPoint) {
        if let node = nodes(at: touchLocation).filter({$0 is BubbleView}).first {
            let burst = getBurstEmitter()
            burst.position = node.position
            burst.particlePositionRange = CGVector(dx: 0.707 * node.frame.size.width, dy: 0.707 * node.frame.size.height)
            burst.targetNode = self
            burst.advanceSimulationTime(0.1)
            
            let startEmitting = SKAction.run { burst.particleBirthRate = 400 }
            let stopEmitting = SKAction.run {
                burst.particleBirthRate = 0
                self.burstEmitters.append(burst)
            }

            burst.run(SKAction.sequence([startEmitting, SKAction.wait(forDuration: 0.1), stopEmitting]))
            
            run(popSound)
            
            node.removeFromParent()
            bubblesReserve.append(node as! BubbleView)
        }
    }
    
    private func newBubble() -> BubbleView {
        let angle = randomDouble(min: gravityAngle - Double.pi / 2, max: gravityAngle + Double.pi / 2)
        
        let bubble = getBubble()
        bubble.position = CGPoint(x: radius * cos(angle) + Double(size.width) / 2, y: radius * sin(angle) + Double(size.height) / 2)
        bubble.physicsBody?.velocity = CGVector(angle: angle + Double.pi + randomDouble(min: -0.5, max: 0.5), magnitude: randomDouble(min: 20, max: 40))
        
        addChild(bubble)
        return bubble
    }
    
    private func getBurstEmitter() -> SKEmitterNode {
        if let burst = burstEmitters.popLast() {
            return burst
        }
        
        let burst = NSKeyedUnarchiver.unarchiveObject(withFile: Bundle.main.path(forResource: "BubbleBurst", ofType:"sks")!) as! SKEmitterNode
        burst.particleBirthRate = 0
        addChild(burst)
        
        return burst
    }
    
    var bubbleNumber = 4
    private func getBubble() -> BubbleView {
        if let bubble = bubblesReserve.popLast() {
            return bubble
        }
        
        if bubbleNumber < 4 {
            bubbleNumber += 1
        } else {
            bubbleNumber = 1
        }
        
        let scale = randomDouble(min: 0.3, max: 1.0)
        return BubbleView(bubbleSize: bubbleSize * scale, bubbleNumber: bubbleNumber)
    }
    
    private func positionBubble(bubble: SKNode) {

    }
    
    var lastBubbleAdd: Double?
    
    override func update(_ currentTime: TimeInterval) {
        if let motion = cmm.deviceMotion {
            gravityAngle = atan2(motion.gravity.y, motion.gravity.x)
            physicsWorld.gravity = CGVector(angle: gravityAngle + M_PI, magnitude: gravityMagnitude)
            for burst in burstEmitters {
                burst.xAcceleration = CGFloat(cos(gravityAngle) * 450.0)
                burst.yAcceleration = CGFloat(sin(gravityAngle) * 450.0)
            }
            for bubble in self.children.filter({$0 is BubbleView}).map({$0 as! BubbleView}) {
                bubble.run(SKAction.rotate(toAngle: CGFloat(gravityAngle + M_PI_2), duration: 0.3, shortestUnitArc: true))
            }
        }
        
        if let recorder = recorder {
            recorder.updateMeters()
            let level = recorder.averagePower(forChannel: 0)
            recorder.deleteRecording()
            
            if -level < 5.0 {
                let bubble = newBubble()
                bubble.physicsBody?.velocity = CGVector(angle: gravityAngle + M_PI, magnitude: randomDouble(min: 100, max: 300))
                lastBubbleAdd = currentTime
            }
            NSLog("\(level)")
        }
        
        if lastBubbleAdd == nil || currentTime - lastBubbleAdd! > bubbleSpawnDelay {
            let _ = newBubble()
            lastBubbleAdd = currentTime
        }
        
        super.update(currentTime)
    }
    
    override func didSimulatePhysics() {
        // Find and reset any bubbles that have move off the screen
        enumerateChildNodes(withName: "bubble") { (node, bool) in
            if self.hypo(x: node.position.x - self.size.width / 2, y: node.position.y - self.size.height / 2) > Double(self.radius) {
                node.removeFromParent()
                self.bubblesReserve.append(node as! BubbleView)
            }
        }
    }
    
    private func randomDouble(min: Double, max: Double) -> Double {
        return min + (Double(arc4random()) / Double(UINT32_MAX)) * (max - min)
    }
    
    private func hypo(x: Double, y: Double) -> Double {
        return sqrt(pow(x, 2) + pow(y, 2))
    }
    
    private func hypo(x: CGFloat, y: CGFloat) -> Double {
        return hypo(x: Double(x), y: Double(y))
    }
}
