//
//  ContentView.swift
//  Todo Application
//
//  Created by Fatih Kadir Akın on 21.12.2024.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import AppKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]
    @State private var isCreatingNewTodo = false
    @State private var newTodoPosition: CGPoint = .zero
    @State private var draggingOffset = CGSize.zero
    @State private var currentGeometry: GeometryProxy?
    @State private var isConnectingMode = false
    @State private var firstSelectedItem: Item?
    @State private var isAnyPopupActive: Bool = false
    @State private var isEditing = false
    @State private var editingItem: Item?
    @State private var editTitle: String = ""
    @State private var isTidyMode = false
    @State private var originalPositions: [String: CGPoint] = [:]
    @State private var isShowingSavePanel = false
    @State private var isShowingOpenPanel = false
    @State private var currentDocumentURL: URL?
    @State private var hasUnsavedChanges: Bool = false
    @State private var colors: [Color] = [
        Color(red: 1.0, green: 0.8, blue: 0.4),    // Warm Yellow
        Color(red: 0.98, green: 0.6, blue: 0.6),   // Coral Pink
        Color(red: 0.6, green: 0.9, blue: 0.6),    // Mint Green
        Color(red: 0.6, green: 0.8, blue: 1.0),    // Sky Blue
        Color(red: 1.0, green: 0.7, blue: 0.8),    // Rose Pink
        Color(red: 0.9, green: 0.8, blue: 1.0)     // Soft Purple
    ]
    @State private var searchText: String = ""
    
    private var sortedItems: [Item] {
        items.sorted { $0.lastInteractionTime < $1.lastInteractionTime }
    }
    
    private func deleteItem(_ item: Item) {
        // First, remove all connections where this item is either the source or target
        for connection in item.connections {
            // Remove the connection from the other item's connections array
            if connection.fromItem == item {
                connection.toItem.connections.removeAll { $0.id == connection.id }
            } else {
                connection.fromItem.connections.removeAll { $0.id == connection.id }
            }
            // Delete the connection from the model context
            modelContext.delete(connection)
        }
        // Finally, delete the item itself
        modelContext.delete(item)
    }
    
    private func createNewFile() {
        // Delete all items and their connections
        items.forEach { deleteItem($0) }
        currentDocumentURL = nil
    }
    
    var body: some View {
        ZStack {
            MainContentView(
                items: sortedItems,
                colors: colors,
                isConnectingMode: isConnectingMode,
                firstSelectedItem: firstSelectedItem,
                isAnyPopupActive: isAnyPopupActive,
                currentGeometry: $currentGeometry,
                newTodoPosition: $newTodoPosition,
                isCreatingNewTodo: $isCreatingNewTodo,
                onConnectionAttempt: handleConnectionAttempt,
                onRemoveConnection: removeConnection,
                onEdit: handleEdit,
                onDelete: deleteItem,
                searchText: searchText
            )
            .onChange(of: items) { _, _ in
                hasUnsavedChanges = true
            }
            .onAppear {
                setupNotificationObservers()
            }
            .toolbar {
                BoardToolbarContent(
                    currentDocumentURL: currentDocumentURL,
                    isConnectingMode: $isConnectingMode,
                    isTidyMode: $isTidyMode,
                    firstSelectedItem: $firstSelectedItem,
                    currentGeometry: currentGeometry,
                    items: items,
                    modelContext: modelContext,
                    onTidyUp: tidyUpPostIts,
                    searchText: $searchText
                )
            }
            .background(Color(.windowBackgroundColor))
        }
        .popup(isPresented: $isCreatingNewTodo) {
            NewFloatingPostIt(
                isShowing: $isCreatingNewTodo,
                colors: colors,
                onPostItAdded: {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isAnyPopupActive = false
                    }
                }
            )
        }
        .popup(isPresented: $isEditing) {
            if let item = editingItem {
                if item.imageData != nil {
                    TapeEditView(
                        isShowing: $isEditing,
                        title: $editTitle,
                        onSave: {
                            item.title = editTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                            withAnimation(.easeOut(duration: 0.2)) {
                                isAnyPopupActive = false
                            }
                        }
                    )
                } else {
                    PostItEditView(
                        isShowing: $isEditing,
                        title: $editTitle,
                        color: colors[item.actualColor],
                        rotation: item.actualRotation,
                        onSave: {
                            item.title = editTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                            withAnimation(.easeOut(duration: 0.2)) {
                                isAnyPopupActive = false
                            }
                        }
                    )
                }
            }
        }
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            forName: Notification.Name("NewFile"),
            object: nil,
            queue: .main
        ) { _ in
            handleNewFile()
        }
        
        NotificationCenter.default.addObserver(
            forName: Notification.Name("OpenFile"),
            object: nil,
            queue: .main
        ) { _ in
            handleOpenFile()
        }
        
        NotificationCenter.default.addObserver(
            forName: Notification.Name("SaveFile"),
            object: nil,
            queue: .main
        ) { _ in
            handleSaveFile()
        }
        
        NotificationCenter.default.addObserver(
            forName: Notification.Name("SaveAsFile"),
            object: nil,
            queue: .main
        ) { _ in
            handleSaveAsFile()
        }
        
        NotificationCenter.default.addObserver(
            forName: Notification.Name("NewTodo"),
            object: nil,
            queue: .main
        ) { _ in
            if let geometry = currentGeometry {
                // Calculate center position considering scroll position and window size
                let scrollView = NSApp.keyWindow?.contentView?.subviews.first(where: { $0 is NSScrollView }) as? NSScrollView
                let visibleRect = scrollView?.documentVisibleRect ?? .zero
                
                let centerX = visibleRect.midX
                let centerY = visibleRect.midY
                
                newTodoPosition = CGPoint(x: centerX, y: centerY)
                withAnimation(.spring(duration: 0.5)) {
                    isCreatingNewTodo = true
                    isAnyPopupActive = true
                }
            }
        }
    }
    
    private func handleNewFile() {
        if hasUnsavedChanges {
            let alert = NSAlert()
            alert.messageText = "Do you want to save changes to your document?"
            alert.informativeText = "Your changes will be lost if you don't save them."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Save")
            alert.addButton(withTitle: "Don't Save")
            alert.addButton(withTitle: "Cancel")
            
            let response = alert.runModal()
            switch response {
            case .alertFirstButtonReturn: // Save
                handleSaveFile()
                createNewFile()
            case .alertSecondButtonReturn: // Don't Save
                createNewFile()
            default: // Cancel
                return
            }
        } else {
            createNewFile()
        }
    }
    
    private func handleOpenFile() {
        if hasUnsavedChanges {
            let alert = NSAlert()
            alert.messageText = "Do you want to save changes to your document?"
            alert.informativeText = "Your changes will be lost if you don't save them."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Save")
            alert.addButton(withTitle: "Don't Save")
            alert.addButton(withTitle: "Cancel")
            
            let response = alert.runModal()
            switch response {
            case .alertFirstButtonReturn: // Save
                handleSaveFile()
                loadBoard()
            case .alertSecondButtonReturn: // Don't Save
                loadBoard()
            default: // Cancel
                return
            }
        } else {
            loadBoard()
        }
    }
    
    private func handleSaveFile() {
        if let url = currentDocumentURL {
            saveBoard(to: url)
        } else {
            handleSaveAsFile()
        }
    }
    
    private func getDefaultDirectory() -> URL {
        // Get iCloud Drive/Clues directory
        if let iCloudDriveURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.deletingLastPathComponent().appendingPathComponent("iCloud~dev~fka~clues") {
            let cluesDirectory = iCloudDriveURL.appendingPathComponent("Documents")
            do {
                if !FileManager.default.fileExists(atPath: cluesDirectory.path) {
                    try FileManager.default.createDirectory(at: cluesDirectory, withIntermediateDirectories: true)
                }
                print("Using iCloud directory: \(cluesDirectory.path)")
                return cluesDirectory
            } catch {
                print("Failed to create iCloud directory: \(error)")
            }
        }
        
        // Fallback to user's Documents folder
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let cluesDirectory = documentsURL.appendingPathComponent("Clues")
        do {
            if !FileManager.default.fileExists(atPath: cluesDirectory.path) {
                try FileManager.default.createDirectory(at: cluesDirectory, withIntermediateDirectories: true)
            }
            print("Using local directory: \(cluesDirectory.path)")
            return cluesDirectory
        } catch {
            print("Failed to create local directory: \(error)")
            return documentsURL
        }
    }
    
    private func handleSaveAsFile() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType.todoBoard]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.title = "Save Clues Board"
        savePanel.message = "Choose a location to save your clues board"
        savePanel.nameFieldLabel = "File name:"
        
        // Set default directory
        let defaultDirectory = getDefaultDirectory()
        print("Setting default save directory to: \(defaultDirectory.path)")
        savePanel.directoryURL = defaultDirectory
        
        let defaultName = currentDocumentURL?.lastPathComponent ?? "Untitled"
        let nameWithoutExtension = (defaultName as NSString).deletingPathExtension
        savePanel.nameFieldStringValue = "\(nameWithoutExtension).clues"
        
        if let window = NSApp.keyWindow {
            savePanel.beginSheetModal(for: window) { response in
                if response == .OK, let url = savePanel.url {
                    saveBoard(to: url)
                }
            }
        }
    }
    
    private func saveBoard(to url: URL) {
        do {
            let document = BoardDocument(items: items)
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(document.boardData)
            try data.write(to: url)
            currentDocumentURL = url
            hasUnsavedChanges = false
        } catch {
            let alert = NSAlert()
            alert.messageText = "Error Saving File"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .critical
            alert.runModal()
        }
    }
    
    private func handleConnectionAttempt(_ selectedItem: Item) {
        if let first = firstSelectedItem {
            if first != selectedItem {
                let connection = Connection(fromItem: first, toItem: selectedItem)
                first.connections.append(connection)
                selectedItem.connections.append(connection)
                firstSelectedItem = nil
            }
        } else {
            firstSelectedItem = selectedItem
        }
    }
    
    private func handleEdit(_ item: Item) {
        editingItem = item
        editTitle = item.title
        withAnimation(.spring(duration: 0.3)) {
            isEditing = true
            isAnyPopupActive = true
        }
    }
    
    private func calculateCanvasSize(geometry: GeometryProxy) -> (width: CGFloat, height: CGFloat) {
        let minWidth: CGFloat = max(geometry.size.width, 800)
        let minHeight: CGFloat = max(geometry.size.height, 600)
        
        let maxX = items.map { $0.position.x }.max() ?? 0
        let maxY = items.map { $0.position.y }.max() ?? 0
        
        let width = max(minWidth, maxX + 170)
        let height = max(minHeight, maxY + 170)
        
        return (width, height)
    }
    
    private func tidyUpPostIts(in geometry: GeometryProxy) {
        if !isTidyMode {
            // Store original positions before tidying
            let positions = items.map { item in
                (String(describing: item.persistentModelID), item.position)
            }
            originalPositions = Dictionary(uniqueKeysWithValues: positions)
            
            // Apply tidy layout
            let padding: CGFloat = 16
            let postItWidth: CGFloat = 170
            let postItHeight: CGFloat = 170
            let columns = max(1, Int(geometry.size.width / (postItWidth + padding)))
            
            for (index, item) in items.enumerated() {
                let row = index / columns
                let col = index % columns
                
                let x = (postItWidth + padding) * CGFloat(col) + postItWidth/2 + padding
                let y = (postItHeight + padding) * CGFloat(row) + postItHeight/2 + padding
                
                withAnimation(.spring(duration: 0.5)) {
                    item.position = CGPoint(x: x, y: y)
                }
            }
        } else {
            // Restore original positions
            for item in items {
                if let originalPosition = originalPositions[String(describing: item.persistentModelID)] {
                    withAnimation(.spring(duration: 0.5)) {
                        item.position = originalPosition
                    }
                }
            }
            originalPositions.removeAll()
        }
        
        // Toggle the tidy mode
        isTidyMode.toggle()
    }
    
    private func removeConnection(_ connection: Connection) {
        // Remove from both items' connections arrays
        connection.fromItem.connections.removeAll { $0.id == connection.id }
        connection.toItem.connections.removeAll { $0.id == connection.id }
        modelContext.delete(connection)
    }
    
    private func connectionPoint(for postIt: CGPoint) -> CGPoint {
        CGPoint(x: postIt.x + 65, y: postIt.y - 65)
    }
    
    private func loadBoard() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [UTType.todoBoard]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = true
        openPanel.title = "Open Clues Board"
        openPanel.message = "Choose a clues board to open"
        openPanel.allowsOtherFileTypes = false
        openPanel.treatsFilePackagesAsDirectories = false
        
        // Set default directory
        openPanel.directoryURL = getDefaultDirectory()
        
        // Set up allowed file types explicitly
        openPanel.allowedFileTypes = ["clues"]
        
        if let window = NSApp.keyWindow {
            openPanel.beginSheetModal(for: window) { response in
                if response == .OK, let url = openPanel.url {
                    // Verify file extension
                    guard url.pathExtension.lowercased() == "clues" else {
                        let alert = NSAlert()
                        alert.messageText = "Invalid File Type"
                        alert.informativeText = "Please select a .clues file"
                        alert.alertStyle = .warning
                        alert.runModal()
                        return
                    }
                    
                    do {
                        let data = try Data(contentsOf: url)
                        let decoder = JSONDecoder()
                        let boardData = try decoder.decode(BoardData.self, from: data)
                        
                        // Clear existing items
                        items.forEach { modelContext.delete($0) }
                        
                        // Dictionary to store items by their IDs for connection restoration
                        var itemsById: [UUID: Item] = [:]
                        
                        // Create new items
                        boardData.items.forEach { itemData in
                            let item = Item(
                                id: itemData.id,
                                title: itemData.title,
                                content: itemData.content,
                                position: itemData.position,
                                color: itemData.color,
                                rotation: itemData.rotation,
                                imageData: itemData.imageData
                            )
                            item.isCompleted = itemData.isCompleted
                            item.lastInteractionTime = itemData.lastInteractionTime
                            item.crossCurve1Offset = itemData.crossCurve1Offset
                            item.crossCurve2Offset = itemData.crossCurve2Offset
                            item.crossCurve1Direction = itemData.crossCurve1Direction
                            item.crossCurve2Direction = itemData.crossCurve2Direction
                            modelContext.insert(item)
                            itemsById[item.id] = item
                        }
                        
                        // Restore connections
                        boardData.connections.forEach { connectionData in
                            if let fromItem = itemsById[connectionData.fromItemId],
                               let toItem = itemsById[connectionData.toItemId] {
                                let connection = Connection(
                                    id: UUID(uuidString: connectionData.id) ?? UUID(),
                                    fromItem: fromItem,
                                    toItem: toItem,
                                    color: connectionData.color,
                                    stringPoints: connectionData.stringPoints
                                )
                                fromItem.connections.append(connection)
                                toItem.connections.append(connection)
                            }
                        }
                        
                        // Update current document URL
                        self.currentDocumentURL = url
                        hasUnsavedChanges = false
                        
                    } catch {
                        let alert = NSAlert()
                        alert.messageText = "Error Loading File"
                        alert.informativeText = error.localizedDescription
                        alert.alertStyle = .critical
                        alert.runModal()
                    }
                }
            }
        }
    }
    
    private func handleNewPostItCreation(title: String, color: Int, rotation: Double) {
        let item = Item(
            title: title,
            position: newTodoPosition
        )
        item.color = color
        item.rotation = rotation
        
        withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
            modelContext.insert(item)
        }
    }
}

