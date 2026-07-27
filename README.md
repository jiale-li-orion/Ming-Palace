# 明故宫 · 朱允炆在场叙事 Demo

Android 优先、完全离线的 Flutter 现场叙事 Demo。用户沿南京明故宫遗址固定路线行走，通过朱允炆第一人称音频、固定视点分层复原、A/B/C 证据系统、二选一互动和现场问卷完成约 6—8 分钟体验。完整需求见 [Project.md](Project.md)。

## 当前实现

- **24 阶段复合状态机**，双路线（正常登楼 + 地面替代），含定位建议、偏航暂停、安全抢占。
- **本地 `experience.json` 严格校验**；配置错误显示可恢复错误页。
- **分段本地音频**（7 段离线 TTS，已标注临时），支持播放、暂停、继续、重播、**整句位置恢复**；缺音频时提示并允许继续。
- **固定视点 WebP 分层淡入**；观察节点含 90/120 秒观察器（按路线区分），引擎拒绝过早推进。
- **A/B/C 证据层**：史实画面（A）、考古图（B）、结构注释（C），按路线自适应展现。
- **横竖屏兼容**，旋转不触发状态变更。
- **应用进入后台时暂停并保存**；被终止后下次启动可选择恢复或放弃。
- **问卷、JSONL 遥测、当前会话/全部日志导出**。
- **操作员入口**：首页标题连续点击 7 次，可跳转、回退、路线切换、重播、标记帮助、查看/导出/清空日志、结束/新建会话。
- **传统色 UI**：米白、玄色、石青、石绿、朱砂红。

## 视觉素材

- 7 张 1080×1920 / 1920×1080 正式 sRGB 图片已入库，含 ICC 色彩配置，单图约 200–316 KB，按传统色重构。
- 图片硬规范：1080×1920、sRGB 色彩空间、单张 ≤2 MB、上下各 12% 安全区。清单见 [素材指南](docs/asset-guide.md)。
- 正式 MP3 尚未入库。7 段离线普通话 TTS 已标注“临时音频、路线未现场校准”。应用在缺音频时记录 `audio_load_failed` 并显示“音频暂缺”，流程可验收。

## 环境与构建

- 已验证 Flutter `3.44.8`、Dart `3.12.2`
- Android 最低 API 26（Android 8.0）
- 连续集成：`flutter analyze` → **No issues found**；`flutter test` → **103/103 通过**

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --debug
```

Debug APK 输出到 `build/app/outputs/flutter-apk/app-debug.apk`。

首次构建需要网络解析 Gradle 及 Android SDK 依赖。已缓存的 Gradle 9.1.0 分发可在第二次构建时跳过下载。

```bash
# 构建前检查
cd android && ./gradlew --no-daemon --version && cd ..
# 构建
flutter build apk --debug --no-pub
```

```bash
# 查看 APK 哈希
sha256sum build/app/outputs/flutter-apk/app-debug.apk
# 通过 adb 安装
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

## 团队成员：快速安装

如果你是团队测试成员，不需要搭建 Flutter 环境。直接从 GitHub Releases 下载预构建 APK：

1. 打开 https://github.com/jiale-li-orion/Ming-Palace/releases/tag/v0.6.0-demo
2. 下载 Assets 中的 `app-debug.apk`（约 154 MB）
3. 通过 adb 安装到 Android 真机（最低 Android 8.0）：

```bash
adb install -r app-debug.apk
```

或在手机浏览器中直接下载 APK 文件后点击安装（需在设置中启用"允许安装未知来源应用"）。

### 真机验收检查项

安装后请按以下场景验证，结果反馈在团队群中：

- [ ] 离线冷启动 → 显示欢迎页
- [ ] 正常路线完整走完 → 问卷 → 导出
- [ ] 地面路线完整走完 → 问卷 → 导出
- [ ] 拒绝定位权限后 → 可手动推进
- [ ] 模拟偏航 → 音频暂停
- [ ] 横屏旋转 → 不触发状态跳变
- [ ] 安全阶段（上楼/下楼）→ 黑色警示页
- [ ] 播放中切后台 → 返回后不跳段
- [ ] 强杀应用后重启 → 可恢复会话
- [ ] 标题 7 击 → 操作员面板可用
- [ ] 临时音频标签和路线未校准提示可见

## 数据与隐私

事件逐行写入应用文档目录的 `telemetry.jsonl`，不上传服务器。完成页导出当前会话，操作员面板可查看最近日志或导出全部日志。字段见 [遥测 Schema](docs/telemetry-schema.md)。

## 验证范围

- **自动测试**：103 个用例覆盖双路线、非法转换、分支合流、偏航暂停、安全抢占、观察器超时、内容解析、会话恢复、JSONL 遥测、问卷、操作员面板。
- **需真机验收的场景**：户外直射光可读性、后台中断恢复、连续 10 次运行稳定性、分享面板、adb 安装、Android 权限请求、双路线完整流程、定位拒绝后的手动推进。详见 [手工验收表](docs/manual-acceptance.md)。

本版本不实现 GPS、地图、实时相机、AR/3D、账号、后端、云上传、语音识别、LLM 或远程内容更新。
