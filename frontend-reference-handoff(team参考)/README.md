# 精游·南京明故宫前端参考交接包

版本：v0.2  
日期：2026-07-26  
性质：视觉与交互交接参考，不是现场发布版本

## 推荐阅读顺序

1. 打开 `00-complete-handoff.pdf`，先看总体流程与九张主页面。
2. 单独查看 `01-flow-overview.png`，理解竖屏行走、横屏观察和系统抢占的关系。
3. 在 `pages/` 中查看每张主页面及其用法。
4. 在 `states/` 中核对状态机、发现性提示和七类异常兜底。
5. 开发与产品人员阅读 `02-interaction-spec.md`。
6. 视觉资产制作人员阅读 `03-asset-replacement-list.md`。

## 文件结构

```text
08-frontend-reference-handoff/
├─ 00-complete-handoff.pdf
├─ 01-flow-overview.png
├─ 02-interaction-spec.md
├─ 03-asset-replacement-list.md
├─ pages/
│  ├─ 01-welcome-and-preparation.png
│  ├─ 02-navigation.png
│  ├─ 03-walking-subtitle.png
│  ├─ 04-safety-takeover.png
│  ├─ 05-arrival-and-rotate.png
│  ├─ 06-observe-reality.png
│  ├─ 07-layered-restoration.png
│  ├─ 08-single-question.png
│  └─ 09-ending.png
├─ states/
│  ├─ 00-state-overview.png
│  ├─ 01-navigation-states.png
│  ├─ 02-evidence-states.png
│  ├─ 03-landscape-state-machine.png
│  ├─ 04-safety-states.png
│  ├─ 05-route-choice-states.png
│  └─ 06-fallback-states.png
└─ assets/
   └─ visual-style-placeholder.png
```

## 交接结论

- A/B/C 表示三种陈述来源，不代表高、中、低。
- 系统判断城台路线是否可用；游客决定自己是否适合走台阶。
- 行进阶段竖屏；安全观察阶段横屏。
- 横屏不会因设备旋转直接进入行走，必须先确认“继续行进”。
- 安全页和偏航状态均暂停台词，且不自动恢复。
- 实景和分层复原素材尚未到位，但已有稳定占位编号，不阻塞界面交接。

