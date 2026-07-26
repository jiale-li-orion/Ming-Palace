Ming-Palace 现场叙事 App 项目规格

版本：v0.6日期：2026-07-27交付平台：Android / Flutter当前素材阶段：纯 AI 视觉样片

0. 文档地位

本文件是当前开发、内容接入、测试和验收的执行基线。

信息优先级：

根目录 Project.md：当前版本范围、系统行为和验收标准；

frontend-reference-handoff(team参考)/：页面、状态、交互和视觉参考；

assets/content/ 与历史研究文档：台词、证据和内容来源；

代码现状：已实现能力，不自动等同于最新需求。

前端交接包中的 PDF、页面图和状态图用于说明布局、信息层级和状态关系，不作为 App 运行时图片直接使用。

1. 项目目标

构建一个在南京明故宫遗址现场使用的 6-8 分钟第一人称叙事体验。

游客沿固定路线行走，朱允炆以预先录制的第一人称台词引导观察。系统负责定位、导航、路线条件、安全抢占、屏幕方向、故障说明和恢复。到达固定观察点后，App 使用横屏历史想象画面帮助游客理解已经消失的宫城空间，并提供一次受限的二选一质询。

本项目验证：

第一人称叙事能否与现场行走形成连贯体验；

竖屏行进、横屏观察的切换是否自然；

定位辅助和手动兜底能否让游客独立完成路线；

历史画面是否帮助理解空间，而不是替代现实；

暂停后查看证据是否有价值且不打断主线；

城台路线和地面路线是否都能完整结束；

用户在哪些节点偏航、停顿、退出或需要帮助。

2. 当前版本范围

2.1 当前里程碑：AI 视觉联调版

当前版本先使用 7 张完整 AI 场景图，不要求现场照片、不要求像素级现实叠加，也不要求透明分层复原。

当前版本必须完成：

Android 可安装 APK；

完全离线的主叙事、图片、证据摘要和日志；

正常城台路线与地面替代路线；

GPS 辅助导航和手动到达兜底；

起步、稳定行走、接近、偏航四类导航状态；

竖屏行进与横屏观察；

登楼、下楼和其他危险状态的安全抢占；

固定音频、整句字幕、暂停、继续、重播；

暂停后查看当前句 A/B/C 证据；

一次二选一质询与固定回答；

会话恢复、问卷、日志查看和导出；

隐藏操作员面板。

2.2 后续视觉升级

后续版本可将 AI 整图替换为：

现场固定机位照片；

空间轮廓透明层；

建筑复原透明层；

人物活动透明层；

现实与记忆淡出层。

该升级不得要求重写主流程、状态机或页面结构，只替换资源和视觉序列配置。

2.3 当前明确不做

实时相机叠加；

ARCore、SLAM、空间锚点；

Unity 或实时三维模型；

自由文本对话、LLM、RAG；

语音识别；

用户账号、支付、云数据库；

后台持续定位；

通用城市地图和通用路线规划；

iOS 发布；

应用商店发布；

自动识别游客体力、恐高或行动能力；

自动推断城台开放、人流和现场管理状态。

3. 体验原则

3.1 现实优先

App 用来引导游客看现场，不要求游客全程盯屏。

稳定行走时导航退场；

不显示剩余百分比和持续倒计时；

横屏观察允许隐藏界面；

AI 画面必须被明确视为历史想象或绘画化复原，不得伪装成精确 AR；

后续接入现场照片时，现实底图始终保留。

3.2 角色层和系统层分离

朱允炆负责：

固定第一人称台词；

与人物叙事直接相关的观察邀请；

两个固定质询分支的固定回答。

系统负责：

定位、导航、偏航和到达确认；

城台路线是否可用；

游客是否选择走台阶；

登楼、下楼和危险提示；

横竖屏切换；

音频、定位、网络和设备故障；

退出、恢复和日志。

朱允炆不承担左右转向、台阶提示、错误定位、故障说明或客服语言。

3.3 安全高于叙事

安全状态可抢占主叙事：

立即暂停台词；

隐藏复原画面和互动；

显示高对比安全页面；

不自动恢复；

用户到达安全平地后主动确认；

恢复只能从完整句子或完整段落边界开始。

3.4 固定叙事优先

主要内容由编辑过的脚本、音频和证据索引驱动。模型不在运行时生成历史内容。

