//
//  GameScene.swift
//  Project17
//
//  Created by Jeffrey Eng on 8/11/16.
//  Copyright (c) 2016 Jeffrey Eng. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    override func didMoveToView(view: SKView) {
        // Create instance of sprite node
        let background = SKSpriteNode(imageNamed: "sliceBackground")
        // Position sprite
        background.position = CGPoint(x: 512, y: 384)
        // Replace over scene
        background.blendMode = .Replace
        // Specify the z-position
        background.zPosition = -1
        // Add sprite node as child of the scene
        addChild(background)
        
        // Define gravity
        physicsWorld.gravity = CGVector(dx: 0, dy: -6)
        physicsWorld.speed = 0.85
        
        createScore()
        createLives()
        createSlices()
        
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {

        
    }
   
    override func update(currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
    }
}
