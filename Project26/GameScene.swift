//
//  GameScene.swift
//  Project26
//
//  Created by Grant Watson on 10/26/22.
//

import CoreMotion
import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    var player: SKSpriteNode!
    var lastTouchPosition: CGPoint?
    
    var motionManager: CMMotionManager?
    var isGameOver = false
    
    var scoreLabel: SKLabelNode!
    
    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    enum CollisionTypes: UInt32 {
        case player = 1
        case wall = 2
        case star = 4
        case vortex = 8
        case finish = 16
        case teleport = 32
    }
    
    override func didMove(to view: SKView) {
        configureBackground()
        configureScoreLabel()
        
        loadLevel(levelFile: "level1")
        createPlayer()
        
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        motionManager = CMMotionManager()
        motionManager?.startAccelerometerUpdates()
    }
    
    func loadLevel(levelFile: String) {
        guard let levelURL = Bundle.main.url(forResource: levelFile, withExtension: "txt") else {
            fatalError("Could not find level1.txt in the app bundle")
        }
        guard let levelString = try? String(contentsOf: levelURL) else {
            fatalError("Could not load level1.txt from the app bundle")
        }
        
        let lines = levelString.components(separatedBy: "\n")
        
        for (row, line) in lines.reversed().enumerated() {
            for (column, letter) in line.enumerated() {
                let position = CGPoint(x: (64 * column) + 32, y: (64 * row) + 32)
                
                if letter == "x" {
                    configureWall(position: position)
                } else if letter == "v" {
                    configureVortex(position: position)
                } else if letter == "s" {
                    configureStar(position: position)
                } else if letter == "f" {
                    configureFinish(position: position)
                } else if letter == "t" {
                    configureTeleport(type: "teleport1", position: position)
                } else if letter == "T" {
                    configureTeleport(type: "teleport2", position: position)
                } else if letter == " " {
                    // empty space - leave open
                } else {
                    fatalError("Unknown level letter: \(letter)")
                }
            }
        }
    }
    
    func configureWall(position: CGPoint) {
        let node = SKSpriteNode(imageNamed: "block")
        node.position = position
        node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
        node.physicsBody?.categoryBitMask = CollisionTypes.wall.rawValue
        node.physicsBody?.isDynamic = false
        addChild(node)
    }
    
    func configureVortex(position: CGPoint) {
        let node = SKSpriteNode(imageNamed: "vortex")
        node.name = "vortex"
        node.position = position
        node.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi, duration: 1)))
        node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
        node.physicsBody?.isDynamic = false
        node.physicsBody?.categoryBitMask = CollisionTypes.vortex.rawValue
        node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        node.physicsBody?.collisionBitMask = 0
        addChild(node)
    }
    
    func configureStar(position: CGPoint) {
        let node = SKSpriteNode(imageNamed: "star")
        node.name = "star"
        node.position = position
        node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
        node.physicsBody?.isDynamic = false
        node.physicsBody?.categoryBitMask = CollisionTypes.star.rawValue
        node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        node.physicsBody?.collisionBitMask = 0
        addChild(node)
    }
    
    func configureFinish(position: CGPoint) {
        let node = SKSpriteNode(imageNamed: "finish")
        node.name = "finish"
        node.position = position
        node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
        node.physicsBody?.isDynamic = false
        node.physicsBody?.categoryBitMask = CollisionTypes.finish.rawValue
        node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        node.physicsBody?.collisionBitMask = 0
        addChild(node)
    }
    
    func configureTeleport(type: String, position: CGPoint) {
        let node = SKSpriteNode(imageNamed: "teleport")
        if type == "teleport1" {
            node.name = "teleport1"
        } else {
            node.name = "teleport2"
        }
        node.position = position
        node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
        node.run(SKAction.repeatForever(SKAction.rotate(byAngle: -.pi, duration: 4)))
        node.physicsBody?.isDynamic = false
        node.physicsBody?.categoryBitMask = CollisionTypes.teleport.rawValue
        node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        node.physicsBody?.collisionBitMask = 0
        addChild(node)
    }
    
    func createPlayer() {
        player = SKSpriteNode(imageNamed: "player")
        player.position = CGPoint(x: 96, y: 672)
        player.zPosition = 1
        
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width / 2)
        player.physicsBody?.allowsRotation = false
        player.physicsBody?.linearDamping = 0.5
        
        player.physicsBody?.categoryBitMask = CollisionTypes.player.rawValue
        player.physicsBody?.contactTestBitMask = CollisionTypes.star.rawValue | CollisionTypes.vortex.rawValue | CollisionTypes.finish.rawValue | CollisionTypes.teleport.rawValue
        player.physicsBody?.collisionBitMask = CollisionTypes.wall.rawValue
        addChild(player)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        lastTouchPosition = location
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        lastTouchPosition = location
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastTouchPosition = nil
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard isGameOver == false else { return }
        
        #if targetEnvironment(simulator)
        if let lastTouchPosition = lastTouchPosition {
            let diff = CGPoint(x: lastTouchPosition.x - player.position.x, y: lastTouchPosition.y - player.position.y)
            physicsWorld.gravity = CGVector(dx: diff.x / 100, dy: diff.y / 100)
        }
        #else
        if let accelerometerData = motionManager?.accelerometerData {
            physicsWorld.gravity = CGVector(dx: accelerometerData.acceleration.y * -50, dy: accelerometerData.acceleration.x * 50)
        }
        #endif
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else { return }
        guard let nodeB = contact.bodyB.node else { return }
        
        if nodeA == player {
            playerCollided(with: nodeB)
        } else if nodeB == player {
            playerCollided(with: nodeA)
        }
    }
    
    func playerCollided(with node: SKNode) {
        if node.name == "vortex" {
            player.physicsBody?.isDynamic = false
            isGameOver = true
            score -= 1
            
            let move = SKAction.move(to: node.position, duration: 0.25)
            let scale = SKAction.scale(to: 0.0001, duration: 0.25)
            let rotate = SKAction.rotate(byAngle: -180, duration: 0.25)
            let remove = SKAction.removeFromParent()
            
            let group = SKAction.group([scale, rotate])
            let sequence = SKAction.sequence([move, group, remove])
            player.run(sequence) { [weak self] in
                self?.createPlayer()
                self?.isGameOver = false
            }
        } else if node.name == "star" {
            let scale = SKAction.scale(by: 2, duration: 0.25)
            let fade = SKAction.fadeOut(withDuration: 0.25)
            let remove = SKAction.removeFromParent()
            
            let group = SKAction.group([scale, fade])
            let sequence = SKAction.sequence([group, remove])
            node.run(sequence)
            score += 1
        } else if node.name == "teleport1" {
            guard let teleport2 = node.parent?.childNode(withName: "teleport2") else { return }
            teleport2.name = "teleport"
            
            let fadeOut = SKAction.fadeOut(withDuration: 0.1)
            let move = SKAction.move(to: teleport2.position, duration: 0.4)
            let fadeIn = SKAction.fadeIn(withDuration: 0.1)
            let seq = SKAction.sequence([fadeOut, move, fadeIn])
            
            player.run(seq)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                teleport2.name = "teleport2"
            }
            
        } else if node.name == "teleport2" {
            guard let teleport1 = node.parent?.childNode(withName: "teleport1") else { return }
            teleport1.name = "teleport"
            
            let fadeOut = SKAction.fadeOut(withDuration: 0.05)
            let move = SKAction.move(to: teleport1.position, duration: 0.06)
            let fadeIn = SKAction.fadeIn(withDuration: 0.2)
            let seq = SKAction.sequence([fadeOut, move, fadeIn])
            
            player.run(seq)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                teleport1.name = "teleport1"
            }
        } else if node.name == "finish" {
            // next level
            let move = SKAction.move(to: node.position, duration: 0.25)
            let remove = SKAction.removeFromParent()
            let seq = SKAction.sequence([move, remove])
            player.run(seq)
            nextLevel()
        }
    }
    
    func nextLevel() {
        removeAllChildren()
        configureBackground()
        configureScoreLabel()
        loadLevel(levelFile: "level2")
        createPlayer()
    }
    
    func configureBackground() {
        let background = SKSpriteNode(imageNamed: "background")
        background.position = CGPoint(x: 512, y: 384)
        background.zPosition = -1
        background.blendMode = .replace
        addChild(background)
    }
    
    func configureScoreLabel() {
        scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabel.text = "Score: 0"
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: 16, y: 20)
        scoreLabel.zPosition = 2
        addChild(scoreLabel)
    }
}
