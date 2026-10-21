//
//  BlobModel.swift
//  糯
//
//  一坨软体的物理。只有四个量：
//  press（陷多深）、dent（从哪个方向陷）、wobble（松手后的晃）、time（静息呼吸）。
//

import Foundation
import Observation
import QuartzCore

@Observable
final class BlobModel {

    private(set) var press: Double = 0
    private(set) var dentAngle: Double = 0
    private(set) var wobble: Double = 0
    private(set) var wobblePhase: Double = 0
    private(set) var time: Double = 0
    private(set) var touching = false

    /// 手指相对中心的位置（点）
    private(set) var touchOffset: CGPoint = .zero

    @ObservationIgnored private var releaseSpeed: Double = 0

    // MARK: 每帧

    func advance(_ dt: Double) {
        time += dt

        if touching {
            // 按下去要有"软"的迟滞，不是瞬间到位
            press += (1 - press) * min(1, dt * 7)
        } else {
            // 回弹比按下快，带一点过冲感
            press += (0 - press) * min(1, dt * 15)
            if press < 0.002 { press = 0 }
        }

        wobble *= pow(0.90, dt * 60)
        wobblePhase += dt * 7.5
        if wobble < 0.001 { wobble = 0 }
    }

    // MARK: 输入

    func begin(at offset: CGPoint, radius: CGFloat) {
        touching = true
        touchOffset = offset
        if let angle = angleIfInside(offset, radius: radius) {
            dentAngle = angle
        }
        Haptics.shared.beginSquish()
        Haptics.shared.updateSquish(intensity: 0.16, sharpness: 0.06)
    }

    func move(to offset: CGPoint, radius: CGFloat) {
        guard touching else { return }
        touchOffset = offset
        if let angle = angleIfInside(offset, radius: radius) {
            dentAngle = angle
        }
        let depth = min(1, max(0, press))
        Haptics.shared.updateSquish(intensity: Float(0.14 + 0.46 * depth), sharpness: 0.06)
    }

    func end() {
        guard touching else { return }
        touching = false
        releaseSpeed = press
        // 松手：越深，晃得越明显
        wobble = min(1.0, 0.35 + releaseSpeed * 0.7)
        Haptics.shared.stopSquish()
        Haptics.shared.boing(strength: Float(min(1, 0.4 + releaseSpeed * 0.6)))
    }

    private func angleIfInside(_ offset: CGPoint, radius: CGFloat) -> Double? {
        let d = hypot(offset.x, offset.y)
        guard d < radius * 1.45 else { return nil }
        return atan2(Double(offset.y), Double(offset.x))
    }
}
