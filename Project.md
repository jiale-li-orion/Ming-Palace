# Ming-Palace Demo Project Specification

## 1. 项目目标

构建一个可安装在 Android 手机上的离线现场叙事 Demo。

用户沿南京明故宫遗址的一条固定短路线行走。朱允炆通过第一人称音频引导用户观察现实遗址；在午门城台北望时，程序以固定视点的绘画化分层复原补出奉天门、奉天殿、文楼和武楼；用户完成一次二选一互动；最后在午门南侧回望现实遗址并结束体验。

目标体验时长为 6—8 分钟。当前台词单次实际有声量约 990—996 字，纯音频约 4 分 30 秒—5 分钟，其余时间用于步行、登楼、下楼、观察和互动。

本项目验证：

1. 第一人称人物叙事能否和真实遗址行走形成连贯体验。
2. 固定观察点的历史复原画面能否帮助用户理解已经消失的宫城空间。
3. 用户能否在没有讲解员实时帮助的情况下完成流程。
4. 用户在哪些节点停顿、退出、走神或需要帮助。

本项目不验证完整商业产品、精确空间定位、自由对话或完整三维复原。

---

## 2. 当前实现决策

### 2.1 客户端

- Flutter。
- Android 优先。
- 交付 APK。
- 完全离线运行。
- 首批只保证指定测试设备。
- 不接后端。

### 2.2 视觉

第一版使用预先拍摄的固定视点照片作为现实背景。

历史复原由多张透明 WebP/PNG 图层构成：

- 宫城中轴线；
- 奉天门；
- 奉天殿；
- 文楼；
- 武楼；
- 淡出遮罩。

图层按时间依次淡入或淡出。

第一版不使用：

- 实时相机；
- ARCore；
- Unity；
- 三维模型；
- SLAM；
- 空间锚点；
- GPS 自动触发。

代码结构必须允许以后增加 `camera_overlay` 和 `ar_scene`，但本次不得实现。

### 2.3 音频

- 所有有声台词由朱允炆说出。
- 音频按状态拆分，不使用一个完整长音频。
- 音频资源打包在 APK 内。
- 必须支持播放、暂停、继续、重播和跳过。
- 应用进入后台或收到音频中断时，恢复后不得自动跳过当前状态。
- 行走静默、登楼静默、下楼静默由状态机控制，不播放主要台词。

### 2.4 位置与触发

第一版全部手动推进：

- 用户点击“继续”；
- 用户点击“我已到达”；
- 操作员可从隐藏控制面板强制跳转。

用户界面不得出现 GPS 精度或定位等待。

### 2.5 互动

只实现一次二选一互动：

1. 为什么急着削藩？
2. 为什么太看重经典和文字？

第一版使用按钮，不实现语音识别。

选择后播放对应音频，两条分支最终合流。

### 2.6 数据

所有事件写入本地 JSONL 文件。

测试结束后可以：

- 查看当前会话摘要；
- 导出单次会话；
- 导出全部会话；
- 清空测试数据。

不上传服务器。

---

## 3. 用户流程

### 3.1 正常路线

```text
启动应用
→ 欢迎与使用说明
→ 创建测试会话
→ 奉天门北侧
→ 向南步行
→ 午门北侧
→ 登楼安全静默
→ 午门城台北望
→ 二选一互动
→ 下楼安全静默
→ 向南穿过午门
→ 午门南侧回望
→ 结束页面
→ 测试问卷
→ 保存并导出结果
```

### 3.2 无法登楼时的替代路线

触发条件：

- 午门封楼；
- 下雨；
- 人流拥挤；
- 现场管理要求；
- 操作员主动选择。

```text
启动应用
→ 奉天门北侧
→ 向南步行
→ 午门北侧
→ 操作员选择“使用地面替代路线”
→ 地面固定观察点
→ 缩短版宫城复原
→ 二选一互动
→ 午门南侧回望
→ 结束页面
→ 测试问卷
```

替代路线必须是正式状态，不得通过临时跳过多个页面实现。

---

## 4. 状态机