4. 用户流程

4.1 启动与路线选择

启动应用
-> 欢迎与使用说明
-> 创建或恢复测试会话
-> 系统检查定位权限和路线可用状态
-> 游客选择城台路线或“不走台阶”
-> 进入奉天门起点

路线判断遵循：

SYSTEM_CHECK
  |- 城台可用 -> USER_ROUTE_CHOICE
  |                 |- 城台路线
  |                 `- 不走台阶
  `- 城台不可用 -> GROUND_ROUTE

当前无后台和景区接口，因此：

城台开放、天气、人流和批准路线由操作员在测试开始前设置；

App 将这些输入视为系统条件；

游客只决定自己是否愿意走台阶；

默认不得以传感器推断游客身体能力。

4.2 城台路线

奉天门北侧开场
-> 向午门行走
-> 接近午门
-> 午门北侧到达确认
-> 登楼安全抢占
-> 城台安全平地确认
-> 转为横屏
-> 观察历史空间
-> 历史复原画面
-> 一次二选一质询
-> 固定回答
-> 南望与自由观察
-> 确认继续行进
-> 转回竖屏
-> 下楼安全抢占
-> 午门南侧回望
-> 结束
-> 问卷
-> 完成与导出

4.3 地面路线

奉天门北侧开场
-> 向午门行走
-> 接近午门
-> 午门北侧到达确认
-> 地面固定观察点
-> 转为横屏或使用竖屏兼容画面
-> 地面历史想象画面
-> 一次二选一质询
-> 固定回答
-> 确认继续行进
-> 午门南侧回望
-> 结束
-> 问卷
-> 完成与导出

地面路线是正式路线，不得通过操作员连续跳过登楼状态模拟。

5. 状态模型

新版流程不得继续扩展为一个包含所有组合的巨大平面枚举。使用“主阶段 + 并行子状态”的集中式状态模型。

class ExperienceSessionState {
  ExperiencePhase phase;
  RouteMode routeMode;
  NavigationMode navigationMode;
  NarrationMode narrationMode;
  OrientationMode orientationMode;
  ChromeMode chromeMode;
  SafetyInterruption? safetyInterruption;
  EvidenceOverlay? evidenceOverlay;
  String? currentSegmentId;
  String? resumeSegmentId;
}

5.1 主阶段 ExperiencePhase

READY
WELCOME
SYSTEM_CHECK
USER_ROUTE_CHOICE
FENGTIAN_START
WALK_TO_WUMEN
WUMEN_APPROACH
WUMEN_ARRIVAL
TOWER_ASCEND
PLATFORM_ARRIVAL
PLATFORM_OBSERVE
PLATFORM_RESTORED
QUESTION
QUESTION_ANSWER
PLATFORM_SOUTH_VIEW
CONTINUE_DECISION
TOWER_DESCEND
GROUND_ARRIVAL
GROUND_OBSERVE
GROUND_RESTORED
WALK_TO_ENDING
WUMEN_SOUTH_ENDING
SURVEY
COMPLETED

5.2 并行子状态

RouteMode

UNDECIDED
TOWER
GROUND

NavigationMode

INACTIVE
START_GUIDANCE
STABLE_WALK
APPROACHING
OFF_ROUTE
ARRIVAL_SUGGESTED
MANUAL_MODE

NarrationMode

IDLE
PLAYING
USER_PAUSED
SYSTEM_PAUSED
LOAD_ERROR
COMPLETED

OrientationMode

PORTRAIT_REQUIRED
REQUEST_LANDSCAPE
LANDSCAPE_REQUIRED
PORTRAIT_FALLBACK
REQUEST_PORTRAIT

ChromeMode

VISIBLE
HIDDEN

5.3 状态转换原则

所有转换集中在 ExperienceEngine；

Widget 只能发送动作，不得直接设置下一阶段；

安全抢占保存 returnPhase 和 resumeSegmentId；

偏航保存当前完整句边界，回到路线后由用户确认恢复；

设备旋转本身不能推进体验阶段；

GPS 到达只产生“到达建议”，默认不直接跳转；

操作员跳转必须记录原因和目标状态。

6. 定位与导航

6.1 使用目标

定位用于：

发现游客是否接近奉天门、午门和结束点；

判断游客是否大致沿批准路线前进；

