import SwiftUI
import SwiftData

struct ImageDropDelegate: DropDelegate {
    let geometry: GeometryProxy
    let modelContext: ModelContext
    let colors: [Color]
    
    @MainActor
    private func resizeImage(data: Data) -> Data? {
        guard let originalImage = NSImage(data: data) else { return nil }
        
        let maxSize: CGFloat = 300 // Maximum dimension for resizing
        let aspectRatio = originalImage.size.width / originalImage.size.height
        
        var newSize: NSSize
        if originalImage.size.width > originalImage.size.height {
            newSize = NSSize(width: maxSize, height: maxSize / aspectRatio)
        } else {
            newSize = NSSize(width: maxSize * aspectRatio, height: maxSize)
        }
        
        let resizedImage = NSImage(size: newSize)
        resizedImage.lockFocus()
        originalImage.draw(in: NSRect(origin: .zero, size: newSize),
                         from: NSRect(origin: .zero, size: originalImage.size),
                         operation: .sourceOver,
                         fraction: 1.0)
        resizedImage.unlockFocus()
        
        // Convert back to data
        if let tiffData = resizedImage.tiffRepresentation,
           let bitmapImage = NSBitmapImageRep(data: tiffData) {
            return bitmapImage.representation(using: .jpeg, properties: [.compressionFactor: 0.8])
        }
        
        return nil
    }
    
    func performDrop(info: DropInfo) -> Bool {
        guard let provider = info.itemProviders(for: [.image]).first else { return false }
        let dropPoint = info.location
        
        _ = provider.loadDataRepresentation(for: .image) { [dropPoint] data, error in
            if let imageData = data {
                Task { @MainActor in
                    let resizedData = resizeImage(data: imageData)
                    if let resizedData {
                        let item = Item(
                            title: "Image",
                            position: dropPoint,
                            imageData: resizedData
                        )
                        modelContext.insert(item)
                    }
                }
            }
        }
        
        return true
    }
    
    func validateDrop(info: DropInfo) -> Bool {
        return info.hasItemsConforming(to: [.image])
    }
} 