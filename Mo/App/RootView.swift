//
//  RootView.swift
//  糯
//
//  屏幕就是一张桌子。桌子上只有一坨东西。
//  没有文字、没有按钮、没有其他任何东西。
//

import SwiftUI
import UIKit

struct RootView: View {

    var body: some View {
        ZStack {
            desk
            BlobView()
                .ignoresSafeArea()
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    private var desk: some View {
        ZStack {
            LinearGradient(
                colors: [Palette.deskTop, Palette.deskBottom],
                startPoint: .top,
                endPoint: .bottom
            )

            // 左上打下来的一束光，落成一片光池
            RadialGradient(
                colors: [Color.white.opacity(0.055), .clear],
                center: UnitPoint(x: 0.24, y: 0.10),
                startRadius: 0,
                endRadius: 520
            )

            // 物件周围的一圈微弱反光
            RadialGradient(
                colors: [Color.white.opacity(0.030), .clear],
                center: UnitPoint(x: 0.5, y: 0.45),
                startRadius: 0,
                endRadius: 320
            )
        }
        .ignoresSafeArea()
    }
}

#Preview {
    RootView()
        .preferredColorScheme(.dark)
}