// MARK: - Main Content View
private struct MainContentView: View {
    @Environment(\.modelContext) private var modelContext
    let items: [Item]
    let colors: [Color]
    let isConnectingMode: Bool
    let firstSelectedItem: Item?
    let isAnyPopupActive: Bool
    @Binding var currentGeometry: GeometryProxy?
    @Binding var newTodoPosition: CGPoint
    @Binding var isCreatingNewTodo: Bool
    let onConnectionAttempt: (Item) -> Void
    let onRemoveConnection: (Connection) -> Void
    let onEdit: (Item) -> Void
    let onDelete: (Item) -> Void
    let searchText: String
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView([.horizontal, .vertical]) {
                ZStack {
                    let canvasSize = calculateCanvasSize(geometry: geometry)
                    Color.clear
                        .frame(
                            width: canvasSize.width + 100,
                            height: canvasSize.height + 100
                        )
                        .onDrop(
                            of: [.image],
                            delegate: ImageDropDelegate(
                                geometry: geometry,
                                modelContext: modelContext,
                                colors: colors
                            )
                        )
                    
                    // Layer 1: Post-its
                    ForEach(items) { item in
                        PostItView(
                            item: item,
                            colors: colors,
                            isConnectingMode: isConnectingMode,
                            firstSelectedItem: firstSelectedItem,
                            onConnectionAttempt: onConnectionAttempt,
                            onRemoveConnection: onRemoveConnection,
                            onEdit: onEdit,
                            onDelete: onDelete
                        )
                        .position(item.position)
                        .opacity(searchText.isEmpty ? 1 : item.title.localizedCaseInsensitiveContains(searchText) ? 1 : 0.3)
                        .animation(.easeInOut(duration: 0.2), value: searchText)
                    }
                    
                    // Layer 2: Strings and Pins
                    StringsLayer(
                        items: items,
                        colors: colors,
                        connectionPoint: connectionPoint,
                        isPopupActive: isAnyPopupActive
                    )
                }
            }
            .onAppear {
                currentGeometry = geometry
                NotificationCenter.default.addObserver(
                    forName: Notification.Name("NewTodo"),
                    object: nil,
                    queue: .main
                ) { _ in
                    newTodoPosition = CGPoint(
                        x: geometry.size.width / 2,
                        y: geometry.size.height / 2
                    )
                    isCreatingNewTodo = true
                }
            }
            .onChange(of: items) { _, _ in
                currentGeometry = geometry
            }
        }
    }
    
    private func calculateCanvasSize(geometry: GeometryProxy) -> (width: CGFloat, height: CGFloat) {
        let minWidth: CGFloat = max(geometry.size.width, 800)
        let minHeight: CGFloat = max(geometry.size.height, 600)
        
        let maxX = items.map { $0.position.x }.max() ?? 0
        let maxY = items.map { $0.position.y }.max() ?? 0
        
        let width = max(minWidth, maxX + 170)
        let height = max(minHeight, maxY + 170)
        
        return (width, height)
    }
    
    private func connectionPoint(for postIt: CGPoint) -> CGPoint {
        CGPoint(x: postIt.x + 65, y: postIt.y - 65)
    }
}

