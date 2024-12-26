import SwiftUI

struct PopupModifier: ViewModifier {
    @Binding var isPresented: Bool
    let content: () -> AnyView
    
    func body(content: Content) -> some View {
        ZStack {
            content
            
            if isPresented {
                GeometryReader { geometry in
                    ZStack {
                        // Background overlay
                        Color.black
                            .opacity(0.2)
                            .background(.thinMaterial)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    isPresented = false
                                }
                            }
                        
                        // Centered content
                        self.content()
                            .position(
                                x: geometry.frame(in: .global).midX,
                                y: geometry.frame(in: .global).midY
                            )
                    }
                }
                .transition(.opacity)
                .ignoresSafeArea()
                .onKeyPress(.escape) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        isPresented = false
                    }
                    return .handled
                }
            }
        }
    }
}

extension View {
    func popup<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(PopupModifier(
            isPresented: isPresented,
            content: { AnyView(content()) }
        ))
    }
} 