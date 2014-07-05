//
//  GameOverScene.swift
//  Ninjia
//
//  Created by ran on 14-7-4.
//  Copyright (c) 2014年 Rannie. All rights reserved.
//

import SpriteKit

class GameOverScene : SKScene {
    
    convenience init(size: CGSize, won: Bool) {
        self.init(size: size)
        self.backgroundColor = SKColor(red:1.0, green:1.0, blue:1.0, alpha:1.0)
        
        self.setupMsgLabel(isWon :won)
        self.directorAction()
    }
    
    func setupMsgLabel(isWon won: Bool) {
        var msg: String = won ? "Yow Won!" : "You Lose :["
        
        var msgLabel = SKLabelNode(fontNamed: "Chalkduster")
        msgLabel.text = msg
        msgLabel.fontSize = 40
        msgLabel.fontColor = SKColor.blackColor()
        msgLabel.position = CGPointMake(self.size.width/2, self.size.height/2)
        self.addChild(msgLabel)
    }
    
    func directorAction() {
        var actions: AnyObject[] = [ SKAction.waitForDuration(3.0), SKAction.runBlock({
            var reveal = SKTransition.flipHorizontalWithDuration(0.5)
            var gameScene = GameScene(size: self.size)
            self.view.presentScene(gameScene, transition: reveal)
            }) ]
        var sequence = SKAction.sequence(actions)
        
        self.runAction(sequence)
    }
    
}