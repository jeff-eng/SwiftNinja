//
//  GameScene.swift
//  Project17
//
//  Created by Jeffrey Eng on 8/11/16.
//  Copyright (c) 2016 Jeffrey Eng. All rights reserved.
//

import SpriteKit

class GameScene: SKScene {
    
    var gameScore: SKLabelNode!
    var score: Int = 0 {
        didSet {
            gameScore.text = "Score: \(score)"
        }
    }
    
    var livesImages = [SKSpriteNode]()
    var lives = 3
    
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
        // Set speed of gravity slightly slower than default
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
    
    func createScore() {
        // Create instance of label node and specify the text, alignment and font size
        gameScore = SKLabelNode(fontNamed: "Chalkduster")
        gameScore.text = "Score: 0"
        gameScore.horizontalAlignmentMode = .Left
        gameScore.fontSize = 48
        
        // Add label node to the scene
        addChild(gameScore)
        
        // Specify the position of the game score label
        gameScore.position = CGPoint(x: 8, y: 8)
    }
    
    func createLives() {
        for i in 0..<3 {
            // create instance of the sprite node
            let spriteNode = SKSpriteNode(imageNamed: "sliceLife")
            // position the sprite node
            spriteNode.position = CGPoint(x: CGFloat(834 + (i * 70)), y: 720)
            // add the sprite node as a child node to the scene
            addChild(spriteNode)
            
            // add the sprite node object to the array declared at the top of the class
            livesImages.append(spriteNode)
        }
    }
    
    func createSlices() {
        
    }
}
