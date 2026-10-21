//
//  Haptics.swift
//  摸 Mo
//
//  核心不是"打点"，是"连续"。
//  手指按下去的那一刻开始播一条 30 秒的 continuous 事件（循环），
//  然后每帧用 sendParameters 调它的强度和锐利度 —— 于是震感会跟着材质、位置、手速连续变化。
//
//  离散的颗粒（玻璃珠、链条）另外用瞬态事件叠上去。
//  全程无音频：不 import AVFoundation。
//

import CoreHaptics
import UIKit
import QuartzCore

final class Haptics {

    static let shared = Haptics()

    private var engine: CHHapticEngine?
    private var texturePlayer: CHHapticAdvancedPatternPlayer?
    private var grainPlayers: [CHHapticPatternPlayer] = []
    private var grainCursor = 0
    private var engineRunning = false
    private var lastGrain: CFTimeInterval = 0

    private init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        guard let engine = try? CHHapticEngine() else { return }

        self.engine = engine
        engine.playsHapticsOnly = true
        engine.isAutoShutdownEnabled = false

        engine.resetHandler = { [weak self] in
            self?.engineRunning = false
            self?.startEngine()
            self?.rebuildGrainPlayers()
        }
        engine.stoppedHandler = { [weak self] _ in
            self?.engineRunning = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self?.startEngine()
            }
        }

        startEngine()
        rebuildGrainPlayers()
    }

    private func startEngine() {
        guard let engine, !engineRunning else { return }
        do {
            try engine.start()
            engineRunning = true
        } catch {
            engineRunning = false
        }
    }

    // MARK: - 连续纹理

    /// 手指落下：开始摩擦感
    func beginTexture(_ profile: HapticProfile) {
        startEngine()
        guard let engine else { return }
        stopTexture()

        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: profile.base),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: profile.sharpness)
            ],
            relativeTime: 0,
            duration: 30
        )

        guard let pattern = try? CHHapticPattern(events: [event], parameters: []),
              let player = try? engine.makeAdvancedPlayer(with: pattern) else { return }

        player.loopEnabled = true
        texturePlayer = player
        try? player.start(atTime: CHHapticTimeImmediate)
    }

    /// 每帧调用。intensity / sharpness 已经由调用方按手速算好
    func updateTexture(intensity: Float, sharpness: Float) {
        guard let texturePlayer else { return }
        let i = max(0, min(1, intensity))
        let s = max(0, min(1, sharpness))
        try? texturePlayer.sendParameters([
            CHHapticDynamicParameter(parameterID: .hapticIntensityControl, value: i, relativeTime: 0),
            CHHapticDynamicParameter(parameterID: .hapticSharpnessControl, value: s, relativeTime: 0)
        ], atTime: CHHapticTimeImmediate)
    }

    func stopTexture() {
        try? texturePlayer?.stop(atTime: CHHapticTimeImmediate)
        texturePlayer = nil
    }

    // MARK: - 离散颗粒

    func grain(strength: Float, sharpness: Float, minInterval: CFTimeInterval = 0.018) {
        let now = CACurrentMediaTime()
        guard now - lastGrain >= minInterval else { return }
        lastGrain = now
        startEngine()

        guard !grainPlayers.isEmpty else { return }
        let player = grainPlayers[grainCursor % grainPlayers.count]
        grainCursor += 1
        if (try? player.start(atTime: CHHapticTimeImmediate)) != nil { return }

        UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: CGFloat(max(0.2, min(1, strength))))
    }

    private func rebuildGrainPlayers() {
        guard let engine else { return }
        grainPlayers.removeAll()

        let specs: [(Float, Float)] = [(0.55, 0.35), (0.45, 0.70), (0.80, 0.85)]
        for (intensity, sharpness) in specs {
            let event = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                ],
                relativeTime: 0
            )
            for _ in 0..<2 {
                if let pattern = try? CHHapticPattern(events: [event], parameters: []),
                   let player = try? engine.makePlayer(with: pattern) {
                    grainPlayers.append(player)
                }
            }
        }
    }
}
