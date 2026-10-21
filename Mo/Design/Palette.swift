//
//  Palette.swift
//  糯
//

import SwiftUI

enum Palette {
    static let deskTop    = Color(hex: 0x15161A)
    static let deskBottom = Color(hex: 0x050506)
    static let body       = Color(hex: 0x0A0B0D)
    static let core       = Color(hex: 0x7A2E0E)
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
