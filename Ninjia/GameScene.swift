//
//  GameScene.swift
//  Ninjia
//
//  Created by Rannie on 14/7/3.
//  Copyright (c) 2014年 Rannie. All rights reserved.
//

import SpriteKit

let projectileCategory : UInt32 = 0x1 << 0
let monsterCategory    : UInt32 = 0x1 << 1

// overload '%'
@infix func %(lhs: UInt32, rhs: Float) -> Float {
    return Float(lhs) % Float(rhs)
}
@infix func %(lhs: UInt32, rhs: Double) -> Double {
    return Double(lhs) % Double(rhs)
}

let niAdd = {(a: CGPoint, b: CGPoint) -> CGPoint in CGPointMake(a.x + b.x, a.y + b.y)}
let niSub = {(a: CGPoint, b: CGPoint) -> CGPoint in CGPointMake(a.x - b.x, a.y - b.y)}
let niMult = {(a: CGPoint, b: Float) -> CGPoint in CGPointMake(a.x * b, a.y * b)}
let niLength = {(a: CGPoint) -> Float in sqrtf(a.x * a.x + a.y * a.y)}
// unit vector
let niNormalize = {(a : CGPoint) -> CGPoint in
    var length = niLength(a)
    return CGPointMake(a.x / length, a.y / length)
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var player: SKSpriteNode!
    var lastSpawnTimeInterval: NSTimeInterval!
    var lastUpdateTimeInterval: NSTimeInterval!
    var monstersDestroyed: Int!
    
    enum Level: Int {
        case Easy = 1, Normal, Hard
        mutating func nextLevel() {
            switch self {
            case .Easy:
                self = .Normal
            case .Normal:
                self = .Hard
            case .Hard:
                self = .Easy
            }
        }
    }
    var gameLevel: Level = .Easy
    
    init(size: CGSize) {
        super.init(size: size)
        
        self.backgroundColor = SKColor(red: 1.0, green:1.0, blue:1.0, alpha:1.0)
        player = SKSpriteNode(imageNamed: "player")
        player.position = CGPointMake(self.player.size.width/2, self.frame.size.height/2)
        self.addChild(player)
        
        monstersDestroyed = 0
        lastSpawnTimeInterval = 0
        lastUpdateTimeInterval = 0
        
        gameLevel.nextLevel()
        
        //physics
        self.physicsWorld.gravity = CGVectorMake(0, 0)
        self.physicsWorld.contactDelegate = self
    }
    
    override func update(currentTime: NSTimeInterval) {
        var timeSinceLast: CFTimeInterval = currentTime - lastSpawnTimeInterval
        lastUpdateTimeInterval = currentTime
        if timeSinceLast > 1 {
            timeSinceLast = Double(gameLevel.toRaw()) / 60.0
            lastUpdateTimeInterval = currentTime
        }
        
        self.updateWithTimeSinceLastUpdate(timeSinceLast: timeSinceLast)
    }
    
    override func touchesEnded(touches: NSSet!, withEvent event: UIEvent!) {
        // get touch
        var touch = touches.anyObject() as UITouch
        var location = touch.locationInNode(self)
        
        //bullet action
        self.addProjectile(location: location)
    }
    
    func updateWithTimeSinceLastUpdate(#timeSinceLast: CFTimeInterval) {
        lastSpawnTimeInterval = lastSpawnTimeInterval + timeSinceLast
        if lastSpawnTimeInterval > 1 {
            lastSpawnTimeInterval = 0
            self.addMonster()
        }
    }
    
    func addProjectile(#location: CGPoint) {
        var projectile = SKSpriteNode(imageNamed:"projectile")
        projectile.position = player.position
        
        //physics
        projectile.physicsBody = SKPhysicsBody(circleOfRadius: projectile.size.width/2)
        projectile.physicsBody.dynamic = true
        projectile.physicsBody.categoryBitMask = projectileCategory
        projectile.physicsBody.contactTestBitMask = monsterCategory
        projectile.physicsBody.collisionBitMask = 0
        projectile.physicsBody.usesPreciseCollisionDetection = true
        
        var offset = niSub(location, projectile.position)
        if offset.x < 0 {return}
        
        self.addChild(projectile)
        
        // direct unit vector
        var direction = niNormalize(offset)
        //to screen's edge
        var shootAmount = niMult(direction, 1000)
        //now loc
        var realDest = niAdd(shootAmount, projectile.position)
        
        //action
        var velocity = 480.0/1.0
        var realMoveDuration = Double(self.size.width) / velocity
        
        var actionMove = SKAction.moveTo(realDest, duration: realMoveDuration)
        var actionMoveDone = SKAction.removeFromParent()
        var sequence = SKAction.sequence([actionMove, actionMoveDone])
        projectile.runAction(sequence)
        
        self.runAction(SKAction.playSoundFileNamed("pew-pew-lei.caf", waitForCompletion: false))
    }
    
    func addMonster() {
        var monster = SKSpriteNode(imageNamed: "monster")
        
        //location
        var minY = monster.size.height/2
        var maxY = self.frame.size.height - monster.size.height/2
        var rangeY = maxY - minY
        var actualY = arc4random() % rangeY + minY
        
        monster.position = CGPointMake(self.frame.size.width + monster.size.width/2, actualY)
        self.addChild(monster)
        
        //physics
        monster.physicsBody = SKPhysicsBody(rectangleOfSize: monster.size)
        monster.physicsBody.dynamic = true
        monster.physicsBody.categoryBitMask = monsterCategory
        monster.physicsBody.contactTestBitMask = projectileCategory
        monster.physicsBody.collisionBitMask = 0
        
        //speed
        var minDuration = 2.0
        var maxDuration = 4.0
        var rangeDuration = maxDuration - minDuration
        var actualDuration = arc4random() % rangeDuration + minDuration
        
        var actionMove = SKAction.moveTo(CGPointMake(-monster.size.width/2, actualY), duration: actualDuration)
        var actionMoveDone = SKAction.removeFromParent()
        var loseAction = SKAction.runBlock({
            var reveal = SKTransition.flipHorizontalWithDuration(0.5)
            var gameOverScene = GameOverScene(size: self.size, won: false)
            self.view.presentScene(gameOverScene, transition: reveal)
            })
        
        monster.runAction(SKAction.sequence([actionMove, loseAction, actionMoveDone]))
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        var firstBody: SKPhysicsBody!
        var secondBody: SKPhysicsBody!
        
        if (contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask)
        {
            firstBody = contact.bodyA;
            secondBody = contact.bodyB;
        }
        else
        {
            firstBody = contact.bodyB;
            secondBody = contact.bodyA;
        }
        
        if (firstBody.categoryBitMask & projectileCategory) != 0 && (secondBody.categoryBitMask & monsterCategory) != 0 {
            self.didCollide(projectile: firstBody.node as SKSpriteNode, monster: secondBody.node as SKSpriteNode)
        }
    }
    
    func didCollide(#projectile: SKSpriteNode, monster: SKSpriteNode) {
        projectile.removeFromParent()
        monster.removeFromParent()
        
        monstersDestroyed = monstersDestroyed + 1
        if monstersDestroyed > 30 {
            var reveal = SKTransition.flipHorizontalWithDuration(0.5)
            var gameOverScene = GameOverScene(size: self.size, won: true)
            self.view.presentScene(gameOverScene, transition: reveal)
        }
    }
}
