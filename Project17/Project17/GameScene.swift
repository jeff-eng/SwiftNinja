//
//  GameScene.swift
//  Project17
//
//  Created by Jeffrey Eng on 8/11/16.
//  Copyright (c) 2016 Jeffrey Eng. All rights reserved.
//

import SpriteKit

enum ForceBomb {
    case Never, Always, Default
}

class GameScene: SKScene {
    
    // Score related properties
    var gameScore: SKLabelNode!
    var score: Int = 0 {
        didSet {
            gameScore.text = "Score: \(score)"
        }
    }
    
    var livesImages = [SKSpriteNode]()
    var lives = 3
    
    // Initialize the slice shape properties
    var activeSliceBG: SKShapeNode!
    var activeSliceFG: SKShapeNode!
    
    // Store swipe points
    var activeSlicePoints = [CGPoint]()
    
    // Swoosh sound
    var swooshSoundActive = false
    
    // Array to track enemies currently active in the scene
    var activeEnemies = [SKSpriteNode]()
    
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
        super.touchesBegan(touches, withEvent: event)
        
        // 1) Remove all existing points in the activeSlicePoints array, because we're starting fresh
        activeSlicePoints.removeAll(keepCapacity: true)
        
        // 2) Get the touch location and add it to the activeSlicePoints array
        if let touch = touches.first {
            let location = touch.locationInNode(self)
            activeSlicePoints.append(location)
            
            // 3) Call the (As yet unwritten) redrawActiveSlice() method to clear the slice shapes
            redrawActiveSlice()
            
            // 4) Remove any actions that are currently attached to the slice shapes.  This will be important if they are in the middle of a fadeOutWithDuration() action
            activeSliceBG.removeAllActions()
            activeSliceFG.removeAllActions()
            
            // 5) Set both slice shapes to have an alpha value of 1 so they are fully visible.
            activeSliceBG.alpha = 1
            activeSliceFG.alpha = 1
        }
    }
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        // Get the first touch object
        guard let touch = touches.first else { return }
        
        // Store the location where user touched
        let location = touch.locationInNode(self)
        
        // Add location where in the scene the user touched to the activeSlicePoints array
        activeSlicePoints.append(location)
        
        // Redraw the slice shape
        redrawActiveSlice()
        
        // If swooshSoundActive is not false, play the swoosh sound
        if !swooshSoundActive {
            playSwooshSound()
        }
    }
    
    // This method gets called when user finishes touching the screen
    override func touchesEnded(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        // Make the slice shapes fade out
        activeSliceBG.runAction(SKAction.fadeOutWithDuration(0.25))
        activeSliceFG.runAction(SKAction.fadeOutWithDuration(0.25))
        
    }
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        if let touches = touches {
            touchesEnded(touches, withEvent: event)
        }
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
        for i in 0 ..< 3 {
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
        // Create an SKShapeNode instance for the activeSliceBG property
        activeSliceBG = SKShapeNode()
        // Set the z-position to 2 to make sure the slices are at top of z-position stack
        activeSliceBG.zPosition = 2
        
        // Create an SKShapeNode instance for the activeSliceFG property
        activeSliceFG = SKShapeNode()
        // Set the z-position
        activeSliceFG.zPosition = 2
        
        // Set the stroke color and line width of activeSliceBG
        activeSliceBG.strokeColor = UIColor(red: 1, green: 0.9, blue: 0, alpha: 1)
        activeSliceBG.lineWidth = 9
        
        // Set the stroke color and line width of activeSliceFG
        activeSliceFG.strokeColor = UIColor.whiteColor()
        activeSliceFG.lineWidth = 5
        
        // Add the nodes to SKShapeNode objects to the Game Scene as child nodes
        addChild(activeSliceBG)
        addChild(activeSliceFG)
    
    }
    
    func redrawActiveSlice() {
        // 1) If we have fewer than two points in our array, we don't have enough data to draw a line so it needs to clear the shapes and exit the method
        if activeSlicePoints.count < 2 {
            activeSliceBG.path = nil
            activeSliceFG.path = nil
            return
        }
        
        // 2) If we have more than 12 slice points in our array, we need to remove the oldest ones until we have at most 12 - this stops the swipe shapes from becoming too long.
        while activeSlicePoints.count > 12 {
            activeSlicePoints.removeAtIndex(0)
        }
        
        // 3) It needs to start its line at the position of the first swipe point, then go through each of the others drawing lines to each point.
        let path = UIBezierPath()
        path.moveToPoint(activeSlicePoints[0])
        
        for i in 1 ..< activeSlicePoints.count {
            path.addLineToPoint(activeSlicePoints[i])
        }
        // 4) Finally, it needs to update the slice shape paths so they get drawn using their designs - i.e., line width and color
        activeSliceBG.path = path.CGPath
        activeSliceFG.path = path.CGPath
    }
    
    func playSwooshSound() {
        // Set the property to true
        swooshSoundActive = true
        
        // Create a random number (this random number method is in the Helper.swift file) and use string interpolation to select the sound file name and save it to a constant
        let randomNumber = RandomInt(min: 1, max: 3)
        let soundName = "swoosh\(randomNumber).caf"
        
        // Store sound file
        let swooshSound = SKAction.playSoundFileNamed(soundName, waitForCompletion: true)
        
        // Run the sound file and then set the swoosh sound property to false after sound played
        runAction(swooshSound) { [unowned self] in
            self.swooshSoundActive = false
        }
    }
    
    func createEnemy(forceBomb forceBomb: ForceBomb = .Default) {
        var enemy: SKSpriteNode
        
        //Create random integer that determines what type of enemy is created
        var enemyType = RandomInt(min: 0, max: 6)
        
        if forceBomb == .Never {
            enemyType = 1
        } else if forceBomb == .Always {
            enemyType = 0
        }
        
        // Zero will be considered a bomb
        if enemyType == 0 {
            // insert bomb code here
        } else {
            // Create Sprite node instance
            enemy = SKSpriteNode(imageNamed: "penguin")
            // Play sound
            runAction(SKAction.playSoundFileNamed("launch.caf", waitForCompletion: false))
            // Assign name to the sprite node created
            enemy.name = "enemy"
        }
        
        // Position code
        // 1) Give the enemy a random position off the bottom edge of the screen
        let randomPosition = CGPoint(x: RandomInt(min: 64, max: 960), y: -128)
        
        // 2) Create a random angular velocity, which is how fast something should spin
        let randomAngularVelocity = CGFloat(RandomInt(min: -6, max: 6)) / 2.0
        var randomXVelocity = 0
        
        // 3) Create a random X velocity (how far to move horizontally) that takes into account the enemy's position
        if randomPosition.x < 256 {
            randomXVelocity = RandomInt(min: 8, max: 15)
        } else if randomPosition.x < 512 {
            randomXVelocity = RandomInt(min: 3, max: 5)
        } else if randomPosition.x < 768 {
            randomXVelocity = -RandomInt(min: 3, max: 5)
        } else {
            randomXVelocity = -RandomInt(min: 8, max: 15)
        }
        
        // 4) Create a random Y velocity just to make things fly at different speeds
        let randomYVelocity = RandomInt(min: 24, max: 32)
        
        // 5) Give all enemies a circular physics body where the collisionBitMask is set to 0 so they don't collide
        enemy.physicsBody = SKPhysicsBody(circleOfRadius: 64)
        enemy.physicsBody!.velocity = CGVector(dx: randomXVelocity * 40, dy: randomYVelocity * 40)
        enemy.physicsBody!.angularVelocity = randomAngularVelocity
        enemy.physicsBody!.collisionBitMask = 0
        
        // Add the Sprite node as a child to the Game Scene
        addChild(enemy)
        // Add the sprite node to the array of active enemies that we are keeping track of
        activeEnemies.append(enemy)
        
    }
}
