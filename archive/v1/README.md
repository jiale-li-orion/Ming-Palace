# v1 归档

本目录保存 v1 状态机系统的完整代码，已于 2026-07-27 从活跃代码路径中移出。

当前生产路径为 v2 系统（`ProjectExperienceEngine` + `ProjectExperienceScreen`），入口见 `lib/app/app.dart`。

v1 代码仍可通过 git 历史追溯（`git log --follow -- <path>`），本目录仅作参考保留。

## 移出原因

- v1（`ExperienceEngine` / `ExperienceState` / 21 状态）与 v2（`ProjectExperienceEngine` / `ExperiencePhase` / 24 阶段）互不兼容
- `app.dart` 仅使用 v2，v1 不在生产路径上
- 双系统并存导致维护成本翻倍、新成员无法判断正式系统

## 目录结构

```
archive/v1/
├── lib/           ← v1 源码（engine, renderers, screens, domain, infra）
├── test/          ← v1 单元测试
└── integration_test/  ← v1 集成测试
```
