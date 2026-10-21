//
//  MoApp.swift
//  摸 Mo
//
//  一个没有文字、没有目标、没有声音的触感样本册。
//

import SwiftUI

@main
struct MoApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
                .statusBarHidden(true)
                .persistentSystemOverlays(.hidden)
        }
    }
}
