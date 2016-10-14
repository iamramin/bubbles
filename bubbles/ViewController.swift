//
//  ViewController.swift
//  bubbles
//
//  Created by Ramin Ghorashi on 10/09/2016.
//  Copyright © 2016 Ramin Ghorashi. All rights reserved.
//

import UIKit
import SpriteKit

class ViewController: UIViewController, UICollisionBehaviorDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let spriteView = view as! SKView;
        
        #if DEBUG
        spriteView.showsDrawCount = true;
        spriteView.showsNodeCount = true;
        spriteView.showsFPS = true;
        #endif
        
        spriteView.presentScene(BubbleScene(size: spriteView.bounds.size))
    }
    
    override var shouldAutorotate:Bool {
        get {
            return false
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

