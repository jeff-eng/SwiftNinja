//
//  GameScene.swift
//  Project17
//
//  Created by Jeffrey Eng on 8/11/16.
//  Copyright (c) 2016 Jeffrey Eng. All rights reserved.
//

import SpriteKit
import AVFoundation

enum SequenceType: Int {
    case OneNoBomb, One, TwoWithOneBomb, Two, Three, Four, Chain, FastChain
}

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
    
    // Bomb sound effect
    var bombSoundEffect: AVAudioPlayer!
    
    // Array to track enemies currently active in the scene
    var activeEnemies = [SKSpriteNode]()
    
    var popupTime = 0.9 //amt of time to wait between last enemy destroyed and new one created
    var sequence: [SequenceType]! //an array of our SequenceType enum that defines what enemies to create
    var sequencePosition = 0 //where we are right now in the game
    var chainDelay = 3.0 //how long to wait before creating a new enemy when sequence type is .Chain or .FastChain.
    var nextSequenceQueued = true //used to keep track of when all enemies are destroyed and we're ready to create more
    
    
    
    
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
        
        sequence = [.OneNoBomb, .OneNoBomb, .TwoWithOneBomb, .TwoWithOneBomb, .Three, .One, .Chain]
        
        for _ in 0 ... 1000 {
            let nextSequence = SequenceType(rawValue: RandomInt(min: 2, max: 7))!
            sequence.append(nextSequence)
        }
        
        RunAfterDelay(2) { [unowned self] in
            self.tossEnemies()
        }
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
        
        let nodes = nodesAtPoint(location)
        
        for node in nodes {
            if node.name == "enemy" {
                // 1) Create a particle effect over the penguin
                let emitter = SKEmitterNode(fileNamed: "sliceHitEnemy")!
                emitter.position = node.position
                addChild(emitter)
                
                // 2) Clear its node name so that it can't be swiped repeatedly
                node.name = ""
                
                // 3) Disable the dynamic  of its physics body so that it doesn't carry on falling
                node.physicsBody!.dynamic = false
                
                // 4) Make the penguin scale out and fade out at the same time
                let scaleOut = SKAction.scaleTo(0.001, duration: 0.2)
                let fadeOut = SKAction.fadeOutWithDuration(0.2)
                let group = SKAction.group([scaleOut, fadeOut])
                
                // 5) After making the penguin scale out and fade out, we should remove it from the scene
                let seq = SKAction.sequence([group, SKAction.removeFromParent()])
                node.runAction(seq)
                
                // 6) Add one to the player's score
                score += 1
                
                // 7) Remove the enemy from our activeEnemies array
                let index = activeEnemies.indexOf(node as! SKSpriteNode)
                activeEnemies.removeAtIndex(index!)
                
                // 8) Play a sound so the player knows they hit the penguin
                runAction(SKAction.playSoundFileNamed("whack.caf", waitForCompletion: false))
            } else if node.name == "bomb" {
                let emitter = SKSpriteNode(fileNamed: "sliceHitBomb")!
                emitter.position = node.position
                addChild(emitter)
                
                node.name = ""
                node.parent!.physicsBody!.dynamic = false
                
                let scaleOut = SKAction.scaleTo(0.001, duration: 0.2)
                let fadeOut = SKAction.fadeOutWithDuration(0.2)
                let group = SKAction.group([scaleOut, fadeOut])
                
                let seq = SKAction.sequence([group, SKAction.removeFromParent()])
                node.runAction(seq)
                
                let index = activeEnemies.indexOf(node as! SKSpriteNode)!
                activeEnemies.removeAtIndex(index)
                
                runAction(SKAction.playSoundFileNamed("explosion.caf", waitForCompletion: false))
                endGame(triggeredByBomb: true)
            }
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
        if activeEnemies.count > 0 {
            for node in activeEnemies {
                if node.position.y < -140 {
                    node.removeAllActions()
                    
                    if node.name == "enemy" {
                        node.name = ""
                        subtractLife()
                        
                        node.removeFromParent()
                        
                        if let index = activeEnemies.indexOf(node) {
                            activeEnemies.removeAtIndex(index)
                        }
                    } else if node.name == "bombContainer" {
                        node.name = ""
                        node.removeFromParent()
                        
                        if let index = activeEnemies.indexOf(node) {
                            activeEnemies.removeAtIndex(index)
                        }
                    }
                }
            }
        } else {
            if !nextSequenceQueued {
                RunAfterDelay(popupTime) { [unowned self] in
                    self.tossEnemies()
                }
                
                nextSequenceQueued = true
            }
        }
        
        var bombCount = 0
        
        for node in activeEnemies {
            if node.name == "bombContainer" {
                bombCount += 1
                break
            }
        }
        
        if bombCount == 0 {
            // no bombs - stop the fuse sound!
            if bombSoundEffect != nil {
                bombSoundEffect.stop()
                bombSoundEffect = nil
            }
        }
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
            // 1) Create a new SKSpriteNode that will hold the fuse and the bomb image as children, setting its Z position to be 1.
            enemy = SKSpriteNode()
            enemy.zPosition = 1
            enemy.name = "bombContainer"
            
            // 2) Create the bomb image, name it "bomb" and add it to the container.
            let bombImage = SKSpriteNode(imageNamed: "sliceBomb")
            bombImage.name = "bomb"
            enemy.addChild(bombImage)
            
            // 3) If the bomb fuse sound effect is playing, stop it and destroy it.
            if bombSoundEffect != nil {
                bombSoundEffect.stop()
                bombSoundEffect = nil
            }
            
            // 4) Create a new bomb fuse sound effect, then play it.
            let path = NSBundle.mainBundle().pathForResource("sliceBombFuse.caf", ofType: nil)!
            let url = NSURL(fileURLWithPath: path)
            let sound = try! AVAudioPlayer(contentsOfURL: url)
            bombSoundEffect = sound
            sound.play()
            
            // 5) Create a particle emitter node, position it so that it's at the end of the bomb image's fuse, and add it to the container.
            let emitter = SKEmitterNode(fileNamed: "sliceFuse")!
            emitter.position = CGPoint(x: 76, y: 64)
            enemy.addChild(emitter)
            
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
    
    func tossEnemies() {
        popupTime *= 0.991
        chainDelay *= 0.99
        physicsWorld.speed *= 1.02
        
        let sequenceType = sequence[sequencePosition]
        
        switch sequenceType {
        case .OneNoBomb:
            createEnemy(forceBomb: .Never)
            
        case .One:
            createEnemy()
            
        case .TwoWithOneBomb:
            createEnemy(forceBomb: .Never)
            createEnemy(forceBomb: .Always)
            
        case .Two:
            for _ in 1...2 {
                createEnemy()
            }
            
        case .Three:
            for _ in 1...3 {
                createEnemy()
            }
        
        case .Four:
            for _ in 1...4 {
                createEnemy()
            }
        
        case .Chain:
            createEnemy()
            
            RunAfterDelay(chainDelay / 5.0) { [unowned self] in self.createEnemy() }
            RunAfterDelay(chainDelay / 5.0 * 2) { [unowned self] in self.createEnemy() }
            RunAfterDelay(chainDelay / 5.0 * 3) { [unowned self] in self.createEnemy() }
            RunAfterDelay(chainDelay / 5.0 * 4) { [unowned self] in self.createEnemy() }

        case .FastChain:
            createEnemy()
            
            RunAfterDelay(chainDelay / 10.0) { [unowned self] in self.createEnemy() }
            RunAfterDelay(chainDelay / 10.0 * 2) { [unowned self] in self.createEnemy() }
            RunAfterDelay(chainDelay / 10.0 * 3) { [unowned self] in self.createEnemy() }
            RunAfterDelay(chainDelay / 10.0 * 4) { [unowned self] in self.createEnemy() }
        }
        
        sequencePosition += 1
        
        nextSequenceQueued = false
        
    }
    
    func subtractLife() {
        // subtract 1 from lives property when penguin falls off screen w/out being sliced
        lives -= 1
        
        // Play sound to denote life being lost
        runAction(SKAction.playSoundFileNamed("wrong.caf", waitForCompletion: false))
        
        var life: SKSpriteNode
        
        // update the images in the liveImages array so correct number are crossed off
        if lives == 2 {
            life = livesImages[0]
        } else if lives == 1 {
            life = livesImages[1]
        } else {
            life = livesImages[2]
            endgame(triggeredByBomb: false)
        }
        
        // Using SKTexture to modify contents of Sprite without having to recreate it
        life.texture = SKTexture(imageNamed: "sliceLifeGone")
        
        // Scale the life being lost to slightly larger, then scale back down
        life.xScale = 1.3
        life.yScale = 1.3
        life.runAction(SKAction.scaleTo(1, duration: 0.1))
    }
}
