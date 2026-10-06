# Windows 年度版复刻开发

## 基准

- 上游：https://github.com/wszqkzqk/PvZ-Portable
- 起始提交：848b1dddbe82a5976ee6005992b51bb8fa79b00c
- 行为对照：PC 年度版 1.2.0.1073；本机资源的版本、语言及差异见 docs/STATUS.zh-CN.md。
- Release 禁用调试作弊和社区原版 bug 修复，沿用原版规则。
- 上游 LICENSE、COPYING 和源码版权声明保留；原版资源不纳入源码或发布包。

## 本机工具链

工具安装在 `.tools/msys64`，不修改全局 PATH。使用 MSYS2 UCRT64 的 GCC、CMake、Ninja、SDL2、libpng、libjpeg-turbo、libopenmpt。

重新准备工具链时，从 https://www.msys2.org/docs/installer/ 获取官方基础压缩包，验证校验值，解压到 `.tools`，运行一次登录 shell，然后执行 `pacman -Syu --noconfirm`。更新核心组件若要求退出，重新打开 shell 继续更新。

依赖命令：

```sh
pacman -S --needed --noconfirm mingw-w64-ucrt-x86_64-cmake mingw-w64-ucrt-x86_64-gcc mingw-w64-ucrt-x86_64-libjpeg-turbo mingw-w64-ucrt-x86_64-libopenmpt mingw-w64-ucrt-x86_64-libpng mingw-w64-ucrt-x86_64-ninja mingw-w64-ucrt-x86_64-SDL2
```

## 构建与运行

在项目根目录打开 PowerShell：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/windows/Build.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/windows/Start.ps1
```

复制 `config/local.example.json` 为 `config/local.json` 并填写资源目录；本机已使用项目内的 `resources`，不再依赖桌面的原版文件夹。相对路径以项目根目录为准。启动脚本读取资源包，存档写入 `runtime/saves`，不导入或覆盖原版存档。

资源包内包含 properties 文件时可直接使用，无需解包。检查资源：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/windows/Test-Resources.ps1 -ResourceDirectory 'C:\Games\PlantsVsZombies'
```

传入 `Start.ps1 -Record` 可记录复刻程序操作供回放；这不能替代对原版的对照测试。Windows 程序输出在 `dist/windows-x64`，构建记录在 `build-info.json`。直接双击 exe 时会查找 exe 旁的资源；本机建议使用项目启动脚本。

## 验证原则

构建通过、进程存活、实际画面验证、关卡验证分别记录。没有实际完成的检查不得标记通过。先验证前十关，再检查全部模式，最后逐项修正行为与视听差异。验收清单见 docs/ACCEPTANCE.zh-CN.md。
