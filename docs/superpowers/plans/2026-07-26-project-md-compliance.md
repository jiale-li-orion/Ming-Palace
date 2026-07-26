# Project.md Complete Compliance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将现有 Flutter 骨架修复为可构建、可离线完成两条路线，并真实支持音频降级、问卷、遥测、恢复、导出和操作员功能的 Android Demo。

**Architecture:** 保留 domain/application/infrastructure/presentation 四层。状态机保持纯 Dart，所有文件与插件副作用通过注入的 Repository/Service 执行；界面只发送带数据的意图并渲染应用状态。

**Tech Stack:** Flutter 3.44.8、Dart 3.12.2、just_audio、path_provider、share_plus、uuid、flutter_test、integration_test。

---

## 文件职责图

- `lib/domain/`：21 状态、事件负载、场景 Schema、路线转换、恢复快照和会话摘要。
- `lib/application/experience_controller.dart`：唯一状态转换入口、最小时长、幂等、日志和持久化编排。
- `lib/application/audio_controller.dart`：本地音频播放及可恢复错误状态。
- `lib/application/operator_controller.dart`：操作员真实用例，不直接伪造普通用户事件。
- `lib/infrastructure/`：内容校验、恢复快照、统一 JSONL、导出文件。
- `lib/presentation/screens/experience_screen.dart`：生命周期、恢复选择、音频和 Renderer 编排。
- `lib/presentation/renderers/`：无 I/O 的状态页面。
- `assets/content/experience.json`：完整场景配置。
- `test/`：需求级合同测试；`integration_test/`：两条主流程。

### Task 1: 恢复可编译 Android 工程

**Files:**
- Modify: `lib/domain/experience_event.dart`
- Modify: `lib/domain/route_definition.dart`
- Modify: `lib/presentation/renderers/layered_reconstruction_renderer.dart`
- Modify: `.gitignore`
- Modify: `pubspec.yaml`
- Create: `android/`（由 Flutter CLI 生成后仅保留 Android 平台）
- Create: `pubspec.lock`

- [ ] **Step 1: 复现生产代码编译失败**

Run: `/home/orion/flutter/bin/flutter analyze`

Expected: FAIL，至少包含 `ExperienceState`、directive 顺序和 `VisualLayer` 未定义。

- [ ] **Step 2: 修复生产代码导入根因**

在事件和路线文件顶部放置完整 import：

```dart
import 'experience_state.dart';
```

在分层 Renderer 顶部引入定义 `VisualLayer` 的文件：

```dart
import '../../domain/scene_definition.dart';
```

- [ ] **Step 3: 生成 Android API 26 工程**

Run: `/home/orion/flutter/bin/flutter create --platforms=android --org com.mingpalace --project-name ming_palace .`

Expected: `android/app/build.gradle.kts` 等平台文件生成，现有 `lib/` 不被模板替换。

将 `android/app/build.gradle.kts` 的 `minSdk` 固定为 26：

```kotlin
minSdk = 26
```

- [ ] **Step 4: 固定应用依赖**

从 `.gitignore` 删除 `pubspec.lock`/`*.lock` 的宽泛忽略，只忽略构建缓存。运行：

Run: `/home/orion/flutter/bin/flutter pub get`

Expected: 生成可跟踪的 `pubspec.lock`。

- [ ] **Step 5: 验证生产代码至少可分析**

Run: `/home/orion/flutter/bin/flutter analyze lib`

Expected: 无 error；info 可留待最后按成本处理。

- [ ] **Step 6: 提交构建基线**

```bash
git add .gitignore pubspec.yaml pubspec.lock android lib/domain/experience_event.dart lib/domain/route_definition.dart lib/presentation/renderers/layered_reconstruction_renderer.dart
git commit -m "fix: restore compilable Android project"
```

### Task 2: 统一场景 Schema 与路线转换

**Files:**
- Modify: `lib/domain/scene_definition.dart`
- Modify: `lib/domain/route_definition.dart`
- Modify: `assets/content/experience.json`
- Modify: `lib/infrastructure/local_content_repository.dart`
- Test: `test/domain/state_machine_test.dart`
- Create: `test/infrastructure/content_repository_test.dart`

- [ ] **Step 1: 写内容校验与替代路线合流失败测试**

核心断言：

```dart
expect(fallback.nextState(
  ExperienceState.questionMerge,
  ExperienceEventType.audioCompleted,
), ExperienceState.wumenSouthEnding);

expect(
  () => SceneDefinition.fromJson('BROKEN', {'renderer': 'unknown'}),
  throwsFormatException,
);
```

