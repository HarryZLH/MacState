# MacState 性能监控

基于 [Better Mac Stats](https://github.com/ariwisnu/better-mac-stats) 的非官方简体中文版，使用 MIT 开源协议。

菜单栏监控 CPU、GPU、内存、磁盘、网络、电池、传感器、蓝牙和世界时钟。

## 下载与运行

在 [Releases](https://github.com/HarryZLH/MacState/releases/latest) 下载压缩包，解压后将 **MacState 性能监控.app** 移入应用程序目录。
当前本地发行包面向 Apple Silicon（M1 及更新），要求 macOS 12 或更新。
应用采用本地临时签名，未经 Apple 公证。首次打开若被系统拦截，请在系统设置 → 隐私与安全性中检查并允许打开。

## 编译

安装完整 Xcode 和命令行开发工具后：

```sh
bash Scripts/build.sh
# 可选：UNIVERSAL=1 bash Scripts/build.sh
```

产物位于 `dist/MacState 性能监控.app`。当前发行版本：0.1.3。

## 来源和许可证

Copyright (c) 2026 Putu Ari Wisnu and Better Mac Stats contributors。
保留上游完整 [MIT 许可证](LICENSE)，应用资源和发行包也附带该许可证。
修改内容和上游版本见 [NOTICE.md](NOTICE.md)，原始英文说明见 [README.upstream.md](README.upstream.md)。
此项目是独立衍生版本，不代表原作者发布或背书。

## 语言设置

在设置 → 通用 → 语言中，默认勾选“跟随系统语言”。取消勾选可手动选择简体中文或英语，切换即时生效。暂不支持的系统语言使用英语。外观跟随系统深浅色模式。

菜单栏监控面板使用 AppKit 原生 NSMenu，背景、圆角、边缘与阴影由系统绘制。