```text
READY
INTRO
FENGTIAN_NORTH
WALK_TO_WUMEN
WUMEN_NORTH
WAIT_FOR_ROUTE_DECISION

NORMAL_ASCEND
NORMAL_PLATFORM_OBSERVE
NORMAL_PLATFORM_NARRATION
QUESTION
QUESTION_BRANCH_FEUDAL
QUESTION_BRANCH_CLASSICS
QUESTION_MERGE
NORMAL_DESCEND
WALK_THROUGH_WUMEN

FALLBACK_GROUND_OBSERVE
FALLBACK_GROUND_NARRATION

WUMEN_SOUTH_ENDING
ENDING_AMBIENCE
SURVEY
COMPLETED
```

### 4.1 状态转换

```text
READY → INTRO
INTRO → FENGTIAN_NORTH
FENGTIAN_NORTH → WALK_TO_WUMEN
WALK_TO_WUMEN → WUMEN_NORTH
WUMEN_NORTH → WAIT_FOR_ROUTE_DECISION

WAIT_FOR_ROUTE_DECISION
  → NORMAL_ASCEND
  → FALLBACK_GROUND_OBSERVE

NORMAL_ASCEND → NORMAL_PLATFORM_OBSERVE
NORMAL_PLATFORM_OBSERVE → NORMAL_PLATFORM_NARRATION
NORMAL_PLATFORM_NARRATION → QUESTION

QUESTION
  → QUESTION_BRANCH_FEUDAL
  → QUESTION_BRANCH_CLASSICS

QUESTION_BRANCH_FEUDAL → QUESTION_MERGE
QUESTION_BRANCH_CLASSICS → QUESTION_MERGE
QUESTION_MERGE → NORMAL_DESCEND
NORMAL_DESCEND → WALK_THROUGH_WUMEN

FALLBACK_GROUND_OBSERVE → FALLBACK_GROUND_NARRATION
FALLBACK_GROUND_NARRATION → QUESTION

WALK_THROUGH_WUMEN → WUMEN_SOUTH_ENDING
WUMEN_SOUTH_ENDING → ENDING_AMBIENCE
ENDING_AMBIENCE → SURVEY
SURVEY → COMPLETED
```

### 4.2 每个状态必须定义

- `id`
- `renderer`
- `audio`
- `visualSequence`
- `allowedActions`
- `next`
- `operatorActions`
- `safetyMode`
- `autoAdvance`
- `minimumDurationMs`

状态转换必须集中在 Experience Engine 中，不得分散写在各页面按钮里。

---

## 5. 核心模块

### 5.1 Experience Engine

职责：

- 加载体验配置；
- 保存当前状态；
- 校验状态转换；
- 调度音频和视觉；
- 记录事件；
- 支持正常路线和替代路线；
- 支持重新开始和恢复。

输入：

- 当前状态；
- 用户动作；
- 操作员动作；
- 音频完成事件；
- 定时器事件。

输出：

- 新状态；
- 当前渲染模型；
- 音频命令；
- 日志事件。

### 5.2 Scene Renderer

```dart
abstract interface class SceneRenderer {
  Widget build(BuildContext context, SceneViewModel scene);
}
```

第一版实现：

- `InstructionRenderer`
- `NarrativeRenderer`
- `LayeredReconstructionRenderer`
- `QuestionRenderer`
- `SurveyRenderer`
- `SafetyRenderer`
- `CompletedRenderer`

预留但不实现：

- `CameraOverlayRenderer`
- `PanoramaRenderer`
- `ArSceneRenderer`

### 5.3 Audio Service

职责：

- 播放本地音频；
- 暂停、继续、重播；
- 监听播放完成；
- 处理应用生命周期；
- 保存当前音频位置；
- 控制环境静默计时。

禁止在 Widget 中直接调用音频插件。

### 5.4 Content Repository

职责：

- 从 assets 读取 `experience.json`；
- 校验配置；
- 提供场景、音频和视觉资源路径；
- 暴露内容版本。

第一版只有 `LocalContentRepository`。

预留 `RemoteContentRepository` 接口，但不得实现网络请求。

### 5.5 Telemetry Repository

使用 JSONL，每行一个事件。

必须记录：

- 会话创建；
- 状态进入与离开；
- 用户点击；
- 操作员操作；
- 音频开始、暂停、恢复、完成；
- 问题选择；
- 使用替代路线；
- 请求帮助；
- 应用错误；
- 问卷提交；
- 会话完成或中止。

### 5.6 Operator Panel

通过首页标题连续点击 7 次打开。

功能：

- 创建新会话；
- 查看当前状态；
- 上一步；
- 下一步；
- 跳转到指定状态；
- 重播音频；
- 标记“用户需要帮助”；
- 切换正常/替代路线；
- 结束当前会话；
- 查看日志；
- 导出日志；
- 清空数据。