在偏航时暂停台词并给出返回指引；

降低现场讲解员的实时干预。

定位不用于：

精确 AR 对齐；

判断游客是否已经登楼；

区分相距数米的微小点位；

作为唯一的流程控制权。

6.2 本地路线数据

路线数据存储在 assets/content/route.json：

{
  "schemaVersion": 1,
  "coordinateSystem": "WGS84",
  "routes": {
    "tower": {
      "polyline": [],
      "nodes": []
    },
    "ground": {
      "polyline": [],
      "nodes": []
    }
  },
  "defaults": {
    "maxLocationAgeMs": 5000,
    "maxAccuracyM": 20,
    "arrivalRadiusM": 25,
    "offRouteDistanceM": 30,
    "requiredConsecutiveSamples": 3
  }
}

数值为初始假设，必须通过现场测试调整，且不得硬编码在页面中。

6.3 定位结果校验

一次位置结果只有同时满足以下条件才可参与判断：

用户已授予精确定位，或当前精度足以使用；

数据未过期；

accuracy 小于配置阈值；

连续多个样本给出一致结果。

到达逻辑：

有效定位连续进入目标区域
-> 显示“你似乎已经到达”
-> 用户确认“我已到达”
-> 推进阶段

偏航逻辑：

连续有效定位离批准路线过远
-> 暂停台词
-> 进入 OFF_ROUTE
-> 显示方向、小地图和手动继续入口
-> 返回路线
-> 用户确认
-> 从完整句边界恢复

6.4 地图表现

当前版本不接入完整在线地图 SDK。

使用本地路线折线、节点和简单地标；

由 Flutter 自绘小地图和方向箭头；

稳定行走时地图隐藏；

起步、接近和偏航时显示全屏导航；

网络不可用不影响主线。

6.5 手动兜底

定位权限被拒绝、定位长时间不可靠或触发失败时，必须提供：

去设置；

使用手动路线；

“我已到达奉天门”；

“我已到达午门北侧”；

“我已站稳”；

“我已到达午门南侧”。

手动流程不得被视为错误状态，也不得阻断已下载内容。

7. 横竖屏与观察状态

7.1 基本规则

行进阶段使用竖屏；

安全观察阶段优先使用横屏；

设备旋转只改变物理方向，不直接改变体验阶段；

必须先完成到达或继续确认，再提示转屏；

手机无法横屏时提供竖屏固定画面版本；

竖屏兼容版不得伪装成实时 AR。

7.2 进入横屏

到达安全观察点
-> 用户点击“我已站稳”
-> 显示“请将手机转为横屏”
-> 检测到横屏后进入观察

若长时间未进入横屏：

继续等待
或
使用竖屏兼容画面

7.3 横屏界面显隐

CHROME_VISIBLE
  |- 首次提示“轻触画面，可以隐藏文字，安静观看”
  `- 点击空白 -> CHROME_HIDDEN

CHROME_HIDDEN
  |- 只保留低存在感安全退出入口
  `- 点击空白 -> CHROME_VISIBLE

该首次提示每个测试会话只显示一次。

7.4 横屏观察顺序

观察
-> 界面隐藏/恢复
-> 质询
-> 回答
-> 南望
-> 90 秒无操作
-> 下一次轻触后显示“继续行进？”
-> 用户可选择“再看看”
-> 再等待 120 秒
-> 显示最后一次提示
-> 此后不再主动提示

强制规则：

自动提示只在安全平地触发；

90 秒到达时不立即弹窗；

只有用户下一次轻触时才显示询问；

选择“再看看”后只再提示一次；

不强制退出横屏；

用户确认“继续行进”后才提示转回竖屏。

8. 音频、字幕与证据

8.1 音频行为

使用打包在 APK 内的固定音频；

支持播放、暂停、继续、重播；

每个阶段可配置自动播放或等待用户操作；

行走稳定时可继续播放；

偏航、安全抢占和系统故障立即暂停；

后台或进程退出时保存阶段和播放边界；

恢复后不得未经确认自动播放。

8.2 完整句边界

为支持安全恢复和偏航恢复，每段音频必须定义句子边界。

推荐内容结构：

{
  "audio": "audio/04_platform_narration.mp3",
  "segments": [
    {
      "id": "platform-04-s01",
      "startMs": 0,
      "endMs": 9200,
      "subtitle": "...",
      "evidenceIds": ["E-A-014"]
    }
  ]
}

