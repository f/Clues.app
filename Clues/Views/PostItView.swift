import SwiftUI
import SwiftData

struct PostItView: View {
    @Bindable var item: Item
    @Environment(\.modelContext) private var modelContext
    @State private var dragOffset = CGSize.zero
    @State private var isDragging = false
    @State private var crossProgress: Double = 0
    @State private var isHovered = false
    @State private var scale: CGFloat = 0
    
    let colors: [Color]
    let isConnectingMode: Bool
    let firstSelectedItem: Item?
    let onConnectionAttempt: (Item) -> Void
    let onRemoveConnection: (Connection) -> Void
    let onEdit: (Item) -> Void
    let onDelete: (Item) -> Void
    
    private var allConnections: [Connection] {
        var connections = Set<Connection>()
        item.connections.forEach { connections.insert($0) }
        return Array(connections)
    }
    
    private var currentPosition: CGPoint {
        CGPoint(
            x: item.position.x + dragOffset.width,
            y: item.position.y + dragOffset.height
        )
    }
    
    private func resizeImage(_ image: NSImage) -> NSImage? {
        let maxSize: CGFloat = 300
        let aspectRatio = image.size.width / image.size.height
        
        var newSize: NSSize
        if image.size.width > image.size.height {
            newSize = NSSize(width: maxSize, height: maxSize / aspectRatio)
        } else {
            newSize = NSSize(width: maxSize * aspectRatio, height: maxSize)
        }
        
        let resizedImage = NSImage(size: newSize)
        resizedImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize),
                  from: NSRect(origin: .zero, size: image.size),
                  operation: .sourceOver,
                  fraction: 1.0)
        resizedImage.unlockFocus()
        
        return resizedImage
    }
    
    var body: some View {
        ZStack {
            if let imageData = item.imageData,
               let originalImage = NSImage(data: imageData),
               let resizedImage = resizeImage(originalImage) {
                // Photo Frame Style
                let aspectRatio = resizedImage.size.width / resizedImage.size.height
                let frameWidth: CGFloat = 170
                let frameHeight = frameWidth / aspectRatio
                
                ZStack {
                    // Container for the image and frame
                    VStack(spacing: 0) {
                        Image(nsImage: resizedImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(12)
                    }
                    .frame(width: frameWidth, height: frameHeight)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color.black.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 3, x: 2, y: 2)
                    
                    // Tape label on top, not clipped
                    TapeLabel(text: item.title, frameWidth: frameWidth)
                }
                .frame(width: frameWidth + 80, height: frameHeight + 80)
                .rotation3DEffect(.degrees(item.actualRotation), axis: (x: 0, y: 0, z: 1))
                .offset(dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            isDragging = true
                            dragOffset = gesture.translation
                            item.bringToFront()
                            item.temporaryPosition = currentPosition
                        }
                        .onEnded { gesture in
                            withAnimation(.spring(duration: 0.3, bounce: 0.2)) {
                                isDragging = false
                                dragOffset = .zero
                                let newPosition = CGPoint(
                                    x: item.position.x + gesture.translation.width,
                                    y: item.position.y + gesture.translation.height
                                )
                                item.position = newPosition
                                item.temporaryPosition = nil
                            }
                        }
                )
                .onTapGesture(count: 2) {
                    onEdit(item)
                }
                .onTapGesture {
                    if isConnectingMode {
                        onConnectionAttempt(item)
                    } else {
                        item.bringToFront()
                    }
                }
                .scaleEffect(isDragging ? 1.05 : 1.0)
                .animation(.spring(duration: 0.3, bounce: 0.2), value: isDragging)
                .contextMenu {
                    if !allConnections.isEmpty {
                        Menu("Remove Connections") {
                            ForEach(allConnections) { connection in
                                Button(role: .destructive, action: {
                                    onRemoveConnection(connection)
                                }) {
                                    let otherItem = connection.fromItem.id == item.id ? connection.toItem : connection.fromItem
                                    Label(
                                        "To: \(otherItem.title)",
                                        systemImage: "link.badge.minus"
                                    )
                                }
                            }
                        }
                    }
                    
                    Button(role: .destructive, action: { onDelete(item) }) {
                        Label("Delete", systemImage: "trash")
                    }
                }
            } else {
                // Regular Post-it Style
                VStack(alignment: .leading, spacing: 8) {
                    Text(item.title)
                        .font(.custom("Bradley Hand", size: 16, relativeTo: .headline))
                        .foregroundStyle(.black)
                    
                    if !item.content.isEmpty {
                        Text(item.content)
                            .font(.custom("Bradley Hand", size: 14, relativeTo: .subheadline))
                            .foregroundStyle(.black.opacity(0.8))
                            .lineLimit(3)
                    }
                    
                    Spacer()
                    
                    HStack {
                        Button(action: {
                            if !item.isCompleted {
                                withAnimation(.easeInOut(duration: 1.0)) {
                                    item.isCompleted = true
                                    withAnimation(.easeInOut(duration: 1.0)) {
                                        crossProgress = 1.0
                                    }
                                }
                            } else {
                                item.isCompleted = false
                                crossProgress = 0
                            }
                        }) {
                            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(item.isCompleted ? .green : .black.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                        
                        Spacer()
                        
                        Text(item.timestamp.formatted(date: .abbreviated, time: .omitted))
                            .font(.custom("Bradley Hand", size: 12, relativeTo: .caption))
                            .foregroundStyle(.black.opacity(0.6))
                    }
                }
                .overlay {
                    if item.isCompleted {
                        CrossPaintView(progress: crossProgress, item: item)
                            .padding()
                    }
                }
                .padding()
                .frame(width: 170, height: 170)
                .background(colors[item.actualColor])
                .clipShape(RoundedRectangle(cornerRadius: 3))
                .shadow(color: .black.opacity(0.2), radius: 3, x: 2, y: 2)
                .rotation3DEffect(.degrees(item.actualRotation), axis: (x: 0, y: 0, z: 1))
                .overlay(
                    RoundedRectangle(cornerRadius: 3)
                        .stroke(isConnectingMode && (firstSelectedItem == item || firstSelectedItem == nil) ? 
                            Color.blue : Color.black.opacity(0.1), 
                            lineWidth: isConnectingMode ? 2 : 1
                        )
                )
                .offset(dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { gesture in
                            isDragging = true
                            dragOffset = gesture.translation
                            item.bringToFront()
                            item.temporaryPosition = currentPosition
                        }
                        .onEnded { gesture in
                            withAnimation(.spring(duration: 0.3, bounce: 0.2)) {
                                isDragging = false
                                dragOffset = .zero
                                let newPosition = CGPoint(
                                    x: item.position.x + gesture.translation.width,
                                    y: item.position.y + gesture.translation.height
                                )
                                item.position = newPosition
                                item.temporaryPosition = nil
                            }
                        }
                )
                .onTapGesture(count: 2) {
                    onEdit(item)
                }
                .onTapGesture {
                    if isConnectingMode {
                        onConnectionAttempt(item)
                    } else {
                        item.bringToFront()
                    }
                }
                .scaleEffect(isDragging ? 1.05 : 1.0)
                .animation(.spring(duration: 0.3, bounce: 0.2), value: isDragging)
                .contextMenu {
                    Button(action: {
                        item.bringToFront()
                        onEdit(item)
                    }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    if !allConnections.isEmpty {
                        Menu("Remove Connections") {
                            ForEach(allConnections) { connection in
                                Button(role: .destructive, action: {
                                    onRemoveConnection(connection)
                                }) {
                                    let otherItem = connection.fromItem.id == item.id ? connection.toItem : connection.fromItem
                                    Label(
                                        "To: \(otherItem.title)",
                                        systemImage: "link.badge.minus"
                                    )
                                }
                            }
                        }
                    }
                    
                    Button(role: .destructive, action: { onDelete(item) }) {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .onChange(of: item.isCompleted) { _, isCompleted in
            if !isCompleted {
                crossProgress = 0
            }
        }
        .onAppear {
            if item.isCompleted {
                crossProgress = 1.0
            }
        }
        .scaleEffect(scale)
        .onAppear {
            withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                scale = 1
            }
        }
    }
    
    init(item: Item, colors: [Color], isConnectingMode: Bool, firstSelectedItem: Item?,
         onConnectionAttempt: @escaping (Item) -> Void, onRemoveConnection: @escaping (Connection) -> Void,
         onEdit: @escaping (Item) -> Void, onDelete: @escaping (Item) -> Void) {
        self.item = item
        self.colors = colors
        self.isConnectingMode = isConnectingMode
        self.firstSelectedItem = firstSelectedItem
        self.onConnectionAttempt = onConnectionAttempt
        self.onRemoveConnection = onRemoveConnection
        self.onEdit = onEdit
        self.onDelete = onDelete
        self._scale = State(initialValue: 0)
    }
} 