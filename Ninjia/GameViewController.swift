//
//  GameViewController.swift
//  Ninjia
//
//  Created by Rannie on 14/7/3.
//  Copyright (c) 2014年 Rannie. All rights reserved.
//

import UIKit
import SpriteKit
import AVFoundation

let BG_MUSIC_NAME = "background-music-aac"

class GameViewController: UIViewController {
    
    var backgroundMusicPlayer : AVAudioPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMedia()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        var skView : SKView = self.view as SKView
        if !skView.scene {
            //DEBUG
            skView.showsFPS = true
            skView.showsNodeCount = true
            
            var scene : SKScene = GameScene.sceneWithSize(skView.bounds.size)
            scene.scaleMode = .AspectFill
            
            skView.presentScene(scene)
        }
    }
    
    func setupMedia() {
        
        var error : NSError?
        let backgroundMusicURL : NSURL = NSBundle.mainBundle().URLForResource(BG_MUSIC_NAME, withExtension: "caf")
        backgroundMusicPlayer = AVAudioPlayer(contentsOfURL: backgroundMusicURL , error: &error)
        if error {
            println("load background music error : \(error)")
        } else {
            backgroundMusicPlayer!.numberOfLoops = -1
            backgroundMusicPlayer!.prepareToPlay()
            backgroundMusicPlayer!.play()
        }
    }
    
    override func prefersStatusBarHidden() -> Bool { return true }
    
}