- [ ] **Step 2: 运行测试确认失败**

Run: `/home/orion/flutter/bin/flutter test test/domain/state_machine_test.dart test/infrastructure/content_repository_test.dart`

Expected: FAIL，显示 fallback 合流错误或配置校验缺失。

- [ ] **Step 3: 扩展场景模型**

`SceneDefinition` 增加并解析以下字段：

```dart
final List<String> next;
final List<String> operatorActions;
```

同时校验 Renderer、动作、safety mode、非负时长和视觉层字段。

- [ ] **Step 4: 补全 JSON 配置**

为全部 21 个场景增加显式 `id`、`audio`、`next`、`operatorActions`。正常路线与替代路线的 `QUESTION_MERGE` 由各自转换表决定，不复制场景。

- [ ] **Step 5: 修复 fallback 合流**

```dart
fallback[ExperienceState.questionMerge] = {
  ExperienceEventType.userContinue: ExperienceState.wumenSouthEnding,
  ExperienceEventType.audioCompleted: ExperienceState.wumenSouthEnding,
};
```

- [ ] **Step 6: 验证并提交**

Run: `/home/orion/flutter/bin/flutter test test/domain/state_machine_test.dart test/infrastructure/content_repository_test.dart`

Expected: PASS。

```bash
git add lib/domain/scene_definition.dart lib/domain/route_definition.dart lib/infrastructure/local_content_repository.dart assets/content/experience.json test/domain/state_machine_test.dart test/infrastructure/content_repository_test.dart
git commit -m "feat: validate content and route contracts"
```

### Task 3: 统一会话、遥测、问卷与导出

**Files:**
- Modify: `lib/domain/experience_event.dart`
- Create: `lib/domain/session_snapshot.dart`
- Modify: `lib/infrastructure/local_session_repository.dart`
- Modify: `lib/infrastructure/local_telemetry_repository.dart`
- Modify: `lib/infrastructure/export_service.dart`
- Modify: `lib/application/experience_controller.dart`
- Test: `test/infrastructure/repository_test.dart`
- Test: `test/application/experience_engine_test.dart`

- [ ] **Step 1: 写数据闭环失败测试**

用临时目录注入文件位置，证明 session ID、问卷 payload 和摘要一致：

```dart
expect(snapshot.sessionId, sessionId);
expect(summary.survey?.mostEngagingMoment, '城台复原');
expect(summary.questionChoice, 'feudal_princes');
```

- [ ] **Step 2: 运行测试确认失败**

Run: `/home/orion/flutter/bin/flutter test test/infrastructure/repository_test.dart test/application/experience_engine_test.dart`

Expected: FAIL，当前 session ID 为空、问卷无负载或接口假对象无法编译。

- [ ] **Step 3: 建立强类型恢复快照**

```dart
class SessionSnapshot {
  final String sessionId;
  final ExperienceState state;
  final String routeId;
  final String? audioAsset;
  final int audioPositionMs;
  final bool completed;
}
```

`SessionRepository.createSession()` 只返回 ID；遥测统一由引擎写入。

- [ ] **Step 4: 统一遥测信封**

```dart
TelemetryEvent(
  schemaVersion: 1,
  sessionId: sessionId,
  timestamp: clock.now().toUtc(),
  event: event,
  state: state.id,
  payload: payload,
)
```

问题选择、问卷、帮助、路线、音频和错误只写入 `payload`。

- [ ] **Step 5: 让问卷事件携带真实答案**

```dart
class SubmitSurvey extends ExperienceEvent {
  const SubmitSurvey(this.answers);
  final SurveyAnswers answers;
}
```

只有 `survey_submitted` 成功落盘后才转换到 `COMPLETED`。

- [ ] **Step 6: 完成当前/全部导出**

`ExportService` 接受 `TelemetryRepository` 与目录提供器，生成 `ming-palace-<session>-<timestamp>.json`，并暴露 share 方法。

- [ ] **Step 7: 验证并提交**

Run: `/home/orion/flutter/bin/flutter test test/infrastructure/repository_test.dart test/application/experience_engine_test.dart`

Expected: PASS。

```bash
git add lib/domain lib/application/experience_controller.dart lib/infrastructure test/infrastructure test/application
git commit -m "feat: close session telemetry and export loop"
```

### Task 4: 完成音频降级、最小时长与生命周期恢复

**Files:**
- Modify: `lib/application/audio_controller.dart`
- Modify: `lib/application/experience_controller.dart`
- Modify: `lib/presentation/screens/experience_screen.dart`
- Create: `lib/presentation/widgets/resume_prompt.dart`
- Modify: `lib/presentation/widgets/audio_controls.dart`
- Test: `test/application/experience_engine_test.dart`
- Test: `test/presentation/experience_screen_test.dart`

