import SwiftUI

struct PhysicsString {
    struct Point {
        var position: CGPoint
        var velocity: CGVector
        var isFixed: Bool
        
        mutating func applyForce(_ force: CGVector) {
            guard !isFixed else { return }
            velocity.dx += force.dx
            velocity.dy += force.dy
        }
        
        mutating func update(gravity: CGFloat, damping: CGFloat, wind: CGFloat = 0) {
            guard !isFixed else { return }
            
            // Apply wind force with reduced effect
            let windForce = CGVector(dx: wind * (0.5 - Double.random(in: 0...1)), dy: 0)
            applyForce(windForce)
            
            // Update position with velocity (faster movement)
            position.x += velocity.dx * 1.5
            position.y += velocity.dy * 1.5
            
            // Apply gravity
            velocity.dy += gravity
            
            // Apply damping
            velocity.dx *= damping
            velocity.dy *= damping
        }
    }
    
    private var points: [Point]
    private var segmentLength: CGFloat
    private let iterations: Int
    private let segments: Int
    private let minSegmentLength: CGFloat = 10 // Minimum length for each segment
    private let maxSag: CGFloat = 30 // Maximum sag in the middle
    
    init(start: CGPoint, end: CGPoint, segments: Int = 12) {
        self.segments = segments
        points = []
        iterations = 30
        
        let distance = sqrt(
            pow(end.x - start.x, 2) +
            pow(end.y - start.y, 2)
        )
        
        // Calculate ideal segment length with minimum constraint
        let idealLength = max(distance / CGFloat(segments - 1), minSegmentLength)
        // Add some slack based on distance
        let slack = min(maxSag, distance * 0.2) // 20% slack, but not more than maxSag
        self.segmentLength = idealLength + (slack / CGFloat(segments))
        
        let delta = CGVector(
            dx: (end.x - start.x) / CGFloat(segments - 1),
            dy: (end.y - start.y) / CGFloat(segments - 1)
        )
        
        // Initialize points with a natural curve
        for i in 0..<segments {
            let progress = CGFloat(i) / CGFloat(segments - 1)
            let sag = sin(progress * .pi) * slack
            
            let position = CGPoint(
                x: start.x + delta.dx * CGFloat(i),
                y: start.y + delta.dy * CGFloat(i) + sag
            )
            points.append(Point(
                position: position,
                velocity: .zero,
                isFixed: i == 0 || i == segments - 1
            ))
        }
    }
    
    mutating func update() {
        let gravity: CGFloat = 0.3
        let damping: CGFloat = 0.95
        let wind: CGFloat = 0.02
        
        // Update physics for each point
        for i in 0..<points.count {
            points[i].update(gravity: gravity, damping: damping, wind: wind)
        }
        
        // Multiple passes of constraints for stability
        for _ in 0..<iterations {
            // Satisfy distance constraints
            for i in 0..<points.count - 1 {
                let p1 = points[i].position
                let p2 = points[i + 1].position
                
                let dx = p2.x - p1.x
                let dy = p2.y - p1.y
                let distance = sqrt(dx * dx + dy * dy)
                let difference = segmentLength - distance
                let percent = difference / distance / 2
                let offsetX = dx * percent
                let offsetY = dy * percent
                
                if !points[i].isFixed {
                    points[i].position.x -= offsetX * 1.2
                    points[i].position.y -= offsetY * 1.2
                }
                
                if !points[i + 1].isFixed {
                    points[i + 1].position.x += offsetX * 1.2
                    points[i + 1].position.y += offsetY * 1.2
                }
            }
            
            // Add slight tension to make string more taut
            for i in 1..<points.count - 1 {
                let prev = points[i - 1].position
                let curr = points[i].position
                let next = points[i + 1].position
                
                let tension: CGFloat = 0.15
                points[i].position.x += (prev.x + next.x - 2 * curr.x) * tension
                points[i].position.y += (prev.y + next.y - 2 * curr.y) * tension
            }
        }
    }
    
