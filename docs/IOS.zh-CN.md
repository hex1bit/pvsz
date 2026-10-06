# Windows 开发、云端编译 iPhone / iPad 版本

日常修改 C++ 代码并在 Windows 测试游戏逻辑；真正的 iOS 编译由 GitHub Actions 的 macOS/Xcode 环境完成。

## 生成安装包

1. 推送代码到 hex1bit/pvsz 的 main 分支。修改 src、ios、CMake 或构建配置时自动触发独立的 Build iOS 工作流。
2. 也可打开 https://github.com/hex1bit/pvsz/actions/workflows/ios.yml ，点击 Run workflow，选择 main。
3. 成功后，在运行详情的 Artifacts 中下载 wanzi-family-ios-unsigned。
4. 解压后得到 wanzi-family-ios-arm64-unsigned.ipa、SHA256SUMS.txt、build-info.txt。校验文件记录安装包哈希；构建记录包含源码提交号。

首次构建需要安装依赖，后续构建使用缓存。安装包保留 14 天。失败日志可在运行详情查看。

## 当前配置

- 名称：WanZi Family。
- Bundle ID：io.github.hex1bit.pvsz.wanzi。
- 同时支持 iPhone 和 iPad，arm64，最低 iOS / iPadOS 16.4。
- 横屏，全屏，保留原版游戏逻辑；调试作弊与社区修复选项关闭。
- 游戏内中文版本标记和 WanZi Family 闪屏使用跨平台固定文字位图。
- Apple 原生启动屏同样显示 WanZi Family。
- IPA 未签名，不含 main.pak、个人存档或 Windows 工具链。

## 安装与资源

IPA 需要有效的 Apple 签名和描述文件才能安装。可在 Mac 的 Xcode 中使用个人账户部署到自己的设备；免费 Personal Team 有短期有效期限制。TestFlight 分发需要 Apple Developer Program。不要把账户密码、证书或私钥提交到 Git。

安装后通过文件 App 或电脑的设备文件共享，将自己拥有的 main.pak 放进 WanZi Family 的 Documents 根目录，然后重新启动游戏。当前已验证的年度版 main.pak 内含 properties 文件，因此无需另复制 properties 目录；其他资源版本可能需要该目录。

Windows 的 resources 和 runtime/saves 不会自动同步到手机。苹果端使用自己的沙盒目录。

## 本地 Mac 构建

安装完整 Xcode、CMake 和 vcpkg，设置 VCPKG_ROOT 后，在仓库根目录运行：

```bash
bash ios/build-ios.sh Release
```

输出位于 build-ios/wanzi-family-ios-arm64-unsigned.ipa。该脚本用于未签名构建；签名部署需要另配置自己的开发团队。

## 真机验收仍需完成

启动文字、资源加载、点击与拖动选卡/种植、不同屏幕比例、声音、后台切换、存档恢复以及完整关卡试玩。云端构建成功只能证明编译和打包通过。
