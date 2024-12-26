import SwiftUI
import SwiftData

struct NewFloatingPostIt: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isShowing: Bool
    @State private var title = ""
    @FocusState private var isTitleFocused: Bool
    @State private var noteColorIndex: Int
    @State private var noteRotation: Double
    let colors: [Color]
    let onPostItAdded: () -> Void
    
    init(isShowing: Binding<Bool>, colors: [Color], onPostItAdded: @escaping () -> Void) {
        self._isShowing = isShowing
        self.colors = colors
        self.onPostItAdded = onPostItAdded
        self._noteColorIndex = State(initialValue: Int.random(in: 0...5))
        self._noteRotation = State(initialValue: Double.random(in: -2...2))
    }
    
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
                
                Button("Save") {
                    let item = Item(
                        title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                        position: CGPoint(x: 200, y: 200)
                    )
                    item.color = noteColorIndex
                    item.rotation = noteRotation
                    
                    modelContext.insert(item)
                    onPostItAdded()
                    withAnimation {
                        isShowing = false
                    }
                }
                .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .buttonStyle(.plain)
                .font(.custom("Bradley Hand", size: 16, relativeTo: .headline))
                .foregroundStyle(.black)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(20)
        .frame(width: 250, height: 200)
        .background(colors[noteColorIndex])
        .environment(\.colorScheme, .light)
        .clipShape(RoundedRectangle(cornerRadius: 3))
        .shadow(color: .black.opacity(0.3), radius: 5, x: 3, y: 3)
        .overlay(
            RoundedRectangle(cornerRadius: 3)
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
        )
        .rotation3DEffect(.degrees(noteRotation), axis: (x: 0, y: 0, z: 1))
        .onAppear {
            isTitleFocused = true
        }
    }
} 