操作员动作必须写入日志。

---

## 6. 内容结构

```text
assets/
├── content/
│   ├── experience.json
│   ├── script/
│   │   └── script-review-v0.5.md
│   └── evidence/
│       └── evidence-index.json
├── audio/
│   ├── 01_fengtian_north.mp3
│   ├── 02_walk_to_wumen.mp3
│   ├── 03_wumen_north.mp3
│   ├── 04_platform_narration.mp3
│   ├── 05_question_prompt.mp3
│   ├── 06_branch_feudal.mp3
│   ├── 07_branch_classics.mp3
│   ├── 08_question_merge.mp3
│   ├── 09_ground_fallback.mp3
│   └── 10_wumen_south_ending.mp3
├── images/
│   ├── fengtian_north/
│   ├── platform_north/
│   │   ├── background.webp
│   │   ├── central_axis.webp
│   │   ├── fengtian_gate.webp
│   │   ├── fengtian_hall.webp
│   │   ├── civil_tower.webp
│   │   ├── military_tower.webp
│   │   └── fade_mask.webp
│   ├── ground_fallback/
│   └── wumen_south/
└── ui/
```

缺少正式资产时，可使用明确标记的占位资源，但：

- 文件名和尺寸必须符合正式结构；
- 不得使用临时网络图片；
- 不得把生成图当作史实复原完成稿；
- 占位资源必须显示 `PLACEHOLDER`。

---

## 7. `experience.json` 示例

```json
{
  "schemaVersion": 1,
  "contentVersion": "0.1.0",
  "experienceId": "ming-palace-zhu-yunwen",
  "title": "朱允炆：建文四年不是空白",
  "routes": {
    "normal": {
      "initialState": "INTRO"
    },
    "fallback": {
      "initialState": "INTRO"
    }
  },
  "scenes": {
    "NORMAL_PLATFORM_OBSERVE": {
      "renderer": "layered_reconstruction",
      "background": "images/platform_north/background.webp",
      "audio": null,
      "minimumDurationMs": 10000,
      "autoAdvance": false,
      "visualSequence": [
        {
          "asset": "images/platform_north/central_axis.webp",
          "startMs": 0,
          "fadeInMs": 1200
        },
        {
          "asset": "images/platform_north/fengtian_gate.webp",
          "startMs": 1500,
          "fadeInMs": 1200
        },
        {
          "asset": "images/platform_north/fengtian_hall.webp",
          "startMs": 3000,
          "fadeInMs": 1500
        },
        {
          "asset": "images/platform_north/civil_tower.webp",
          "startMs": 4500,
          "fadeInMs": 1200
        },
        {
          "asset": "images/platform_north/military_tower.webp",
          "startMs": 4500,
          "fadeInMs": 1200
        }
      ],
      "allowedActions": ["continue"],
      "safetyMode": "stationary"
    }
  }
}
```

配置加载失败时：

- 显示可读错误页；
- 提供重试；
- 写入 `content_load_failed`；
- 不得崩溃或展示空白页面。

---

## 8. 事件格式

```json
{
  "schemaVersion": 1,
  "sessionId": "uuid",
  "timestamp": "2026-07-26T12:00:00.000Z",
  "event": "state_entered",
  "state": "NORMAL_PLATFORM_OBSERVE",
  "payload": {
    "route": "normal",
    "contentVersion": "0.1.0"
  }
}
```

### 8.1 会话摘要

```json
{
  "sessionId": "uuid",
  "startedAt": "...",
  "endedAt": "...",
  "completed": true,
  "route": "normal",
  "durationSeconds": 438,
  "questionChoice": "feudal_princes",
  "helpCount": 1,
  "interrupted": false,
  "survey": {
    "understoodExperience": 4,
    "mostEngagingMoment": "...",
    "confusingMoment": "...",
    "wantsLongerExperience": true
  }
}
```

---

## 9. 问卷

1. 你认为刚才体验的是什么？
2. 哪一刻最吸引你？
3. 哪一刻最难理解或开始走神？
4. 是否愿意体验 30—45 分钟完整版？
5. 是否愿意参加下一轮测试？

问题 1—3 使用文本输入，问题 4—5 使用是/否。

不收集付款，不收集身份证明，不自动上传联系方式。

---

## 10. 页面要求

