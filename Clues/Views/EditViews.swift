import SwiftUI
import SwiftData

struct PostItEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isShowing: Bool
    @Binding var title: String
    @FocusState private var isTitleFocused: Bool
    let color: Color
    let rotation: Double
    let onSave: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextEditor(text: $title)
                .font(.custom("Bradley Hand", size: 24, relativeTo: .headline))
                .foregroundStyle(.black)
                .scrollContentBackground(.hidden)
                .background(.clear)
                .focused($isTitleFocused)
                .frame(height: 120)
                .textEditorStyle(.plain)
                .scrollDisabled(true)
            
            Spacer()
            
            HStack {
                Spacer()
                
                Button(action: {
                    onSave()
                    withAnimation {
                        isShowing = false
                    }
                }) {
                    Text("Save")
                        .font(.custom("Bradley Hand", size: 16, relativeTo: .headline))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.1))
                        .cornerRadius(8)
                }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .frame(width: 250, height: 200)
        .background(color)
        .environment(\.colorScheme, .light)
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .shadow(color: .black.opacity(0.3), radius: 5, x: 3, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
        )
        .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 0, z: 1))
        .onAppear {
            isTitleFocused = true
        }
    }
}

struct TapeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Start from top-left
        path.move(to: CGPoint(x: 0, y: 0))
        
        // Top edge (straight)
        path.addLine(to: CGPoint(x: rect.maxX, y: 0))
        
        // Right edge (jagged)
        let jaggedCount = 4
        let segmentHeight = rect.height / CGFloat(jaggedCount)
        let jaggedWidth: CGFloat = 2
        
        for i in 0...jaggedCount {
            let y = CGFloat(i) * segmentHeight
            let x = i % 2 == 0 ? rect.maxX : rect.maxX - jaggedWidth
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        // Bottom edge (straight)
        path.addLine(to: CGPoint(x: 0, y: rect.maxY))
        
        // Left edge (jagged)
        for i in (0...jaggedCount).reversed() {
            let y = CGFloat(i) * segmentHeight
            let x = i % 2 == 0 ? 0 : jaggedWidth
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        // Close the path
        path.closeSubpath()
        
        return path
    }
}

struct TapeEditView: View {
    @Binding var isShowing: Bool
    @Binding var title: String
    @FocusState private var isTitleFocused: Bool
    @State private var rotation: Double = 0
    let onSave: () -> Void
    
    var body: some View {
        HStack {
            TextField("Image Label", text: $title)
                .font(.custom("Bradley Hand", size: 24))
                .foregroundStyle(.black.opacity(0.8))
                .focused($isTitleFocused)
                .textFieldStyle(.plain)
            
            Button("Save") {
                onSave()
                withAnimation {
                    isShowing = false
                }
            }
            .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .buttonStyle(.plain)
            .font(.custom("Bradley Hand", size: 16))
            .foregroundStyle(.black.opacity(0.8))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.1))
            .cornerRadius(8)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 20)
        .frame(width: 400)
        .background(
            SerratedRectangle()
                .fill(.white.opacity(0.8))
                .shadow(color: .black.opacity(0.2), radius: 2, x: 1, y: 1)
        )
        .rotationEffect(.degrees(rotation))
        .onAppear {
            rotation = Double.random(in: -2...2)
            isTitleFocused = true
        }
    }
}

struct SerratedRectangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Start from top-left
        path.move(to: CGPoint(x: 0, y: 0))
        
        // Top edge
        path.addLine(to: CGPoint(x: rect.maxX, y: 0))
        
        // Right edge with serrated pattern
        let teethCount = Int(rect.height / 3) // One tooth every 3 points
        let toothHeight: CGFloat = rect.height / CGFloat(teethCount)
        let toothWidth: CGFloat = 2.0
        
        for i in 0..<teethCount {
            let y = CGFloat(i) * toothHeight
            if i % 2 == 0 {
                path.addLine(to: CGPoint(x: rect.maxX + toothWidth, y: y))
            } else {
                path.addLine(to: CGPoint(x: rect.maxX, y: y))
            }
        }
        
        // Bottom edge
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: 0, y: rect.maxY))
        
        // Left edge with serrated pattern
        for i in (0...teethCount).reversed() {
            let y = CGFloat(i) * toothHeight
            if i % 2 == 0 {
                path.addLine(to: CGPoint(x: -toothWidth, y: y))
            } else {
                path.addLine(to: CGPoint(x: 0, y: y))
            }
        }
        
        return path
    }
} 