import Foundation
import CoreGraphics
import UniformTypeIdentifiers
import SwiftUI

extension UTType {
    static var todoBoard: UTType {
        UTType(importedAs: "dev.fka.clues", conformingTo: .data)
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
