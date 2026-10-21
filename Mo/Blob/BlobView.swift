//
//  BlobView.swift
//  糯
//
//  一坨坐在桌面上的软体。全部用 Core Graphics 画：
//  投影 → 本体 → 体积光 → 底部内阴影 → 边缘反光 → 高光 → 透光的暖芯
//

import SwiftUI
import QuartzCore

// MARK: - 轮廓

enum BlobGeometry {

    static func path(center: CGPoint,
                     radius: CGFloat,
                     dentAngle: Double,
                     dentDepth: Double,
                     wobble: Double,
                     wobblePhase: Double,
                     time: Double) -> Path {

        let count = 190
        var points: [CGPoint] = []
        points.reserveCapacity(count)

        for index in 0..<count {
            let a = Double(index) / Double(count) * 2 * .pi

            // 静息时就不规则，别像模具压出来的
            var r = 1.0
            r += 0.013 * sin(3 * a + 1.3)
            r += 0.008 * sin(5 * a - 0.8 + time * 0.22)
            r += 0.006 * sin(2 * a + time * 0.15)

            // 松手之后的晃
            r += wobble * 0.05 * sin(3 * a + wobblePhase)

            // 手指压出来的坑 + 对面鼓出来（体积守恒）
            if dentDepth > 0.001 {
                let d = angularDistance(a, dentAngle)
                r -= dentDepth * 0.30 * exp(-pow(d / 0.48, 2))
                let o = angularDistance(a, dentAngle + .pi)
                r += dentDepth * 0.09 * exp(-pow(o / 0.75, 2))
            }

            points.append(CGPoint(
                x: center.x + CGFloat(cos(a) * r) * radius,
                y: center.y + CGFloat(sin(a) * r) * radius * 0.94
            ))
        }

        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        for index in 1..<points.count {
            let previous = points[index - 1]
            let current = points[index]
            let mid = CGPoint(x: (previous.x + current.x) / 2,
                              y: (previous.y + current.y) / 2)
            path.addQuadCurve(to: mid, control: previous)
        }
        path.closeSubpath()
        return path
    }

    static func angularDistance(_ a: Double, _ b: Double) -> Double {
        abs(atan2(sin(a - b), cos(a - b)))
    }
}

// MARK: - 视图

struct BlobView: View {

    @State private var model = BlobModel()
    @State private var driver = FrameDriver()

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let center = CGPoint(x: width / 2, y: height * 0.45)
            let radius = min(width, height) * 0.265

            ZStack {
                Canvas { context, _ in
                    draw(&context, center: center, radius: radius)
                }
                .contentShape(Rectangle())
                .gesture(gesture(center: center, radius: radius))
            }
            .frame(width: width, height: height)
        }
        .onAppear {
            driver.onFrame = { dt in model.advance(dt) }
            driver.start()
        }
        .onDisappear { driver.stop() }
    }

    // MARK: 手势

    private func gesture(center: CGPoint, radius: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                let offset = CGPoint(x: value.location.x - center.x,
                                     y: value.location.y - center.y)
                if model.touching {
                    model.move(to: offset, radius: radius)
                } else {
                    model.begin(at: offset, radius: radius)
                }
            }
            .onEnded { _ in
                model.end()
            }
    }

    // MARK: 绘制

    private func draw(_ ctx: inout GraphicsContext, center: CGPoint, radius: CGFloat) {
        let path = BlobGeometry.path(
            center: center,
            radius: radius,
            dentAngle: model.dentAngle,
            dentDepth: model.press,
            wobble: model.wobble,
            wobblePhase: model.wobblePhase,
            time: model.time
        )

        let bounds = CGRect(x: center.x - radius * 1.7,
                            y: center.y - radius * 1.7,
                            width: radius * 3.4,
                            height: radius * 3.4)

        // 1 落在桌面上的影子
        ctx.drawLayer { layer in
            layer.addFilter(.blur(radius: radius * 0.16))
            let rect = CGRect(x: center.x - radius * 0.88,
                              y: center.y + radius * 0.64,
                              width: radius * 1.76,
                              height: radius * 0.30)
            layer.fill(Path(ellipseIn: rect), with: .color(.black.opacity(0.85)))
        }

        // 2 本体
        ctx.fill(path, with: .color(Color(hex: 0x0A0B0D)))

        // 3 体积：光从左上来
        ctx.drawLayer { layer in
            layer.clip(to: path)
            let light = CGPoint(x: center.x - radius * 0.46, y: center.y - radius * 0.56)
            layer.fill(Path(bounds), with: .radialGradient(
                Gradient(colors: [
                    Color(white: 0.34),
                    Color(white: 0.13),
                    Color(white: 0.03)
                ]),
                center: light,
                startRadius: 0,
                endRadius: radius * 1.55
            ))
        }

        // 4 底部贴着桌面的暗部
        ctx.drawLayer { layer in
            layer.clip(to: path)
            let below = CGPoint(x: center.x, y: center.y + radius * 1.10)
            layer.fill(Path(bounds), with: .radialGradient(
                Gradient(colors: [Color.black.opacity(0.80), Color.black.opacity(0)]),
                center: below,
                startRadius: 0,
                endRadius: radius * 1.30
            ))
        }

        // 5 边缘反光：左上亮、右下暗，这是"有厚度"的关键
        ctx.stroke(path, with: .linearGradient(
            Gradient(colors: [
                Color.white.opacity(0.55),
                Color.white.opacity(0.04),
                Color.black.opacity(0.55)
            ]),
            startPoint: CGPoint(x: center.x - radius, y: center.y - radius * 1.05),
            endPoint: CGPoint(x: center.x + radius, y: center.y + radius * 1.05)
        ), lineWidth: 1.6)

        // 6 大块柔光
        ctx.drawLayer { layer in
            layer.clip(to: path)
            layer.addFilter(.blur(radius: radius * 0.055))
            let rect = CGRect(x: center.x - radius * 0.56,
                              y: center.y - radius * 0.68,
                              width: radius * 0.60,
                              height: radius * 0.30)
            layer.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.42)))
        }

        // 7 锐利的小高光 —— 湿的
        ctx.drawLayer { layer in
            layer.clip(to: path)
            layer.addFilter(.blur(radius: radius * 0.010))
            let rect = CGRect(x: center.x - radius * 0.50,
                              y: center.y - radius * 0.62,
                              width: radius * 0.17,
                              height: radius * 0.09)
            layer.fill(Path(ellipseIn: rect), with: .color(.white.opacity(0.90)))
        }

        // 8 底部透出来的暖芯，像光穿过了半透明的胶
        ctx.drawLayer { layer in
            layer.clip(to: path)
            layer.addFilter(.blur(radius: radius * 0.20))
            let rect = CGRect(x: center.x - radius * 0.46,
                              y: center.y + radius * 0.34,
                              width: radius * 0.92,
                              height: radius * 0.44)
            layer.fill(Path(ellipseIn: rect), with: .color(Color(hex: 0x7A2E0E).opacity(0.35)))
        }
    }
}
