import SwiftUI

extension Color {
    /// Returns a SwiftUI `Color` from a simple color name.
    static func from(name: String) -> Color {
        switch name.lowercased() {
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "blue": return .blue
        case "purple": return .purple
        default: return .green
        }
    }
}
