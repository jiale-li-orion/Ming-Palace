# 明故宫 · 体验重建（rebuild/0802）

本目录是 **路线一** 工作区：在仓库 `jiale-li-orion/Ming-Palace` 上从全新历史分支 `rebuild/0802` 重做现场活卷体验层。

- **旧 `main`（Flutter v0.6 Demo）保留**，不覆盖、不合并，仅供对照或队友继续使用。
- **本分支从零开始**，以 HTML 体验层 + 视频页为主（不再沿用旧分层复原 + TTS 路径）。
- **产品文档权威**仍在 `D:\dev\Saunter\background\`（宪法、概念表、《06》《07》《09》等），本仓库只放可运行代码与进入运行版本的内容。

## 目录主权（对齐《07》）

| 路径 | 职责 |
| --- | --- |
| `apps/experience-web/` | 体验负责人主责：页面、流程、样式、模拟数据 |
| `content/` | 剧本、字幕、文案、素材登记 |
| `assets/runtime/` | 进入运行版本的压缩媒体 |
| `packages/contracts/` | 与《06》对齐的契约说明（正式定义在 background） |
| `docs/experience/` | 体验验收规格与测试记录 |

## 本地启动（手机同网访问）

```powershell
cd apps/experience-web
node serve.mjs
```

终端会打印本机地址，例如 `http://192.168.x.x:5173`。用手机浏览器打开该地址（需与电脑同一 Wi‑Fi）。

仅本机预览：

```powershell
node serve.mjs --local
```

## Git 与远程

- 远程：`https://github.com/jiale-li-orion/Ming-Palace.git`
- 分支：`rebuild/0802`（勿向 `main` 直接 force push）

```powershell
git status
git push -u origin rebuild/0802
```

## 下一步（体验负责人）

1. 在 Cursor：**File → Open Folder** → 选本目录 `Ming-Palace-rebuild`
2. 确认 `git branch` 为 `rebuild/0802`
3. 按《09》周末测试范围，在 `apps/experience-web` 内逐格实现用户旅程
4. 素材登记写入 `content/manifests/assets.json`
