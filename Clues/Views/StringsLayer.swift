import SwiftUI

struct StringsLayer: View {
    let items: [Item]
    let colors: [Color]
    let connectionPoint: (CGPoint) -> CGPoint
    let isPopupActive: Bool
    
    var body: some View {
        ZStack {
            ForEach(items) { item in
                ForEach(item.connections) { connection in
                    let fromPoint = connectionPoint(connection.fromItem.effectivePosition)
                    let toPoint = connectionPoint(connection.toItem.effectivePosition)
                    
                    // Draw string
                    StringView(
                        from: fromPoint,
                        to: toPoint,
                        color: colors[connection.color]
                    )
                    .blur(radius: isPopupActive ? 1 : 0)
                    
                    // Draw pins
                    PinView()
                        .position(fromPoint)
                        .blur(radius: isPopupActive ? 1 : 0)
                    
                    PinView()
                        .position(toPoint)
                        .blur(radius: isPopupActive ? 1 : 0)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

struct PinView: View {
    var body: some View {
        ZStack {
            // Pin head shadow
            Circle()
                .fill(.black.opacity(0.3))
                .frame(width: 12, height: 12)
                .offset(x: 1, y: 1)
            
            // Pin head highlight
            Circle()
                .fill(Color(.sRGB, red: 0.8, green: 0.2, blue: 0.2))
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .fill(.white.opacity(0.3))
                        .frame(width: 6, height: 6)
                        .offset(x: -2, y: -2)
                )
            
            // Pin point
            Path { path in
                path.move(to: CGPoint(x: 6, y: 6))
                path.addLine(to: CGPoint(x: 8, y: 8))
            }
            .stroke(.black.opacity(0.3), lineWidth: 2)
        }
        .frame(width: 14, height: 14)
    }
} 