//
//  BubbleView.swift
//  bubbles
//
//  Created by Ramin Ghorashi on 14/09/2016.
//  Copyright © 2016 Ramin Ghorashi. All rights reserved.
//

import SpriteKit

class BubbleView: SKSpriteNode {

    convenience init(bubbleSize: Double, bubbleNumber: Int) {
        self.init(imageNamed: "Bubble\(bubbleNumber)")
        
        size = CGSize(width: bubbleSize, height: bubbleSize)
        name = "bubble"
        
        let physicsBody = SKPhysicsBody(circleOfRadius: 1)
        physicsBody.isDynamic = true
        physicsBody.affectedByGravity = true
        self.physicsBody = physicsBody
    }    
}
