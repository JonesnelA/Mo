# 糯

一坨坐在桌面上的软东西。按下去会陷，松手会晃。没有文字、没有分数、没有声音。

全部用 Core Graphics 绘制：投影 → 本体 → 体积光 → 底部内阴影 → 边缘反光 → 柔光 → 锐利高光 → 透光暖芯。

触感是连续调制的一条低频震动（随压深变化），松手时一记三连衰减的"啵"。

## 出包

推到 GitHub 后 Actions 自动编译，产物 Mo-unsigned.ipa 在 Artifacts 里，用 Sideloadly 签名安装。

## 结构

Mo/
├─ App/    MoApp · RootView（桌面背景）
├─ Blob/   BlobModel（软体物理）· BlobView（轮廓与光照）
├─ Core/   Haptics · FrameDriver
└─ Design/ Palette