- [ ] **Step 1: 写恢复和最小时长失败测试**

```dart
engine.handleEvent(const UserAction(UserActionType.continue_));
expect(engine.currentState, ExperienceState.normalPlatformObserve);
clock.elapse(const Duration(seconds: 10));
engine.handleEvent(const UserAction(UserActionType.continue_));
expect(engine.currentState, ExperienceState.normalPlatformNarration);
```

Widget 测试证明已有快照时先出现“继续上次测试”和“放弃并新建”。

- [ ] **Step 2: 运行测试确认失败**

Run: `/home/orion/flutter/bin/flutter test test/application/experience_engine_test.dart test/presentation/experience_screen_test.dart`

Expected: FAIL，当前没有最小时长保护或恢复选择。

- [ ] **Step 3: 单一计时来源**

删除 Renderer 内的自动推进 Timer，只由 `ExperienceScreen`/应用协调器触发一次。引擎记录进入状态时间并拒绝过早的普通推进。

- [ ] **Step 4: 接入 Flutter 生命周期**

`ExperienceScreen` 实现 `WidgetsBindingObserver`：

```dart
if (state == AppLifecycleState.paused ||
    state == AppLifecycleState.inactive) {
  await audio.pause();
  await engine.saveCurrentState(audio.currentPosition.inMilliseconds);
}
```

恢复前台不自动播放。

- [ ] **Step 5: 音频缺失可继续**

`AudioController.play` 返回结构化结果；捕获资源缺失，界面显示“音频暂缺，可继续体验”，写 `audio_load_failed`，不重复自动加载同一失败资源。

- [ ] **Step 6: 验证并提交**

Run: `/home/orion/flutter/bin/flutter test test/application/experience_engine_test.dart test/presentation/experience_screen_test.dart`

Expected: PASS。

```bash
git add lib/application lib/presentation/screens lib/presentation/widgets test/application test/presentation
git commit -m "feat: add resilient audio and session recovery"
```

### Task 5: 完成操作员真实用例和 UI 数据流

**Files:**
- Modify: `lib/application/operator_controller.dart`
- Modify: `lib/application/experience_controller.dart`
- Modify: `lib/presentation/operator/operator_panel.dart`
- Modify: `lib/presentation/renderers/survey_renderer.dart`
- Modify: `lib/presentation/renderers/completed_renderer.dart`
- Modify: `lib/presentation/screens/error_screen.dart`
- Test: `test/presentation/screen_widget_test.dart`
- Test: `test/application/operator_controller_test.dart`

- [ ] **Step 1: 写操作员和问卷失败测试**

```dart
await tester.enterText(find.byKey(const Key('survey-q1')), '现场叙事');
await tester.tap(find.text('提交问卷'));
expect(submitted.experienceDescription, '现场叙事');

for (var i = 0; i < 7; i++) await tester.tap(find.text('明故宫 · 朱允炆'));
expect(find.text('操作员面板'), findsOneWidget);
```

- [ ] **Step 2: 运行测试确认失败**

Run: `/home/orion/flutter/bin/flutter test test/presentation/screen_widget_test.dart test/application/operator_controller_test.dart`

Expected: FAIL，表单无负载且操作员动作无实际效果。

- [ ] **Step 3: 接通问卷与完成页**

Survey Renderer 构造 `SurveyAnswers` 发送给引擎；完成页的导出与重开调用应用用例并显示成功/失败反馈。

- [ ] **Step 4: 实现操作员动作**

引擎提供 `operatorPrevious/Next/Jump/End/MarkHelp` 等显式方法。每个方法写 `operator_action`，执行后写结果；路线选择只在 `WAIT_FOR_ROUTE_DECISION` 有效。

- [ ] **Step 5: 查看、导出、清空与确认**

面板显示当前摘要和最近日志；当前/全部导出分别调用服务；清空数据和结束会话弹出确认对话框。

- [ ] **Step 6: 验证并提交**

Run: `/home/orion/flutter/bin/flutter test test/presentation/screen_widget_test.dart test/application/operator_controller_test.dart`

Expected: PASS。

```bash
git add lib/application lib/presentation test/application test/presentation
git commit -m "feat: complete survey and operator workflows"
```

### Task 6: 补齐合规占位资源与现场 UI

