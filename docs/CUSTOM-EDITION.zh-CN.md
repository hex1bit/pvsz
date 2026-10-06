# 丸子定制版本

- 版本号：0.1.0
- 版本编号：WZ-GOTY-001
- 窗口标题、启动画面和主菜单使用统一版本标识。
- 原 PopCap 启动闪屏改为中央“WanZi Family”标记，使用深绿底、金色边框和淡入淡出。
- 定制程序为 `dist/windows-x64/pvz-wanzi.exe`；`Start-Game.cmd` 已指向该程序。
- 外观：深绿色半透明铭牌、金色描边，版本号与编号作为第二行。
- 标识定义：src/EditionBranding.h。
- 绘制实现：src/EditionBranding.cpp。
- Windows 使用本机微软雅黑绘制定制名称，避免原版位图字体缺少“丸”字；字体不会随程序分发。
- 标识代表本地定制分支，不改变原版及上游的版权归属。

Release 构建通过。窗口标题与主菜单的初次验证发现缺字，已改为系统字体后重新构建。最终视图验证结果见 STATUS.zh-CN.md。
