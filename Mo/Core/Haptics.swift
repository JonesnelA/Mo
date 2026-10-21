//
//  Haptics.swift
//  糯
//
//  这一版只需要两种触感：
//  1. 按住时的一条低频连续震动 —— 像手指陷进一块软胶
//  2. 松手时的一记"啵" —— 三个快速衰减的瞬态，模拟回弹
//
//  不 import AVFoundation，全静音。
//

import CoreHaptics
import UIKit
import QuartzCore

final class Haptics {

    static let shared = Haptics()

    private var engine: CHHapticEngine?
    private var squishPlayer: CHHapticAdvancedPatternPlayer?
    private var boingPlayers: [CHHapticPatternPlayer] = []
    private var boingCursor = 0
    private var engineRunning = false

    private init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        guard let engine = try? CHHapticEngine() else { return }

        self.engine = engine
        engine.playsHapticsOnly = true
        engine.isAutoShutdownEnabled = false
        engine.resetHandler = { [weak self] in
            self?.engineRunning = false
            self?.startEngine()
            self?.rebuild()
        }
        engine.stoppedHandler = { [weak self] _ in
            self?.engineRunning = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { self?.startEngine() }
        }

        startEngine()
        rebuild()
    }

    private func startEngine() {
        guard let engine, !engineRunning else { return }
        do { try engine.start(); engineRunning = true } catch { engineRunning = false }
    }

    // MARK: 按住

    func beginSquish() {
        startEngine()
        guard let engine else { return }
        stopSquish()

        let event = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.16),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.06)
            ],
            relativeTime: 0,
            duration: 30
        )
        guard let pattern = try? CHHapticPattern(events: [event], parameters: []),
              let player = try? engine.makeAdvancedPlayer(with: pattern) else { return }

        player.loopEnabled = true
        squishPlayer = player
        try? player.start(atTime: CHHapticTimeImmediate)
    }

    func updateSquish(intensity: Float, sharpness: Float) {
        guard let squishPlayer else { return }
        try? squishPlayer.sendParameters([
            CHHapticDynamicParameter(parameterID: .hapticIntensityControl,
                                     value: max(0, min(1, intensity)), relativeTime: 0),
            CHHapticDynamicParameter(parameterID: .hapticSharpnessControl,
                                     value: max(0, min(1, sharpness)), relativeTime: 0)
        ], atTime: CHHapticTimeImmediate)
    }

    func stopSquish() {
        try? squishPlayer?.stop(atTime: CHHapticTimeImmediate)
        squishPlayer = nil
    }

    // MARK: 回弹

    /// 三连衰减：0ms / 55ms / 120ms，越来越轻 —— 听不见的"啵"
    func boing(strength: Float) {
        startEngine()
        let s = max(0.2, min(1, strength))

        guard let player = nextBoingPlayer() else {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: CGFloat(s))
            return
        }
        if (try? player.start(atTime: CHHapticTimeImmediate)) == nil {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: CGFloat(s))
        }
    }

    private func nextBoingPlayer() -> CHHapticPatternPlayer? {
        guard !boingPlayers.isEmpty else { return nil }
        let player = boingPlayers[boingCursor % boingPlayers.count]
        boingCursor += 1
        return player
    }

    private func rebuild() {
        guard let engine else { return }
        boingPlayers.removeAll()

        // 强度写死在 pattern 里，靠多个变体轮换
        for strength in [Float(1.0), 0.7, 0.45] {
            let events = [
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.75 * strength),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.10)
                ], relativeTime: 0),
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.42 * strength),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.14)
                ], relativeTime: 0.055),
                CHHapticEvent(eventType: .hapticTransient, parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.22 * strength),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.20)
                ], relativeTime: 0.12)
            ]
            if let pattern = try? CHHapticPattern(events: events, parameters: []),
               let player = try? engine.makePlayer(with: pattern) {
                boingPlayers.append(player)
            }
        }
    }
}
