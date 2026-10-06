# 丸子定制版本

- 版本号：0.1.0
- 版本编号：WZ-GOTY-001
- 窗口标题、启动画面和主菜单使用统一版本标识。
- 原 PopCap 启动闪屏改为中央“WanZi Family”标记，使用深绿底、金色边框和淡入淡出。
- 定制程序为 `dist/windows-x64/pvz-wanzi.exe`；`Start-Game.cmd` 已指向该程序。
- 外观：深绿色半透明铭牌、金色描边，版本号与编号作为第二行。
- 标识定义：src/EditionBranding.h。
- 绘制实现：src/EditionBranding.cpp。
- 定制名称与启动文字使用嵌入代码的固定文字位图，Windows、iPhone、iPad 共用，不依赖运行设备的系统字体。原版字体文件不变。
- 固定文字数据：src/EditionBrandingAssets.h；需要更名时，在 Windows 上运行 scripts/windows/Generate-Branding.ps1 重新生成。
- 标识代表本地定制分支，不改变原版及上游的版权归属。

Windows Release 构建通过。iOS 构建与安装说明见 IOS.zh-CN.md；编译通过不代表已经完成苹果设备上的试玩验证。
