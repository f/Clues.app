import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct BoardData: Codable {
    var items: [ItemData]
    var connections: [ConnectionData]
    
    enum CodingKeys: String, CodingKey {
        case items
        case connections
    }
    
    init(items: [ItemData] = [], connections: [ConnectionData] = []) {
        self.items = items
        self.connections = connections
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        items = try container.decode([ItemData].self, forKey: .items)
        connections = try container.decode([ConnectionData].self, forKey: .connections)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(items, forKey: .items)
        try container.encode(connections, forKey: .connections)
    }
}

struct ItemData: Codable {
    var id: UUID
    var title: String
    var content: String
    var position: CGPoint
    var timestamp: Date
    var color: Int
    var rotation: Double
    var isCompleted: Bool
    var lastInteractionTime: Date
    var imageData: Data?
    var crossCurve1Offset: Double
    var crossCurve2Offset: Double
    var crossCurve1Direction: Double
    var crossCurve2Direction: Double
    
    enum CodingKeys: String, CodingKey {
        case id, title, content, position, timestamp, color, rotation
        case isCompleted, lastInteractionTime, imageData
        case crossCurve1Offset, crossCurve2Offset
        case crossCurve1Direction, crossCurve2Direction
    }
}

struct ConnectionData: Codable {
    var id: String
    var fromItemId: UUID
    var toItemId: UUID
    var color: Int
    var stringPoints: [CGPoint]
    
    enum CodingKeys: String, CodingKey {
        case id, fromItemId, toItemId, color, stringPoints
    }
}

@objcMembers final class BoardDocument: NSObject, ReferenceFileDocument {
    static var readableContentTypes: [UTType] = [.todoBoard]
    static var writableContentTypes: [UTType] = [.todoBoard]
    
    @Published var boardData: BoardData
    
    init(items: [Item]) {
        let itemsData = items.map { item in
            ItemData(
                id: item.id,
                title: item.title,
                content: item.content,
                position: item.position,
                timestamp: item.timestamp,
                color: item.color,
                rotation: item.rotation,
                isCompleted: item.isCompleted,
                lastInteractionTime: item.lastInteractionTime,
                imageData: item.imageData,
                crossCurve1Offset: item.crossCurve1Offset,
                crossCurve2Offset: item.crossCurve2Offset,
                crossCurve1Direction: item.crossCurve1Direction,
                crossCurve2Direction: item.crossCurve2Direction
            )
        }
        
        let connectionsData = items.flatMap { item in
            item.connections.map { connection in
                ConnectionData(
                    id: connection.id,
                    fromItemId: connection.fromItem.id,
                    toItemId: connection.toItem.id,
                    color: connection.color,
                    stringPoints: connection.stringPoints
                )
            }
        }
        
        self.boardData = BoardData(items: itemsData, connections: connectionsData)
        super.init()
    }
    
    required init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents
        else {
            self.boardData = BoardData()
            super.init()
            return
        }
        
        do {
            self.boardData = try JSONDecoder().decode(BoardData.self, from: data)
        } catch {
            throw CocoaError(.fileReadCorruptFile)
        }
        
        super.init()
    }
    
    func snapshot(contentType: UTType) throws -> BoardData {
        return boardData
    }
    
    func fileWrapper(snapshot: BoardData, configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(snapshot)
        return FileWrapper(regularFileWithContents: data)
    }
    
    static func loadIntoContext(_ document: BoardDocument, context: ModelContext) throws {
        // Clear existing items
        try context.delete(model: Item.self)
        
        // Create dictionary to store items by ID for connection lookup
        var itemsById: [UUID: Item] = [:]
        
        // Create new items
        for itemData in document.boardData.items {
            let item = Item(
                id: itemData.id,
                title: itemData.title,
                content: itemData.content,
                position: itemData.position,
                color: itemData.color,
                rotation: itemData.rotation,
                imageData: itemData.imageData
            )
            item.timestamp = itemData.timestamp
            item.isCompleted = itemData.isCompleted
            item.lastInteractionTime = itemData.lastInteractionTime
            item.crossCurve1Offset = itemData.crossCurve1Offset
            item.crossCurve2Offset = itemData.crossCurve2Offset
            item.crossCurve1Direction = itemData.crossCurve1Direction
            item.crossCurve2Direction = itemData.crossCurve2Direction
            
            context.insert(item)
            itemsById[item.id] = item
        }
        
        // Create connections
        for connectionData in document.boardData.connections {
            guard let fromItem = itemsById[connectionData.fromItemId],
                  let toItem = itemsById[connectionData.toItemId] else {
                continue
            }
            
            let connection = Connection(fromItem: fromItem, toItem: toItem)
            connection.id = connectionData.id
            connection.color = connectionData.color
            connection.stringPoints = connectionData.stringPoints
            
            fromItem.connections.append(connection)
            toItem.connections.append(connection)
        }
    }
} 