系统暂停时记录当前句 ID；恢复从该句开头或下一完整句开始，不从半句话恢复。

8.3 字幕

音频播放时只显示当前完整句；

不显示整段长文；

稳定行走页不显示剩余时长和百分比；

字幕必须在常见手机比例、户外高亮环境下可读；

图片不得内嵌字幕，字幕由 Flutter 绘制。

8.4 A/B/C 证据

A/B/C 表示内容形成方式，不表示高、中、低：

标签

名称

含义

A

核心史实

有核心事实或较硬证据支撑的历史骨架

B

史料综合

由多项材料、解释传统或受控综合形成

C

空间叙事

用于连接今日地点、游客动作和人物关系

显示规则：

AUDIO_PLAYING
  |- 只显示当前字幕
  |- 每个会话首次提示一次“暂停台词，可以查看本句依据”
  `- 用户主动暂停 -> AUDIO_PAUSED

AUDIO_PAUSED
  |- 当前句显示 A/B/C 和索引号
  |- 点击标签或索引 -> EVIDENCE_DRAWER
  `- 恢复播放 -> 隐藏标签

证据抽屉显示：

当前句；

依据摘要；

文献名称；

索引号；

A/B/C 分类说明。

A/B/C 的尺寸、颜色、边框和视觉权重必须相同，不使用红黄绿分级。

9. 一次受限质询

只实现两个固定问题：

为什么急着削藩？

为什么太看重经典和文字？

行为：

QUESTION
-> 用户选择一个问题
-> 播放固定回答
-> 记录选择
-> 进入共享后续段落

不实现：

自由输入；

语音提问；

动态生成回答；

多轮对话；

用户重新定义问题。

问题页继续使用当前观察或复原背景，按钮和文本由 Flutter 绘制。

10. 安全抢占与异常兜底

10.1 安全抢占

适用场景：

登楼；

下楼；

复杂路面；

人流冲突；

操作员主动触发。

表现：

高对比黑黄系统视觉；

大字号短提示；

暂停音频；

隐藏历史图片和质询；

禁止自动恢复；

到达安全平地后点击“我已站稳”。

10.2 七类异常

F01 定位权限被拒绝

解释定位用途；

提供去设置；

提供手动到达；

不阻断本地内容。

F02 定位触发失败

显示符合当前阶段的手动到达按钮；

记录 manual_arrival_used。

F03 手机无法转横屏

提示检查方向锁；

提供竖屏兼容画面；

不阻断主线。

F04 音频加载或耳机异常

暂停主线；

保留完整字幕；

提供重新加载；

提供继续无声体验；

提供退出。

F05 城台临时关闭

将城台路线设为不可用；

切换到地面路线；

不播放登楼或下楼相关内容；

地面画面明确为地面视角。

F06 网络不可用

已打包内容继续运行；

本地证据摘要继续可用；

暂时禁用外部书影、链接和扩展内容；

不显示阻断性错误。

F07 主动退出后的恢复

至少保存：

最后完成的阶段；

当前路线；

当前或下一完整句；

质询选择；

是否已确认继续行进；

是否在安全抢占中退出；

横竖屏要求；

首次提示是否已经显示。

若退出发生在台阶或危险状态，下次启动不得自动回到播放状态，必须先进入安全确认页。

11. 视觉系统与素材

11.1 交接包使用方式

交接内容

使用方式

是否作为运行素材

00-complete-handoff.pdf

审核完整体验和页面关系

否

01-flow-overview.png

理解竖屏、横屏和系统抢占

否