### 10.1 欢迎页

显示：

- 项目名称；
- 体验约 6—8 分钟；
- 需要步行和登楼；
- 建议佩戴耳机；
- 注意脚下；
- “开始测试”按钮。

### 10.2 行走页面

只显示：

- 当前观察/行走提示；
- 音频状态；
- 暂停/继续；
- 重播；
- “我已到达”。

不得显示大段台词。

### 10.3 安全页面

登楼和下楼时：

- 黑色或低干扰背景；
- 大字“请看脚下”；
- 当前方向提示；
- 不显示复原图；
- 不触发互动；
- 不自动播放主要叙事。

### 10.4 城台北望页面

- 固定视点背景图；
- 分层复原动画；
- 10—15 秒无台词观察时间；
- 后续播放主独白；
- 用户可暂停和重播；
- 互动只在“站稳后提问”状态开放。

### 10.5 结束页面

- 宫城复原层缓慢淡出；
- 保留现实午门；
- 结束音频后保留 5 秒环境静默；
- 显示“完成体验”；
- 进入问卷。

---

## 11. 错误与恢复

### 11.1 应用切后台

- 暂停当前音频；
- 保存状态和播放位置；
- 返回应用时显示继续按钮；
- 不自动进入下一状态。

### 11.2 应用被系统终止

下次打开时提示：

- 继续上次测试；
- 放弃并创建新会话。

### 11.3 音频文件缺失

- 显示错误提示；
- 允许操作员跳过；
- 写入日志；
- 不崩溃。

### 11.4 图片文件缺失

- 显示占位画面和资源名；
- 允许继续；
- 写入日志。

### 11.5 内容配置错误

- 阻止开始体验；
- 明确显示字段和场景 ID；
- 提供日志导出。

### 11.6 用户误操作

- 普通用户不能任意返回上一个场景；
- 操作员可以回退；
- 连续点击不得重复启动同一音频或重复转换状态。

---

## 12. 测试要求

### 12.1 单元测试

至少覆盖：

- 正常路线完整状态转换；
- 替代路线完整状态转换；
- 非法状态转换被拒绝；
- 两个互动分支均能合流；
- 会话摘要计算；
- 配置解析；
- JSONL 写入；
- 应用恢复状态。

### 12.2 Widget 测试

至少覆盖：

- 欢迎页；
- 行走页；
- 安全页；
- 城台复原页；
- 问题页；
- 问卷页；
- 配置错误页。

### 12.3 集成测试

至少两条：

```text
启动
→ 正常路线
→ 选择“为什么急着削藩”
→ 完成问卷
→ 导出日志
```

```text
启动
→ 替代路线
→ 选择“为什么太看重经典和文字”
→ 完成问卷
→ 导出日志
```

### 12.4 手工验收

在目标 Android 手机上验证：

- 断网后可完成；
- 连续运行 10 次无崩溃；
- 音频暂停、恢复和重播正常；
- 切后台后可以继续；
- 每次测试创建独立 session；
- 日志可导出；
- 两条路线均可完成；
- 操作员可以在 15 秒内重置到新会话。

---

## 13. 完成定义

- APK 可安装；
- 无网络可运行；
- 正常路线无阻断；
- 替代路线无阻断；
- 所有音频可播放、暂停、继续和重播；
- 城台视觉按顺序逐层出现；
- 二选一互动正确分支并合流；
- 登楼和下楼状态不播放主要叙事、不展示复原；
- 会话日志完整；
- 问卷能够保存；
- 数据能够导出；
- 自动测试通过；
- README 写明安装、运行、测试和内容替换方法；
- 没有硬编码绝对文件路径；
- 没有网络图片或运行时下载依赖。

---

## 14. 明确不做

本版本禁止实现：

- 登录、账号、支付和注册；
- 云数据库、CMS 和实时上传；
- GPS 自动触发和路线地图；
- 实时相机叠加；
- AR 和三维建筑；
- 自由对话、LLM、RAG；
- 语音识别和文本转语音；
- 多人物和多路线；
- iOS 适配；
- 应用商店发布；
- 后台内容更新。

OpenCode 不得因为“未来扩展”增加上述模块、依赖或空实现。

---

## 15. 推荐目录结构

