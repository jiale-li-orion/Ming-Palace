# 明故宫 · 朱允炆在场叙事 Demo

Android 优先、完全离线的 Flutter 现场叙事 Demo。用户沿南京明故宫遗址固定路线行走，通过朱允炆第一人称音频、固定视点分层复原、一次二选一互动和现场问卷完成约 6—8 分钟体验。完整需求见 [Project.md](Project.md)。

## 当前实现

- 21 状态集中式状态机，覆盖正常登楼路线与地面替代路线。
- 本地 `experience.json` 严格校验；配置错误显示可恢复错误页。
- 分段本地音频支持播放、暂停、继续、重播、位置保存；缺音频时提示并允许继续。
- 固定视点 WebP 分层淡入；观察节点含 10 秒倒计时。
- 应用进入后台时暂停并保存；被终止后下次启动可选择恢复或放弃。
- 问卷、JSONL 遥测、当前会话/全部日志导出。
- 首页标题连续点击 7 次打开操作员面板，可跳转、回退、标记帮助、重播、查看/导出/清空日志和结束会话。

## 环境与构建

- 已验证 Flutter `3.44.8`、Dart `3.12.2`
- Android 最低 API 26（Android 8.0）

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Debug APK 输出到 `build/app/outputs/flutter-apk/app-debug.apk`。连接目标手机后可运行：

```bash
flutter devices
flutter run
```

若本机代理指向本地端口，Flutter 测试进程无法访问回环地址，可临时执行：

```bash
env -u HTTP_PROXY -u HTTPS_PROXY -u http_proxy -u https_proxy \
  NO_PROXY=localhost,127.0.0.1,::1 \
  no_proxy=localhost,127.0.0.1,::1 flutter test
```

## 内容与素材替换

配置入口是 `assets/content/experience.json`，状态 ID、Renderer、动作、后继状态和时长字段见 [内容 Schema](docs/content-schema.md)。状态转换仍以 `lib/domain/route_definition.dart` 为唯一执行入口。

图片必须为 1080×1920、sRGB、单张不超过 2 MB，并保留上下各 12% 安全区。当前图片均为明确标有 `PLACEHOLDER` 的联调资源，不是史实复原完成稿。正式素材到位后保持原文件名覆盖即可，清单见 [素材指南](docs/asset-guide.md)。

正式 MP3 尚未入库。应用会记录 `audio_load_failed` 并显示“音频暂缺，可继续体验”，因此流程可验收，但“所有正式音频可播放”仍需素材交付后复验。

## 数据与隐私

事件逐行写入应用文档目录的 `telemetry.jsonl`，不上传服务器。完成页导出当前会话，操作员面板可查看最近日志或导出全部日志。字段见 [遥测 Schema](docs/telemetry-schema.md)。

## 验证范围

自动测试覆盖两条路线、非法转换、分支合流、内容解析、会话恢复、JSONL、问卷和关键页面。集成测试覆盖两条完整状态路径。户外直射光、后台中断、连续 10 次运行、分享面板和安装包安装必须在目标 Android 手机上执行，见 [手工验收表](docs/manual-acceptance.md)。

本版本不实现 GPS、地图、实时相机、AR/3D、账号、后端、云上传、语音识别、LLM 或远程内容更新。
