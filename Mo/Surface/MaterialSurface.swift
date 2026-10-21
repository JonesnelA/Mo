//
//  MaterialSurface.swift
//  摸 Mo
//
//  一块可以摸的屏。手指在上面移动时，
//  连续触感的强度和锐利度跟着材质参数和手速实时变化，
//  离散颗粒按位移累积触发。
//

import SwiftUI
import QuartzCore

struct MaterialSurface: View {

    let material: Material

    @State private var image: UIImage?
    @State private var touch: CGPoint?
    @State private var lastPoint: CGPoint?
    @State private var lastTime: CFTimeInterval = 0
    @State private var speed: Double = 0
    @State private var grainAccumulator: Double = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.black

                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                }

                // 指腹下的光
                Canvas { context, size in
                    guard let touch else { return }
                    let r = min(size.width, size.height) * 0.40
                    let rect = CGRect(x: touch.x - r, y: touch.y - r, width: r * 2, height: r * 2)
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .radialGradient(
                            Gradient(colors: [
                                Color.white.opacity(0.17),
                                Color.white.opacity(0.05),
                                Color.white.opacity(0)
                            ]),
                            center: touch,
                            startRadius: 0,
                            endRadius: r
                        )
                    )
                }
                .blendMode(.plusLighter)
                .allowsHitTesting(false)

                // 材质边缘的暗角
                RadialGradient(
                    colors: [.clear, .black.opacity(0.55)],
                    center: .center,
                    startRadius: min(geo.size.width, geo.size.height) * 0.35,
                    endRadius: max(geo.size.width, geo.size.height) * 0.72
                )
                .allowsHitTesting(false)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .gesture(gesture)
        }
        .onAppear { image = TextureFactory.texture(for: material) }
    }

    private var gesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if touch == nil {
                    touch = value.location
                    lastPoint = value.location
                    lastTime = CACurrentMediaTime()
                    grainAccumulator = 0
                    speed = 0
                    Haptics.shared.beginTexture(material.profile)
                    Haptics.shared.updateTexture(intensity: material.profile.base,
                                                 sharpness: material.profile.sharpness)
                    return
                }

                let now = CACurrentMediaTime()
                let dt = max(now - lastTime, 1.0 / 240.0)
                lastTime = now

                let previous = lastPoint ?? value.location
                let distance = Double(hypot(value.location.x - previous.x,
                                            value.location.y - previous.y))
                let instant = distance / dt

                speed = speed * 0.55 + instant * 0.45
                lastPoint = value.location
                touch = value.location

                emit(distance: distance, speed: speed)
            }
            .onEnded { _ in
                Haptics.shared.stopTexture()
                touch = nil
                lastPoint = nil
                speed = 0
            }
    }

    private func emit(distance: Double, speed: Double) {
        let profile = material.profile
        let normalized = min(max(speed / 900.0, 0), 1)

        var intensity = profile.base + profile.speedGain * Float(normalized)
        // 湿的东西慢下来会更粘
        if profile.sticky && normalized < 0.12 {
            intensity += 0.10
        }
        Haptics.shared.updateTexture(intensity: intensity, sharpness: profile.sharpness)

        guard profile.grainRate > 0 else { return }
        let spacing = 100.0 / profile.grainRate
        grainAccumulator += distance

        var fired = 0
        while grainAccumulator >= spacing && fired < 10 {
            Haptics.shared.grain(strength: profile.grainStrength,
                                 sharpness: profile.grainSharpness)
            grainAccumulator -= spacing
            fired += 1
        }
    }
}
