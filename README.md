<div align="center">

# 🌙 虹月 AI Chat

**精致 · 本地优先 · 支持多 AI 群聊的 Flutter 对话应用**

青色主题 · 毛玻璃质感 · 兼容任意 OpenAI 风格接口

[![Flutter](https://img.shields.io/badge/Flutter-3.3+-14E2CE?logo=flutter)](https://flutter.dev)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-14E2CE)](LICENSE)

</div>

---

## ✨ 功能特性

- **多 AI 群聊** — 多个角色进同一个群，各自以独立人格发言、互相接话，而不是一个 AI 的多个分身。
- **角色卡** — 自定义人设、头像、采样参数与专属模型。
- **思考模式** — 一键开关推理深度（1-3 档）。
- **图片视觉** — 发图给支持 Vision 的模型，多模态开箱即用。
- **语音输入** — 说话即输入，轻量语音识别转文字。
- **上下文摘要** — 长对话自动压缩早期内容为摘要，省 token 又不丢脉络。
- **消息分支** — 重新生成 / 编辑保留历史版本，1/N 页码切换。
- **主题定制** — 青色主色、毛玻璃、OLED 纯黑、自定义壁纸。
- **本地优先** — 会话与密钥全部保存在本机，不上传第三方。

## 🚀 编译运行

需要先安装 [Flutter SDK](https://docs.flutter.dev/get-started/install)（3.3 以上）。

```bash
git clone https://github.com/WWRJ3321/IRISChat.git
cd IRISChat
flutter pub get
flutter build apk --release
```

产物在 `build/app/outputs/flutter-apk/app-release.apk`。

> 首次编译前，Flutter 会根据本机环境自动生成 `android/local.properties`（指向你的 Android SDK 路径）。该文件已被忽略，不会进入版本库。

## 🔧 配置

首次打开进入「设置 → API 配置」，填入任意 OpenAI 兼容接口：

- Base URL：填到 `/v1` 为止
- API Key：仅保存在本机，不会上传
- 支持 OpenAI、DeepSeek、Moonshot、硅基流动、Ollama 等

## 🔒 隐私

所有会话、角色卡与 API 密钥仅保存在本机存储中。应用只向你自己配置的服务商发送请求，不经过任何中间服务器。

## 🤝 贡献

欢迎 Star、Issue 与 PR。提交前请确保代码能通过 `flutter analyze`。

## 📄 许可证

本项目基于 [GNU General Public License v3.0](LICENSE) 开源。

你可以自由使用、修改和分发本项目，但衍生作品必须同样以 GPL-3.0 开源并保留版权声明。

Copyright (C) 2026 WWRJ