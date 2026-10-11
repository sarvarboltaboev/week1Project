import SwiftUI

// Figma variables (file ePZsW0Uss1FlcDlb7wQ0d3).
extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }

    static let textPrimary = Color.black
    static let textSecondary = Color(hex: 0x161D35, alpha: 0.4)
    static let textAccent = Color(hex: 0x7DC023)
    static let textAlert = Color(hex: 0xEA2924)
    static let textWarning = Color(hex: 0xD76D16)
    static let borderPrimary = Color.black.opacity(0.1)
    static let surfaceGrey20 = Color(hex: 0xF5F6F9)
    static let surfaceGrey30 = Color(hex: 0xE9EBF0)
    static let surfaceOrange30 = Color(hex: 0xFDB980)
    static let navbarBackground = Color.white.opacity(0.9)
}

// ponytail: system font stands in for Inter; bundle Inter .ttf if pixel parity matters.
extension Font {
    static let titleXL = Font.system(size: 24, weight: .heavy)   // title-xl
    static let titleL = Font.system(size: 18, weight: .bold)     // title-l
    static let bodyXXL = Font.system(size: 16, weight: .semibold) // body-xxl
    static let bodyL = Font.system(size: 14, weight: .bold)      // body-l
    static let bodyM = Font.system(size: 14, weight: .semibold)  // body-m
    static let bodyS = Font.system(size: 14, weight: .medium)    // body-s
    static let captionM = Font.system(size: 12, weight: .semibold) // caption-m
    static let captionS = Font.system(size: 10, weight: .semibold) // caption-s
}