pages/*.png

UI 构图、信息层级和安全区参考

否

states/*.png

状态、异常和分支关系参考

否

visual-style-placeholder.png

笔触、配色、留白参考

否

assets/images/ai_v1/*

当前 App 场景背景

是

参考图不得直接裁切进 App，不得保留其中的示意文字、按钮或占位 UI。

11.2 当前 7 张 AI 图片

目录：

assets/images/ai_v1/
├── 01_fengtian_north.webp
├── 02_walk_to_wumen.webp
├── 03_wumen_arrival.webp
├── 04_platform_observe.webp
├── 05_platform_restored.webp
├── 06_ground_fallback.webp
└── 07_wumen_south_ending.webp

映射：

主阶段

图片

FENGTIAN_START

01_fengtian_north.webp

WALK_TO_WUMEN

02_walk_to_wumen.webp

WUMEN_APPROACH / WUMEN_ARRIVAL

03_wumen_arrival.webp

PLATFORM_OBSERVE

04_platform_observe.webp

PLATFORM_RESTORED / QUESTION / QUESTION_ANSWER

05_platform_restored.webp

GROUND_OBSERVE / GROUND_RESTORED

06_ground_fallback.webp

WUMEN_SOUTH_ENDING

07_wumen_south_ending.webp

11.3 图片规格

竖屏：1080 x 1920；

横屏：1920 x 1080；

普通整图：WebP；

后续透明层：PNG 或支持透明的 WebP；

sRGB；

无文字、按钮、Logo 和水印；

上下保留 UI 安全区；

同一横屏场景后续拆层时必须保持同一画布和透视。

当前 Renderer 使用全屏裁切显示。关键建筑、人物和视觉焦点不得贴近边缘。

11.4 视觉语言

宣纸米白、淡墨、石青、石绿为主；

朱砂仅用于行动和视觉重点；

绘画化历史想象，不做照片级伪历史现场；

保留笔触、缺笔、留白和边缘淡出；

不直接模仿清代北京故宫；

不夸张金色、屋顶曲线和帝王符号；

朱允炆只通过声音、字迹、衣袍、手、背影或空位出现；

不绘制写实完整正面肖像；

“便殿”等不确定空间不得被强行定位为某一确定建筑。

11.5 后续分层资产

后续视觉升级可增加：

photo_wumen_north_landscape.webp
paint_wumen_outline.png
paint_wumen_architecture.png
paint_wumen_people.png
photo_ground_fallback.webp
paint_ground_outline.png
paint_ground_architecture.png

experience.json 通过 visualSequence 控制图层淡入；不得在 Renderer 中硬编码文件名和时间。

12. 内容配置

12.1 文件职责

assets/content/
├── experience.json       # 阶段、页面、动作、图片、音频和时长
├── route.json            # 路线折线、节点和定位阈值
├── evidence-index.json   # A/B/C 依据、来源和索引
└── script/
    └── script-review-v0.5.md

12.2 experience.json 场景字段

每个场景至少定义：

id
phase
renderer
orientation
background
visualSequence
audio
segments
allowedActions
next
minimumDurationMs
autoAdvance
navigationPolicy
safetyPolicy
operatorActions

示例：

{
  "id": "PLATFORM_RESTORED",
  "renderer": "observation",
  "orientation": "landscape",
  "background": "images/ai_v1/05_platform_restored.webp",
  "audio": "audio/04_platform_narration.mp3",
  "visualSequence": [],
  "allowedActions": [
    "pause",
    "resume",
    "replay",
    "toggle_chrome",
    "continue"
  ],
  "navigationPolicy": "inactive",
  "safetyPolicy": "safe_ground_only",
  "autoAdvance": false
}

12.3 配置校验

启动时必须检查：

ID 唯一；

所有 next 指向存在；

Renderer 类型受支持；

图片和音频路径存在；

横屏场景声明横屏要求；

每个音频段落的时间边界合法；

evidence ID 存在；

两条路线均可到达 COMPLETED；

地面路线不经过登楼或下楼状态；

安全状态没有自动播放主叙事。

配置错误显示可恢复错误页并记录日志，不得静默进入错误流程。

13. 软件架构

13.1 Experience Engine

唯一状态转换入口。

职责：

加载和校验配置；

保存当前会话状态；

处理用户、系统、定位、音频、计时器和操作员事件；

管理主阶段和并行子状态；

保存中断前返回点；

输出当前页面 ViewModel；

记录状态进入、离开和拒绝动作。

13.2 Location Service

职责：

请求权限；

获取位置、精度和时间；

过滤过期和低质量结果；

暴露位置流；

支持测试时模拟位置。

不得直接推进剧情。

13.3 Navigation Controller

职责：

计算到节点和路线的距离；

产生起步、稳定、接近、偏航和到达建议；

在偏航时请求系统暂停；

处理手动模式；

输出小地图和方向模型。

13.4 Orientation Controller

职责：

监听当前物理方向；

根据阶段请求横屏或竖屏；

处理无法横屏的兼容路径；

不允许旋转事件直接推进主阶段。

13.5 Audio Service

职责：

播放本地音频；

暂停、继续、重播、定位到句子边界；

暴露播放状态、位置和时长流；

处理生命周期中断；

音频加载失败时保留字幕流程。

Widget 不得直接调用音频插件。

13.6 Content Repository

职责：

读取 experience.json、route.json 和脚本；

校验内容；

提供场景、音频、图片和段落；

暴露内容版本。

13.7 Evidence Repository

职责：

根据当前句获取证据；

提供 A/B/C 说明；

提供摘要、文献名和索引；

离线可用。

13.8 Session Repository

职责：

创建会话；

保存阶段、路线、句子边界、质询选择和首次提示；

恢复或放弃会话；

完成后清除未完成快照。

13.9 Telemetry Repository

使用 JSONL，每行一个事件。写入失败不得阻断体验。

13.10 Renderer Registry

第一版 Renderer：

WelcomeRenderer
RouteChoiceRenderer
NavigationRenderer
WalkingNarrationRenderer
ArrivalRenderer
SafetyRenderer
ObservationRenderer
QuestionRenderer
EvidenceDrawer
AudioErrorRenderer
EndingRenderer
SurveyRenderer
CompletedRenderer
ErrorRenderer

页面根据 ViewModel 渲染，不持有路线逻辑。

14. 日志与隐私

14.1 必须记录

会话创建、恢复、放弃、完成和中止；

主阶段进入和离开；

路线可用状态和游客路线选择；

定位权限结果；

导航状态变化；

偏航、返回路线和手动到达；

横竖屏请求、成功和兼容模式；

安全抢占和恢复；

音频开始、暂停、恢复、重播、完成和失败；

证据提示、打开和关闭；

质询选择；

90 秒与 120 秒提示；

图片和配置加载错误；

问卷提交；

操作员动作；

日志导出和清空。

14.2 位置隐私

默认只记录派生事件：

距目标点的距离区间；

定位精度；

是否偏航；

是否手动到达。

默认不长期保存连续原始轨迹。测试确需记录坐标时，必须通过操作员测试模式显式开启，并在测试说明中告知参与者。

所有数据保存在本机，不自动上传。

15. 操作员面板

通过隐藏入口打开，普通游客不应误触。

功能：

创建新会话；

设置城台路线可用或不可用；

设置推荐路线条件说明；

查看当前主阶段和全部子状态；

上一步、下一步和跳转到指定阶段；

切换城台/地面路线；

触发或解除安全抢占；

模拟定位权限、偏航、接近和到达；

重播音频；

标记用户需要帮助；

重置首次提示；

查看最近日志；

导出当前会话或全部会话；

清空数据；

结束会话。

所有操作员动作必须记录。

16. 目录结构

lib/
├── main.dart
├── app/
│   ├── app.dart
│   └── theme.dart
├── application/
│   ├── experience_engine.dart
│   ├── navigation_controller.dart
│   ├── orientation_controller.dart
│   ├── audio_controller.dart
│   └── operator_controller.dart
├── domain/
│   ├── experience_phase.dart
│   ├── experience_session_state.dart
│   ├── experience_event.dart
│   ├── route_definition.dart
│   ├── scene_definition.dart
│   ├── narration_segment.dart
│   ├── evidence_entry.dart
│   └── telemetry_event.dart
├── infrastructure/
│   ├── device_location_service.dart
│   ├── local_content_repository.dart
│   ├── local_evidence_repository.dart
│   ├── local_session_repository.dart
│   ├── local_telemetry_repository.dart
│   └── export_service.dart
├── presentation/
│   ├── screens/
│   ├── renderers/
│   ├── navigation/
│   ├── evidence/
│   ├── operator/
│   └── widgets/
└── shared/

assets/
├── content/
│   ├── experience.json
│   ├── route.json
│   ├── evidence-index.json
│   └── script/
├── audio/
├── images/
│   └── ai_v1/
└── ui/

当前已有文件可以迁移，不要求为了目录命名重写稳定代码。模块职责和依赖边界优先于文件路径完全一致。

17. 测试要求

17.1 单元测试

必须覆盖：

两条路线均能从开始到完成；

地面路线不经过登楼或下楼；

设备旋转不能直接推进阶段；

定位建议必须等待用户确认；

偏航暂停并可恢复；

安全抢占保存返回阶段；

90 秒和 120 秒提示只按规则触发；

A/B/C 只在用户主动暂停后显示；

恢复落在完整句边界；

非法动作被拒绝并记录；

配置引用不存在时加载失败；

两项首次提示每个会话只显示一次。

17.2 Widget 测试

必须覆盖：

竖屏和横屏关键页面；

导航四状态；

黑黄安全页面；

横屏界面显隐；

证据抽屉和 A/B/C 等权表现；

问题页和固定回答；

定位、音频和方向故障兜底；

会话恢复提示；

7 张 AI 图片路径正确加载。

17.3 集成测试

自动化至少覆盖：

城台路线 + 削藩分支；

城台路线 + 经典分支；

地面路线 + 两个问题中的一个；

定位权限拒绝后的手动流程；

偏航后返回；

安全抢占后恢复；

横屏失败后的竖屏兼容流程；

中途退出和恢复；

问卷和当前会话导出。

17.4 持续集成

每次提交至少执行：

flutter pub get
flutter analyze
flutter test
flutter build apk --debug

CI 失败时不得将该提交标记为可测试版本。

18. 当前版本验收标准

当前 AI 视觉联调版只有同时满足以下条件，才算可交付：

程序

Debug APK 可构建并安装；

无网络可冷启动；

两条路线均可完整完成；

定位辅助和手动路线均可用；

偏航和安全抢占会暂停台词；

恢复不会从半句话或危险状态自动播放；

横屏不能因旋转直接进入下一阶段；

确认继续行进后才提示转回竖屏；

90 秒和 120 秒提示符合规则；

问卷和日志导出可用。

视觉

7 张 AI 图片全部接入；

竖屏和横屏均无关键主体被裁掉；

观察图与复原图有明显信息差；

地面图明确不是城台俯视角；

问题按钮和字幕在复杂背景上可读；

图片无内嵌 UI、文字、Logo 和水印；

A/B/C 不使用红黄绿等级视觉；

安全页不显示历史图片。

内容

音频和字幕对应；

当前句能定位到证据条目；

两个问题均有固定回答；

地面路线不播放登楼或下楼内容；

不确定历史空间没有被写成已确认事实。

真机

目标 Android 手机连续完成两条路线；

前后台切换不跳状态；

强制结束后可恢复或放弃；

分享面板能导出 JSON；

最大亮度下关键提示和按钮可读；

操作员可在 15 秒内切换路线或结束测试。

19. 开发顺序

M1：7 图接入与新版状态骨架

交付：

7 张 AI 图映射到场景；

主阶段与并行子状态模型；

新路线选择；

横竖屏门控；

安全抢占；

原有音频、问卷、日志和操作员能力继续可用。

退出条件：两条路线在无 GPS 的手动模式下可完整运行。

M2：定位导航

交付：

本地 route.json；

定位权限；

起步、稳定、接近、偏航和到达建议；

自绘小地图；

手动到达兜底；

定位日志。

退出条件：模拟位置测试和一次现场路线测试均能完成。

M3：字幕边界与证据

交付：

音频句子边界；

整句字幕；

暂停后 A/B/C；

证据抽屉；

偏航和安全恢复到句边界。

退出条件：每个有声段落至少有可恢复句边界，证据索引无悬空引用。

M4：横屏观察完整行为

交付：

界面显隐；

90 秒和 120 秒提示；

继续行进确认；

横屏失败兼容；

两个质询分支。

退出条件：横屏不能通过旋转误推进，所有提示次数可测试。

M5：正式内容与现场验收

交付：

正式音频；

最终 AI 图片或现场照片；

定位阈值现场校准；

连续稳定性测试；

用户测试记录和日志导出。

退出条件：通过第 18 节全部验收标准。

20. 完成定义

“代码写完”不等于项目完成。

项目完成必须同时具备：

可复现构建；

自动测试通过；

可安装 APK；

两条完整路线；

正式音频和视觉版本号；

可解释的证据索引；

现场校准后的路线数据；

真机验收记录；

用户测试日志和问卷结果；

已知问题和降级路径记录。

任何尚未真机或现场验证的能力，应标记为“已实现，待验收”，不得写成“已完成”。