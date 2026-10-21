//
//  RootView.swift
//  摸 Mo
//
//  一整块材质 + 底部一排小点。没有标题、没有名字、没有设置。
//  换材质就点一下小点，从左到右十个。
//

import SwiftUI
import UIKit

struct RootView: View {

    @State private var index = 0

    var body: some View {
        ZStack {
            MaterialSurface(material: Material.all[index])
                .id(index)
                .transition(.opacity)
                .ignoresSafeArea()

            VStack {
                Spacer()
                rail
                    .padding(.bottom, 16)
            }
        }
        .animation(.easeInOut(duration: 0.32), value: index)
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    private var rail: some View {
        HStack(spacing: 0) {
            ForEach(Material.all) { item in
                Capsule()
                    .fill(Color.white.opacity(item.id == index ? 0.88 : 0.26))
                    .frame(width: item.id == index ? 16 : 5, height: 5)
                    .frame(width: 26, height: 44)
                    .contentShape(Rectangle())
                    .onTapGesture { index = item.id }
            }
        }
        .padding(.horizontal, 12)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.30))
                .blur(radius: 14)
        )
    }
}

#Preview {
    RootView()
        .preferredColorScheme(.dark)
}
