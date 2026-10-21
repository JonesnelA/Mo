//
//  TextureFactory.swift
//  摸 Mo
//
//  每种材质的底图都是当场用 Core Graphics 画出来的 —— 不打包任何图片资源。
//  一张 720×1440 大概 20~60ms，切过去的时候不会卡。
//

import UIKit
import SwiftUI

enum TextureFactory {

    private static let size = CGSize(width: 720, height: 1440)
    private static let cache = NSCache<NSNumber, UIImage>()

    static func texture(for material: Material) -> UIImage {
        let key = NSNumber(value: material.id)
        if let cached = cache.object(forKey: key) { return cached }

        let image = render(material)
        cache.setObject(image, forKey: key)
        return image
    }

    private static func render(_ material: Material) -> UIImage {
        let accent = UIColor(material.accent)
        let base = UIColor(material.base)
        let w = size.width
        let h = size.height
        let area = w * h

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let cg = context.cgContext

            cg.setFillColor(base.cgColor)
            cg.fill(CGRect(origin: .zero, size: size))

            switch material.grain {

            case let .lines(density, angle):
                cg.saveGState()
                cg.translateBy(x: w / 2, y: h / 2)
                cg.rotate(by: angle)
                let span = w + h
                var x = -span
                while x < span {
                    cg.setStrokeColor(accent.withAlphaComponent(.random(in: 0.03...0.20)).cgColor)
                    cg.setLineWidth(.random(in: 0.6...2.0))
                    cg.move(to: CGPoint(x: x, y: -span))
                    cg.addLine(to: CGPoint(x: x, y: span))
                    cg.strokePath()
                    x += CGFloat(density) * .random(in: 3...7)
                }
                cg.restoreGState()

                // 一点横向的褶皱，让丝面不是纯条纹
                cg.saveGState()
                cg.translateBy(x: w / 2, y: h / 2)
                cg.rotate(by: angle + 0.9)
                var y = -span
                while y < span {
                    cg.setStrokeColor(accent.withAlphaComponent(.random(in: 0.012...0.05)).cgColor)
                    cg.setLineWidth(.random(in: 6...26))
                    cg.move(to: CGPoint(x: -span, y: y))
                    cg.addLine(to: CGPoint(x: span, y: y))
                    cg.strokePath()
                    y += CGFloat.random(in: 40...120)
                }
                cg.restoreGState()

            case let .noise(density, contrast):
                let count = min(Int(area * 0.022 * density), 70_000)
                for _ in 0..<count {
                    let x = CGFloat.random(in: 0...w)
                    let y = CGFloat.random(in: 0...h)
                    let s = CGFloat.random(in: 0.8...2.6)
                    cg.setFillColor(accent.withAlphaComponent(.random(in: 0.03...(0.10 + 0.45 * contrast))).cgColor)
                    cg.fill(CGRect(x: x, y: y, width: s, height: s))
                }
                // 少量更亮的碎屑，制造"砂"的高光
                for _ in 0..<Int(Double(count) * 0.08) {
                    let x = CGFloat.random(in: 0...w)
                    let y = CGFloat.random(in: 0...h)
                    cg.setFillColor(UIColor.white.withAlphaComponent(.random(in: 0.05...0.22)).cgColor)
                    cg.fill(CGRect(x: x, y: y, width: 1.2, height: 1.2))
                }

            case let .dots(density, radius):
                let count = min(Int(area * 0.0016 * density), 9000)
                for _ in 0..<count {
                    let cx = CGFloat.random(in: -20...(w + 20))
                    let cy = CGFloat.random(in: -20...(h + 20))
                    let r = radius * .random(in: 0.6...1.35)

                    cg.setFillColor(accent.withAlphaComponent(.random(in: 0.10...0.34)).cgColor)
                    cg.fillEllipse(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))

                    // 球面高光
                    cg.setFillColor(UIColor.white.withAlphaComponent(.random(in: 0.06...0.20)).cgColor)
                    cg.fillEllipse(in: CGRect(x: cx - r * 0.45, y: cy - r * 0.55, width: r * 0.8, height: r * 0.55))
                }

            case let .fibers(density):
                let count = min(Int(area * 0.012 * density), 40_000)
                for _ in 0..<count {
                    let x = CGFloat.random(in: 0...w)
                    let y = CGFloat.random(in: 0...h)
                    let len = CGFloat.random(in: 4...16)
                    let a = CGFloat.random(in: -0.6...0.6)
                    cg.setStrokeColor(accent.withAlphaComponent(.random(in: 0.05...0.30)).cgColor)
                    cg.setLineWidth(CGFloat.random(in: 0.7...1.6))
                    cg.move(to: CGPoint(x: x, y: y))
                    cg.addLine(to: CGPoint(x: x + cos(a) * len, y: y + sin(a) * len))
                    cg.strokePath()
                }

            case let .arcs(frequency):
                let center = CGPoint(x: w * 0.38, y: h * 0.62)
                var r: CGFloat = 24
                var i = 0
                while r < max(w, h) * 1.2 {
                    let alpha = 0.05 + 0.12 * abs(sin(Double(i) * 0.7))
                    cg.setStrokeColor(accent.withAlphaComponent(alpha).cgColor)
                    cg.setLineWidth(CGFloat.random(in: 0.6...2.4))
                    cg.addArc(center: center, radius: r,
                              startAngle: CGFloat.random(in: 0...0.6),
                              endAngle: CGFloat.random(in: 5.4...6.28),
                              clockwise: false)
                    cg.strokePath()
                    r += CGFloat(240.0 / max(frequency, 1)) * .random(in: 0.6...1.5)
                    i += 1
                }
            }

            // 统一的暗角，让四周沉下去
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                         colors: [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.55).cgColor] as CFArray,
                                         locations: [0.45, 1.0]) {
                cg.drawRadialGradient(gradient,
                                      startCenter: CGPoint(x: w / 2, y: h * 0.42), startRadius: 0,
                                      endCenter: CGPoint(x: w / 2, y: h * 0.42), endRadius: max(w, h) * 0.78,
                                      options: [])
            }
        }
    }
}