```text
Ming-Palace/
├── Project.md
├── README.md
├── pubspec.yaml
├── analysis_options.yaml
├── lib/
│   ├── main.dart
│   ├── app/
│   │   ├── app.dart
│   │   ├── router.dart
│   │   └── theme.dart
│   ├── domain/
│   │   ├── experience_state.dart
│   │   ├── experience_event.dart
│   │   ├── scene_definition.dart
│   │   ├── route_definition.dart
│   │   └── session_summary.dart
│   ├── application/
│   │   ├── experience_controller.dart
│   │   ├── audio_controller.dart
│   │   └── operator_controller.dart
│   ├── infrastructure/
│   │   ├── local_content_repository.dart
│   │   ├── local_telemetry_repository.dart
│   │   ├── local_session_repository.dart
│   │   └── export_service.dart
│   ├── presentation/
│   │   ├── screens/
│   │   ├── renderers/
│   │   ├── widgets/
│   │   └── operator/
│   └── shared/
│       ├── result.dart
│       └── app_error.dart
├── assets/
├── test/
│   ├── domain/
│   ├── application/
│   ├── infrastructure/
│   └── presentation/
├── integration_test/
└── docs/
    ├── content-schema.md
    ├── telemetry-schema.md
    └── asset-guide.md
```

避免引入大型状态管理框架。第一版使用 Flutter 自带 `ChangeNotifier`、`ValueNotifier` 或简单 Controller。状态机逻辑必须是纯 Dart，可独立测试。

---

## 16. 依赖建议

只添加实际使用的依赖。选择兼容当前 Flutter stable 的最新稳定版本，并在 README 记录版本。

建议依赖：

```yaml
dependencies:
  flutter:
    sdk: flutter
  just_audio: any
  path_provider: any
  share_plus: any
  uuid: any

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  flutter_lints: any
```

不要加入：

- Riverpod；
- Bloc；
- GetX；
- Firebase；
- Dio；
- AR 插件；
- 地图插件；
- 相机插件；
- 数据库 ORM。

本地 JSONL 和简单 JSON 文件足够。

---

## 17. 实现顺序

### Phase 1：工程与状态机

交付：

- Flutter 工程；
- 领域模型；
- 正常与替代路线状态机；
- 内容配置加载；
- 基础页面；
- 单元测试。

退出条件：

- 使用占位资源可以从 `READY` 走到 `COMPLETED`；
- 两条路线均可完成；
- 非法转换有测试。

### Phase 2：音频和视觉

交付：

- Audio Service；
- 分层复原 Renderer；
- 音频片段配置；
- 静默计时；
- 应用生命周期恢复。

退出条件：

- 音频中断后可恢复；
- 城台图层按配置顺序显示；
- 缺失资源不会崩溃。

### Phase 3：互动、问卷和日志

交付：

- 二选一互动；
- 分支合流；
- 问卷；
- JSONL 日志；
- 会话摘要；
- 导出。

退出条件：

- 每个用户生成独立 session；
- 能复现完整状态轨迹；
- 数据可保存或分享为文件。

### Phase 4：操作员和稳定性

交付：

- 隐藏操作员面板；
- 跳转、重播、帮助标记；
- 正常/替代路线切换；
- 错误页面；
- 集成测试；
- README。

退出条件：

- 操作员能快速重置；
- 目标手机断网连续运行 10 次；
- 自动测试全部通过。

---

## 18. OpenCode 执行要求

执行前：

1. 阅读本文件。
2. 检查仓库现状。
3. 输出简短实现计划。
4. 不修改本文件中的范围。
5. 不自行增加后端、GPS、AR、LLM、相机或语音识别。
6. 缺少正式音频和图片时，创建明确的占位资源与替换说明。
7. 每完成一个 Phase，运行测试并修复失败。
8. 保持提交可审查，避免一次提交混入无关重构。

最终输出：

- 完整 Flutter 工程；
- 可运行 Android Debug APK；
- 自动测试；
- README；
- 内容和日志 Schema 文档；
- 未完成项与已知限制清单。

---

## 19. 内容来源

台词与体验节奏以《“精游”南京明故宫原型：朱允炆第五步完整台词工作稿》v0.5 为准。

实现时保留 `[A]`、`[B]`、`[C]` 证据分层信息，但这些标签不在正式有声台词和普通用户界面中显示。内容审核材料保留在 `assets/content/script/` 和 `assets/content/evidence/`。

正式接入台词前修正：

```text
事情就会按照文字写好得那样yunzhuan走
```

改为：

```text
事情就会按照文字写好的那样运转。
```
