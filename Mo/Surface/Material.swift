//
//  Material.swift
//  摸 Mo
//
//  十种材质。每一种就是一组参数：视觉的颗粒、触感的性格。
//  没有名字，没有文字 —— 你只能靠手分辨。
//

import SwiftUI

// MARK: - 视觉颗粒

enum Grain {
    /// 平行的丝缕（丝绸、毛线）
    case lines(density: CGFloat, angle: CGFloat)
    /// 细密的随机颗粒（砂纸、湿沙、锡纸）
    case noise(density: CGFloat, contrast: CGFloat)
    /// 一颗一颗的实体（玻璃珠、鹅卵石）
    case dots(density: CGFloat, radius: CGFloat)
    /// 短促的纤维（天鹅绒、苔藓）
    case fibers(density: CGFloat)
    /// 同心弧（冰）
    case arcs(frequency: CGFloat)
}

// MARK: - 触感性格

struct HapticProfile {
    /// 静止按住时的底噪
    var base: Float
    /// 锐利度：越高越"刺"，越低越"闷"
    var sharpness: Float
    /// 速度对强度的贡献
    var speedGain: Float
    /// 每 100 点位移产生几颗粒
    var grainRate: Double
    /// 颗粒的强度
    var grainStrength: Float
    /// 颗粒的锐利度
    var grainSharpness: Float
    /// 低速时是否反而更"粘"（湿的东西）
    var sticky: Bool
}

// MARK: - 材质

struct Material: Identifiable {
    let id: Int
    let base: Color
    let accent: Color
    let grain: Grain
    let profile: HapticProfile
}

extension Material {

    static let all: [Material] = [

        // 1 丝绸：几乎无声地滑过去
        Material(id: 0, base: Color(hex: 0x0E0F14), accent: Color(hex: 0x7C87A8),
                 grain: .lines(density: 0.55, angle: -0.35),
                 profile: HapticProfile(base: 0.10, sharpness: 0.30, speedGain: 0.18,
                                        grainRate: 0, grainStrength: 0, grainSharpness: 0, sticky: false)),

        // 2 砂纸：细密的刺
        Material(id: 1, base: Color(hex: 0x3A3128), accent: Color(hex: 0xE8C98A),
                 grain: .noise(density: 0.9, contrast: 0.55),
                 profile: HapticProfile(base: 0.22, sharpness: 0.92, speedGain: 0.34,
                                        grainRate: 6, grainStrength: 0.18, grainSharpness: 0.95, sticky: false)),

        // 3 玻璃珠：一颗一颗滚过去
        Material(id: 2, base: Color(hex: 0x0D1216), accent: Color(hex: 0xA8E0F2),
                 grain: .dots(density: 1.6, radius: 5),
                 profile: HapticProfile(base: 0.14, sharpness: 0.70, speedGain: 0.22,
                                        grainRate: 14, grainStrength: 0.42, grainSharpness: 0.80, sticky: false)),

        // 4 湿沙：被水压住的颗粒
        Material(id: 3, base: Color(hex: 0x2B2A26), accent: Color(hex: 0x9C9483),
                 grain: .noise(density: 1.2, contrast: 0.32),
                 profile: HapticProfile(base: 0.26, sharpness: 0.42, speedGain: 0.26,
                                        grainRate: 9, grainStrength: 0.22, grainSharpness: 0.45, sticky: true)),

        // 5 链条：重的、有间隔的咔哒
        Material(id: 4, base: Color(hex: 0x14161A), accent: Color(hex: 0xB6BEC9),
                 grain: .dots(density: 0.5, radius: 13),
                 profile: HapticProfile(base: 0.16, sharpness: 0.50, speedGain: 0.20,
                                        grainRate: 5, grainStrength: 0.68, grainSharpness: 0.55, sticky: false)),

        // 6 天鹅绒：几乎摸不到阻力
        Material(id: 5, base: Color(hex: 0x1A0E14), accent: Color(hex: 0x8E3556),
                 grain: .fibers(density: 1.4),
                 profile: HapticProfile(base: 0.08, sharpness: 0.12, speedGain: 0.14,
                                        grainRate: 0, grainStrength: 0, grainSharpness: 0, sticky: false)),

        // 7 冰：平滑，偶尔一声脆响
        Material(id: 6, base: Color(hex: 0x0B1418), accent: Color(hex: 0xBFEFF7),
                 grain: .arcs(frequency: 9),
                 profile: HapticProfile(base: 0.12, sharpness: 0.86, speedGain: 0.20,
                                        grainRate: 2.2, grainStrength: 0.55, grainSharpness: 0.98, sticky: false)),

        // 8 苔藓：软的，有弹性，没有刺
        Material(id: 7, base: Color(hex: 0x101710), accent: Color(hex: 0x6C8C42),
                 grain: .fibers(density: 2.2),
                 profile: HapticProfile(base: 0.16, sharpness: 0.10, speedGain: 0.10,
                                        grainRate: 3, grainStrength: 0.12, grainSharpness: 0.08, sticky: true)),

        // 9 鹅卵石：圆、硬、一颗一颗顶着指腹
        Material(id: 8, base: Color(hex: 0x191A1C), accent: Color(hex: 0xA69D91),
                 grain: .dots(density: 0.36, radius: 22),
                 profile: HapticProfile(base: 0.20, sharpness: 0.38, speedGain: 0.18,
                                        grainRate: 3.2, grainStrength: 0.50, grainSharpness: 0.30, sticky: false)),

        // 10 锡纸：又脆又皱，随时会折
        Material(id: 9, base: Color(hex: 0x16181C), accent: Color(hex: 0xD6DEE8),
                 grain: .noise(density: 2.0, contrast: 0.75),
                 profile: HapticProfile(base: 0.20, sharpness: 0.88, speedGain: 0.30,
                                        grainRate: 18, grainStrength: 0.34, grainSharpness: 0.92, sticky: false))
    ]
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
