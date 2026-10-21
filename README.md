# 摸 Mo

十种材质，一面屏。没有文字、没有分数、没有声音。

手指划过去，连续触感的强度和锐利度跟着材质与手速实时变化，
离散颗粒（玻璃珠、链条）按位移累积触发。

底部十个小点，从左到右：

1 丝绸 · 2 砂纸 · 3 玻璃珠 · 4 湿沙 · 5 链条
6 天鹅绒 · 7 冰 · 8 苔藓 · 9 鹅卵石 · 10 锡纸

## 出包

推到 GitHub 后 Actions 自动编译，产物 `Mo-unsigned.ipa` 在 Artifacts 里。
未签名，需要用 Sideloadly 配自己的 Apple ID 签一次。

## 结构

```
Mo/
├─ App/       MoApp · RootView（材质切换）
├─ Core/      Haptics（连续触感 + 离散颗粒）
└─ Surface/   Material（十种参数）· TextureFactory（程序化底图）· MaterialSurface
```
