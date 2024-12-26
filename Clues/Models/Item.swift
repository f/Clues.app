//
//  Item.swift
//  Todo Application
//
//  Created by Fatih Kadir Akın on 21.12.2024.
//

import Foundation
import SwiftData

@Model
final class Item {
    var id: UUID
    var title: String
    var content: String
    var timestamp: Date
    // Store position as separate coordinates
    @Attribute(.externalStorage) var positionX: Double
    @Attribute(.externalStorage) var positionY: Double
    
    var position: CGPoint {
        get {
            CGPoint(x: positionX, y: positionY)
        }
        set {
            positionX = newValue.x
            positionY = newValue.y
        }
    }
    @Transient private var temporaryPos: CGPoint?
    var color: Int
    var rotation: Double
    var isCompleted: Bool
    var lastInteractionTime: Date
    @Attribute(.externalStorage) var imageData: Data?
    @Relationship(deleteRule: .cascade) var connections: [Connection]
    
    // Cross parameters
    var crossCurve1Offset: Double
    var crossCurve2Offset: Double
    var crossCurve1Direction: Double
    var crossCurve2Direction: Double
    
    var temporaryPosition: CGPoint? {
        get { temporaryPos }
        set { temporaryPos = newValue }
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        content: String = "",
        position: CGPoint,
        color: Int = Int.random(in: 0...5),
        rotation: Double = Double.random(in: -2...2),
        imageData: Data? = nil
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.timestamp = Date()
        self.positionX = position.x
        self.positionY = position.y
        self.color = color
        self.rotation = rotation
        self.isCompleted = false
        self.lastInteractionTime = Date()
        self.imageData = imageData
        self.connections = []
        
        // Initialize cross parameters with random values
        self.crossCurve1Offset = Double.random(in: 15...35)
        self.crossCurve2Offset = Double.random(in: 15...35)
        self.crossCurve1Direction = Double.random(in: -1...1)
        self.crossCurve2Direction = Double.random(in: -1...1)
    }
    
    var effectivePosition: CGPoint {
        temporaryPosition ?? position
    }
    
    var actualColor: Int {
        color % 6
    }
    
    var actualRotation: Double {
        rotation.truncatingRemainder(dividingBy: 360)
    }
    
    func bringToFront() {
        lastInteractionTime = Date()
    }
}

@Model
final class Connection {
    var id: String
    var fromItem: Item
    var toItem: Item
    var color: Int
    @Attribute(.externalStorage) var stringPoints: [CGPoint]
    
    init(id: UUID = UUID(), fromItem: Item, toItem: Item, color: Int = Int.random(in: 0...5), stringPoints: [CGPoint] = []) {
        self.id = id.uuidString
        self.fromItem = fromItem
        self.toItem = toItem
        self.color = color
        self.stringPoints = stringPoints
    }
}

extension Connection: Hashable {
    static func == (lhs: Connection, rhs: Connection) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
