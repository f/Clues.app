import SwiftUI

struct CrossPaintView: View {
    let progress: Double
    let color: Color = .red
    let item: Item
    
    private func createBrushStroke(from start: CGPoint, to end: CGPoint, progress: Double, curveOffset: Double, curveDirection: Double) -> [CGPoint] {
        let steps = 30
        var points: [CGPoint] = []
        
        // Calculate the direct line points without curves
        for i in 0...steps {
            let t = Double(i) / Double(steps)
            let adjustedT = t * progress
            
            let x = start.x + (end.x - start.x) * adjustedT
            let y = start.y + (end.y - start.y) * adjustedT
            
            // Add very slight randomness for a natural look
            let randomOffset = Double.random(in: -0.5...0.5)
            points.append(CGPoint(
                x: x + randomOffset,
                y: y + randomOffset
            ))
        }
        
        return points
    }
    
    var body: some View {
        Canvas { context, size in
            // First line of the X (top-left to bottom-right)
            if progress > 0 {
                let line1Progress = min(1, progress * 2)
                let start = CGPoint(x: 0, y: 0)
                let end = CGPoint(x: size.width, y: size.height)
                let points = createBrushStroke(
                    from: start,
                    to: end,
                    progress: line1Progress,
                    curveOffset: item.crossCurve1Offset,
                    curveDirection: item.crossCurve1Direction
                )
                
                // Draw multiple overlapping strokes for thick brush effect
                for _ in 0...5 {
                    var brushPath = Path()
                    brushPath.move(to: points[0])
                    
                    for point in points.dropFirst() {
                        brushPath.addLine(to: point)
                    }
                    
                    context.stroke(
                        brushPath,
                        with: .color(color.opacity(Double.random(in: 0.4...0.6))),
                        lineWidth: CGFloat.random(in: 3...5)
                    )
                }
            }
            
            // Second line of the X (top-right to bottom-left)
            if progress > 0.5 {
                let line2Progress = (progress - 0.5) * 2
                let start = CGPoint(x: size.width, y: 0)
                let end = CGPoint(x: 0, y: size.height)
                let points = createBrushStroke(
                    from: start,
                    to: end,
                    progress: line2Progress,
                    curveOffset: item.crossCurve2Offset,
                    curveDirection: item.crossCurve2Direction
                )
                
                // Draw multiple overlapping strokes for thick brush effect
                for _ in 0...5 {
                    var brushPath = Path()
                    brushPath.move(to: points[0])
                    
                    for point in points.dropFirst() {
                        brushPath.addLine(to: point)
                    }
                    
                    context.stroke(
                        brushPath,
                        with: .color(color.opacity(Double.random(in: 0.4...0.6))),
                        lineWidth: CGFloat.random(in: 3...5)
                    )
                }
            }
        }
    }
} 