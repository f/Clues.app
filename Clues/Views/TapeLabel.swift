import SwiftUI

struct TapeLabel: View {
    let text: String
    let width: CGFloat
    @State private var rotation: Double
    @State private var position: CGPoint
    
    init(text: String, frameWidth: CGFloat) {
        self.text = text
        self.width = frameWidth * 0.5
        
        // Choose either top-right or bottom-left corner
        let isTopRight = Bool.random()
        if isTopRight {
            // Top-right corner, rotated inward
            self._position = State(initialValue: CGPoint(x: frameWidth * 0.45, y: -frameWidth * 0.08))
            self._rotation = State(initialValue: Double.random(in: -20...(-10)))
        } else {
            // Bottom-left corner, rotated inward
            self._position = State(initialValue: CGPoint(x: -frameWidth * 0.45, y: frameWidth * 0.08))
            self._rotation = State(initialValue: Double.random(in: 10...20))
        }
    }
    
    var body: some View {
        Text(text)
            .font(.custom("Bradley Hand", size: 14))
            .foregroundStyle(.black.opacity(0.7))
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(.vertical, 3)
            .padding(.horizontal, 10)
            .frame(width: width)
            .background(
                SerratedRectangle()
                    .fill(.white.opacity(0.7))
                    .shadow(color: .black.opacity(0.2), radius: 1, x: 1, y: 1)
            )
            .rotationEffect(.degrees(rotation))
            .offset(x: position.x, y: position.y)
    }
} 