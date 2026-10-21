//
//  FrameDriver.swift
//  糯
//

import QuartzCore
import Observation

@Observable
final class FrameDriver {

    @ObservationIgnored var onFrame: ((Double) -> Void)?

    @ObservationIgnored private var link: CADisplayLink?
    @ObservationIgnored private var proxy: Proxy?
    @ObservationIgnored private var lastTime: CFTimeInterval = 0

    private final class Proxy: NSObject {
        let action: () -> Void
        init(_ action: @escaping () -> Void) { self.action = action }
        @objc func fire() { action() }
    }

    func start() {
        guard link == nil else { return }
        let proxy = Proxy { [weak self] in self?.step() }
        self.proxy = proxy

        let link = CADisplayLink(target: proxy, selector: #selector(Proxy.fire))
        // 每帧都要重画带模糊的图层，60 帧足够，也更省电
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60, preferred: 60)
        link.add(to: .main, forMode: .common)
        self.link = link

        lastTime = CACurrentMediaTime()
    }

    func stop() {
        link?.invalidate()
        link = nil
        proxy = nil
    }

    private func step() {
        let now = CACurrentMediaTime()
        let dt = min(max(now - lastTime, 0), 1.0 / 30.0)
        lastTime = now
        onFrame?(dt)
    }
}