// MARK: - Board Toolbar Content
private struct BoardToolbarContent: ToolbarContent {
    let currentDocumentURL: URL?
    @Binding var isConnectingMode: Bool
    @Binding var isTidyMode: Bool
    @Binding var firstSelectedItem: Item?
    let currentGeometry: GeometryProxy?
    let items: [Item]
    let modelContext: ModelContext
    let onTidyUp: (GeometryProxy) -> Void
    @Binding var searchText: String
    
    var body: some ToolbarContent {
        // Left group - Quick Actions
        ToolbarItem(placement: .navigation) {
            Button(action: {
                NotificationCenter.default.post(
                    name: Notification.Name("NewTodo"),
                    object: nil
                )
            }) {
                Label("New Todo", systemImage: "plus")
                    .labelStyle(.iconOnly)
            }
            .keyboardShortcut("t", modifiers: .command)
            .help("New Todo")
        }
        
        // Center group - Title and Path
        ToolbarItem(placement: .principal) {
            VStack(spacing: 2) {
                Text("Clue Board")
                    .font(.headline)
                if let url = currentDocumentURL {
                    Text(url.lastPathComponent)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        
        // Right group - Utility functions
        ToolbarItem(placement: .primaryAction) {
            HStack(spacing: 16) {
                Button(action: {
                    isConnectingMode.toggle()
                    if !isConnectingMode {
                        firstSelectedItem = nil
                    }
                }) {
                    Label("Connect Post-its", systemImage: isConnectingMode ? "link.circle.fill" : "link.circle")
                        .labelStyle(.iconOnly)
                }
                .help(isConnectingMode ? "Exit Connection Mode" : "Connect Post-its")
                .keyboardShortcut("l", modifiers: .command)
                
                Button(action: {
                    if let geometry = currentGeometry {
                        onTidyUp(geometry)
                    }
                }) {
                    Label(isTidyMode ? "Restore Layout" : "Tidy Up", 
                          systemImage: isTidyMode ? "arrow.uturn.backward" : "square.grid.2x2")
                        .labelStyle(.iconOnly)
                }
                .help(isTidyMode ? "Restore Layout" : "Tidy Up")
                .keyboardShortcut("t", modifiers: .command)
            }
        }
        
        // Add this new toolbar item before the right group
        ToolbarItem(placement: .primaryAction) {
            ZStack {
                TextField("", text: $searchText)
                    .textFieldStyle(.plain)
                    .frame(width: 200)
                    .padding(4)
                    .padding(.leading, 25)
                    .background {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                                .padding(.leading, 8)
                            Spacer()
                        }
                    }
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(.separatorColor), lineWidth: 0.5)
                    )
                    .placeholder(when: searchText.isEmpty) {
                        Text("Search")
                            .foregroundColor(.secondary)
                            .padding(.leading, 35)
                    }
                
                if !searchText.isEmpty {
                    HStack {
                        Spacer()
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.trailing, 0)
                    .frame(width: 220)
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