**Files:**
- Modify: `assets/images/**`
- Create: `assets/images/platform_north/fade_mask.webp`
- Modify: `lib/presentation/renderers/layered_reconstruction_renderer.dart`
- Modify: `lib/presentation/renderers/safety_renderer.dart`
- Modify: `lib/presentation/renderers/narrative_renderer.dart`
- Modify: `lib/app/theme.dart`
- Test: `test/presentation/screen_widget_test.dart`

- [ ] **Step 1: 写资源降级 Widget 测试**

```dart
expect(find.textContaining('PLACEHOLDER'), findsOneWidget);
expect(find.text('请看脚下'), findsOneWidget);
```

- [ ] **Step 2: 运行测试确认失败**

Run: `/home/orion/flutter/bin/flutter test test/presentation/screen_widget_test.dart`

Expected: FAIL，现有图片错误回退不显示 `PLACEHOLDER`。

- [ ] **Step 3: 生成规范占位图片**

使用 ImageMagick 或 Flutter 可读取的本地图片工具生成 1080×1920 sRGB WebP，画面包含资源名、`PLACEHOLDER` 和 12% 上下安全区；补齐 fade mask。不得引入网络图。

- [ ] **Step 4: 优化户外可读性**

保持高对比暗底、正文至少 16sp、关键按钮高 56dp、安全提示大字；观察页的继续按钮在最小时长前显示倒计时并禁用。

- [ ] **Step 5: 验证资源和提交**

Run: `identify assets/images/**/*.webp`

Expected: 所有 WebP 为 1080×1920、sRGB、单张不超过 2 MB。

```bash
git add assets/images lib/app/theme.dart lib/presentation/renderers test/presentation/screen_widget_test.dart
git commit -m "feat: add field-safe placeholder visuals"
```

### Task 7: 关键流程测试、文档与 APK

**Files:**
- Modify: `integration_test/experience_test.dart`
- Modify: `README.md`
- Modify: `docs/content-schema.md`
- Modify: `docs/telemetry-schema.md`
- Modify: `docs/asset-guide.md`
- Create: `docs/manual-acceptance.md`

- [ ] **Step 1: 实现两条关键集成流程**

测试分别驱动：正常路线 + 削藩、替代路线 + 经典，填写问卷后断言完成状态和可解析日志。平台 I/O 使用临时目录，音频使用可控假实现。

- [ ] **Step 2: 更新权威文档**

README 写明 Flutter 版本、Android API、运行/测试/APK 命令、占位素材限制和替换方法。Schema 文档必须与最终 JSON 和日志信封逐字段一致。

- [ ] **Step 3: 运行格式化与静态分析**

Run: `/home/orion/flutter/bin/dart format lib test integration_test`

Run: `/home/orion/flutter/bin/flutter analyze`

Expected: 无 error；修复直接相关 warning，纯偏好 info 不阻断完成。

- [ ] **Step 4: 运行全部关键测试**

Run: `/home/orion/flutter/bin/flutter test --reporter expanded`

Expected: PASS，且不存在仅含注释、不执行断言的空测试体。

- [ ] **Step 5: 构建 Debug APK**

Run: `/home/orion/flutter/bin/flutter build apk --debug`

Expected: `build/app/outputs/flutter-apk/app-debug.apk` 存在且命令退出 0。

- [ ] **Step 6: 记录无法自动完成的真机验收**

`docs/manual-acceptance.md` 列出断网、后台恢复、两条路线、10 次连续运行、15 秒重置、直射光可读性和目标手机信息，未执行项明确标注“待真机执行”，不得伪称通过。

- [ ] **Step 7: 最终提交**

```bash
git add integration_test README.md docs
git commit -m "docs: align verification and field acceptance"
```

### Task 8: 最终审计、同步与推送

**Files:**
- Review: `/home/orion/Ming-Palace/Project.md`
- Review: repository working tree

- [ ] **Step 1: 对照完成定义逐项复核**

Run: `rg -n "UnimplementedError|仅含注释|尚未实现" lib test integration_test README.md docs`

Expected: 无未解释实现占位；正式音频/真机验收的外部依赖在已知限制中明确记录。

- [ ] **Step 2: 验证 Git 范围**

Run: `git status --short && git diff --check`

Expected: 只包含本项目已审查变更，无缓存、密钥或无关文件。

- [ ] **Step 3: 同步远端**

Run: `git pull --ff-only origin main`

Expected: 快进成功或已是最新；如远端变更冲突则停止并复审。

- [ ] **Step 4: 推送主仓库**

Run: `git push origin main`

Expected: 本轮提交推送成功。

- [ ] **Step 5: Wiki 审核**

只有产生 Wiki 文档变更时才在 `Ming-Palace.wiki` 提交并推送 `master`；否则保持 Wiki 无工作区改动。
