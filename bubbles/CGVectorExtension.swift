//
//  PolarExtensions.swift
//  bubbles
//
//  Created by Ramin Ghorashi on 01/10/2016.
//  Copyright © 2016 Ramin Ghorashi. All rights reserved.
//

import CoreGraphics

extension CGVector {
    init(angle: Double, magnitude: Double) {
        self.init(dx: cos(angle) * magnitude, dy: sin(angle) * magnitude)
    }
}