    func path() -> Path {
        var path = Path()
        guard points.count >= 2 else { return path }
        
        // Use Catmull-Rom spline for smooth curves
        path.move(to: points[0].position)
        
        for i in 1..<points.count - 2 {
            let p0 = i > 0 ? points[i - 1].position : points[i].position
            let p1 = points[i].position
            let p2 = points[i + 1].position
            let p3 = i < points.count - 2 ? points[i + 2].position : p2
            
            for t in stride(from: 0, to: 1, by: 0.1) {
                let t2 = t * t
                let t3 = t2 * t
                
                let x = 0.5 * ((2.0 * p1.x) +
                              (-p0.x + p2.x) * t +
                              (2.0 * p0.x - 5.0 * p1.x + 4.0 * p2.x - p3.x) * t2 +
                              (-p0.x + 3.0 * p1.x - 3.0 * p2.x + p3.x) * t3)
                
                let y = 0.5 * ((2.0 * p1.y) +
                              (-p0.y + p2.y) * t +
                              (2.0 * p0.y - 5.0 * p1.y + 4.0 * p2.y - p3.y) * t2 +
                              (-p0.y + 3.0 * p1.y - 3.0 * p2.y + p3.y) * t3)
                
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        
        path.addLine(to: points[points.count - 1].position)
        return path
    }
    
    mutating func updateEndPoints(start: CGPoint, end: CGPoint) {
        guard points.count >= 2 else { return }
        
        // Calculate new distance and update segment length if needed
        let distance = sqrt(
            pow(end.x - start.x, 2) +
            pow(end.y - start.y, 2)
        )
        let idealLength = max(distance / CGFloat(segments - 1), minSegmentLength)
        let slack = min(maxSag, distance * 0.2)
        self.segmentLength = idealLength + (slack / CGFloat(segments))
        
        // Calculate the movement delta
        let startDelta = CGVector(
            dx: start.x - points[0].position.x,
            dy: start.y - points[0].position.y
        )
        let endDelta = CGVector(
            dx: end.x - points[points.count - 1].position.x,
            dy: end.y - points[points.count - 1].position.y
        )
        
        // Update end points
        points[0].position = start
        points[points.count - 1].position = end
        
        // Propagate movement to nearby points with falloff
        let falloffFactor: CGFloat = 0.8
        for i in 1..<points.count - 1 {
            let startInfluence = CGFloat(points.count - 1 - i) / CGFloat(points.count - 1)
            let endInfluence = CGFloat(i) / CGFloat(points.count - 1)
            
            let deltaX = startDelta.dx * startInfluence + endDelta.dx * endInfluence
            let deltaY = startDelta.dy * startInfluence + endDelta.dy * endInfluence
            
            points[i].applyForce(CGVector(
                dx: deltaX * falloffFactor,
                dy: deltaY * falloffFactor
            ))
        }
    }
}

struct StringView: View {
    let fromPoint: CGPoint
    let toPoint: CGPoint
    let color: Color
    @State private var physicsString: PhysicsString
    @State private var displayLink: DisplayLink?
    
    init(from: CGPoint, to: CGPoint, color: Color) {
        self.fromPoint = from
        self.toPoint = to
        self.color = color
        self._physicsString = State(initialValue: PhysicsString(start: from, end: to))
    }
    
    var body: some View {
        Canvas { context, size in
            // Draw shadow first
            context.withCGContext { cgContext in
                cgContext.setShadow(
                    offset: CGSize(width: 1, height: 1),
                    blur: 2,
                    color: CGColor(gray: 0, alpha: 0.2)
                )
                
                // Draw string with shadow
                let path = physicsString.path().cgPath
                cgContext.addPath(path)
                cgContext.setStrokeColor(color.opacity(0.8).cgColor!)
                cgContext.setLineWidth(2)
                cgContext.setLineCap(.round)
                cgContext.setLineJoin(.round)
                cgContext.strokePath()
            }
        }
        .onChange(of: fromPoint) { _, newValue in
            physicsString.updateEndPoints(start: newValue, end: toPoint)
        }
        .onChange(of: toPoint) { _, newValue in
            physicsString.updateEndPoints(start: fromPoint, end: newValue)
        }
        .onAppear {
            displayLink = DisplayLink(preferredFramesPerSecond: 60) {
                physicsString.update()
            }
        }
        .onDisappear {
            displayLink = nil
        }
    }
}

// Helper class for smooth animation
private class DisplayLink {
    private var displayLink: CVDisplayLink?
    private var callback: () -> Void
    
    init(preferredFramesPerSecond: Int = 60, callback: @escaping () -> Void) {
        self.callback = callback
        setupDisplayLink()
    }
    
    deinit {
        if let displayLink = displayLink {
            CVDisplayLinkStop(displayLink)
        }
    }
    
    private func setupDisplayLink() {
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        
        let opaqueself = Unmanaged.passUnretained(self).toOpaque()
        
        CVDisplayLinkSetOutputCallback(
            displayLink!,
            { (displayLink, _, _, _, _, opaquePointer) -> CVReturn in
                let self_ = Unmanaged<DisplayLink>.fromOpaque(opaquePointer!).takeUnretainedValue()
                DispatchQueue.main.async {
                    self_.callback()
                }
                return kCVReturnSuccess
            },
            opaqueself
        )
        
        CVDisplayLinkStart(displayLink!)
    }
} 