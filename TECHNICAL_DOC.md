# 泡泡猫 DSH 桌面版 — 技术文档

> 版本：v2.3.0  
> 日期：2025-09-16  
> DSH 核心：@deepseek-ai/dsh 0.1.5-rc.1  
> 安装包大小：147MB  
> GitHub 仓库：[zmm863-commits/dsh-desktop-pack](https://github.com/zmm863-commits/dsh-desktop-pack)

### 📥 下载地址

| 版本 | 直链下载 | 大小 |
|------|----------|------|
| v2.3.0（最新） | [PaopaocatDSH-Setup-v2.3.0-x64.exe](https://github.com/zmm863-commits/dsh-desktop-pack/releases/download/v2.3.0/PaopaocatDSH-Setup-v2.3.0-x64.exe) | 147MB |

> 💡 如果 GitHub 下载慢，可以使用 [ghproxy 加速](https://ghproxy.com/https://github.com/zmm863-commits/dsh-desktop-pack/releases/download/v2.3.0/PaopaocatDSH-Setup-v2.3.0-x64.exe)

---

## 0. 桌面版特点综述

### 一句话介绍

**泡泡猫 DSH 桌面版**是一个开箱即用的 AI 助手桌面客户端，基于 DeepSeek Harness 构建，内置 17 个插件，支持 DeepSeek / MiMo / 任意 OpenAI 兼容 API，一键安装即可使用。

### 核心亮点

| 特点 | 说明 |
|------|------|
| 🚀 **一键安装** | NSIS 安装程序，双击运行，自动配置环境 |
| 🎨 **精美主题** | 内置泡泡猫玻璃主题（glassmorphism 风格），猫爪印、小鱼装饰 |
| 🎲 **骰子游戏** | 内置骰子大作战（6 种玩法），单人 AI 对战 + 联机 |
| 🎬 **影视工具** | 泡泡猫影视工具，支持文生图/视频、剧本导入、故事板 |
| 👁️ **视觉能力** | 内置视觉路由，让文字模型也能"看"图片（OCR、问答、定位） |
| 🤖 **领域专家** | 22 个领域专家可召唤（前端、安全、营销、设计等） |
| ⏰ **定时任务** | 支持创建自动化任务，定时执行代码、研究等 |
| 💬 **IM 连接** | 可接入微信、企微、钉钉、飞书、QQ、Telegram |
| 📝 **便签功能** | 彩色标签、置顶、定时提醒、密码保护 |
| 🔌 **插件市场** | 可视化插件市场，浏览、搜索、一键安装社区插件 |
| 🧩 **GenUI 组件** | 在对话中渲染交互式 UI（图表、表单、3D 场景等） |
| 📖 **短剧创作** | Oh Story 短剧创作工具，从剧本到分镜到生产 |
| 🔄 **故障转移** | LLM 故障自动切换备用模型，保证服务不中断 |
| 🛡️ **开箱即用** | 内置 Node.js、Git，无需额外安装任何依赖 |
| 🌐 **本地运行** | 所有数据在本地，不上传到任何服务器 |
| 🆓 **完全免费** | 使用免费 API（DeepSeek / MiMo），无需付费 |

### 与在线版 DSH 的区别

| 对比项 | 在线版 DSH | 泡泡猫桌面版 |
|--------|-----------|-------------|
| 安装方式 | 命令行 `npm install` | 双击 exe 安装 |
| 依赖要求 | 需要 Node.js、Git | 内置，零依赖 |
| 插件数量 | 手动安装 | 17 个预装 |
| 主题 | 默认主题 | 泡泡猫玻璃主题 |
| 更新方式 | 命令行更新 | 下载新版本安装 |
| 适合人群 | 开发者 | 所有用户 |

### 适用场景

- **日常 AI 对话**：DeepSeek / MiMo 聊天、写作、翻译
- **代码开发**：Agent 自动写代码、调试、部署
- **内容创作**：短剧剧本、小说写作、视频解说
- **视觉任务**：图片 OCR、视觉问答、截图分析
- **自动化**：定时任务、日报生成、代码审查
- **团队协作**：IM 机器人接入、多人共享

---

## 1. 项目概述

### 1.1 目标

将服务器上运行的 DSH（DeepSeek Harness）及其全部插件打包为 Windows 安装程序（NSIS），实现一键安装、开箱即用。

### 1.2 核心需求

| 需求 | 说明 |
|------|------|
| 包含全部插件 | 17 个 bundle，一个也不能少 |
| 不含真实 API Key | data-template 中的 settings.yaml 已清理 |
| 安装路径英文 | 文档提示用户避免中文路径 |
| 版本号递增 | 每次编译版本号必须涨一次 |
| 先测试后发布 | 测试通过才发布到 GitHub Release |

---

## 2. 安装包结构

```
PaopaocatDSH-Setup-v2.3.0-x64.exe (147MB)
├── node/                    # Node.js v22.23.2 (Windows x64)
├── app/                     # DSH 核心 (@deepseek-ai/dsh 0.1.5-rc.1)
│   └── node_modules/
│       ├── @deepseek-ai/    # DSH 核心模块
│       ├── koffi/           # v3.1.6 (原生 FFI)
│       ├── @koromix/koffi-win32-x64/  # Windows 原生二进制
│       ├── node-addon-require-builtin-win32-x64-msvc/  # Node 内部模块访问
│       └── node-pty/        # 终端模拟
├── git/                     # Git for Windows (114MB)
├── launcher/                # 启动脚本
│   ├── start.ps1            # 主启动器 (PowerShell, UTF-8 BOM)
│   ├── first-run.ps1        # API Key 配置向导
│   └── check-settings.cjs   # settings.yaml 校验器
├── data-template/           # 首次运行时复制到 %APPDATA%\PaopaocatDSH\
│   ├── settings.yaml        # 配置模板（已清理 API Key）
│   ├── .agent-presets/      # 预设
│   └── profiles/web/
│       ├── package.json     # bundles 列表 + 依赖声明
│       ├── cordis.patch.yml # Web 服务器配置 (port 3080)
│       └── node_modules/    # 17 个插件及其依赖 (pnpm hoisted 布局)
├── paopaocat.ico            # 应用图标
└── README.txt               # 用户说明
```

### 2.1 运行时目录结构

安装后首次运行，数据被复制到 `%APPDATA%\PaopaocatDSH\`：

```
%APPDATA%\PaopaocatDSH\
├── .env                     # API Key (首次运行时由向导创建)
├── settings.yaml            # 运行配置
├── .agent-presets/          # Agent 预设
├── profiles/
│   └── web/
│       ├── package.json     # bundles 声明
│       ├── cordis.yml       # Cordis 根配置
│       ├── cordis.patch.yml # Web 服务器配置
│       └── node_modules/    # 插件（从 data-template 复制）
└── launcher.log             # 启动日志
```

---

## 3. 包含的插件（17 个 Bundle）

### 3.1 核心 Bundle（必需）

| Bundle | 说明 |
|--------|------|
| `@deepseek-ai/dsh-base` | DSH 基础服务（核心运行时） |
| `@deepseek-ai/dsh-web-app` | Web 界面核心（浏览器端 UI） |

### 3.2 功能插件

#### 🎲 dsh-dice-game — 骰子大作战
- **版本**：0.1.3
- **说明**：经典骰子游戏合集，源自中国山西晋城传统玩法。包含 6 种玩法：吹牛（单人 vs AI）、猜红点、猜红蓝、猜大小、猜单双、猜顺子。支持中英双语，侧边栏入口打开游戏面板。
- **npm**：https://www.npmjs.com/package/dsh-dice-game
- **GitHub**：https://github.com/zmm863-commits/dsh-dice-game

#### 📊 dsh-recommend — 插件推荐排行
- **版本**：0.2.0
- **说明**：DSH 插件透明排行与推荐系统。每日自动抓取 dsh-plugin 话题生态，内置公开评分模型，提供 rank/recommend/search 工具和设置页排行标签。
- **npm**：https://www.npmjs.com/package/dsh-recommend
- **GitHub**：https://github.com/zp-home/dsh-recommend

#### 🛒 dshmarket — 可视化插件市场
- **版本**：1.45.1
- **说明**：DSH 可视化插件市场。浏览、搜索、一键安装社区插件。逛一逛，点一下，装好。
- **npm**：https://www.npmjs.com/package/dshmarket
- **官网**：https://dshmarket.com
- **GitHub**：https://github.com/dsh-market/dsh-market

#### 🔄 dsh-llm-fallbacks — LLM 故障转移
- **版本**：0.4.2
- **说明**：当 LLM 请求持续失败时（重试耗尽、认证失败、配额超限、频率限制），自动切换到备用模型链。保证服务不中断。
- **npm**：https://www.npmjs.com/package/dsh-llm-fallbacks
- **GitHub**：https://github.com/omdsh-dev/dsh-llm-fallbacks

#### 📝 dsh-sticky-notes — 即时便签
- **版本**：1.0.1
- **说明**：泡泡猫的即时便签插件。在 DSH 随时记录事情，支持彩色标签、置顶、定时提醒和密码保护。
- **npm**：https://www.npmjs.com/package/dsh-sticky-notes
- **GitHub**：https://github.com/zmm863-commits/dsh-sticky-notes

#### 👁️ dsh-vision-router — 视觉路由
- **版本**：2.1.4
- **说明**：让纯文字 Agent 拥有"眼睛"。内置免费视觉链（无需 API Key），支持像素级视觉工具：视觉问答、目标定位、裁剪、像素对比、颜色提取、OCR、SVG 描摹、抠图、截图。一行命令安装，无需 Python。
- **npm**：https://www.npmjs.com/package/dsh-vision-router
- **GitHub**：https://github.com/ysr666/dsh-vision-router

#### 🎬 dsh-agnes-studio — 泡泡猫影视工具
- **版本**：0.1.0
- **说明**：充分利用 Agnes AI 免费生图/视频大模型。支持文生图、图生图、多图合成、文生视频、图生视频、剧本导入（.txt/.md/.json）、故事板编排。全局浮层，不堵对话框。支持 Agnes / DeepSeek / Qwen / 豆包 / MiniMax / Ollama 六大厂商。
- **npm**：https://www.npmjs.com/package/dsh-agnes-studio

#### 🐱 dsh-client-ui-paopaocat — 泡泡猫玻璃主题
- **版本**：0.1.0
- **说明**：基于 Seaglass 架构的可爱蓝白 glassmorphism 主题。含淡雅/蓝色双风格切换，猫爪印、小鱼、泡泡装饰。支持流体色盘、壁纸、鲸鱼动画、聚光灯效果。
- **npm**：https://www.npmjs.com/package/dsh-client-ui-paopaocat
- **GitHub**：https://github.com/zmm863-commits/dsh-client-ui-paopaocat

#### 🏢 @michengai/dsh-agency-agents — Agency 领域专家
- **版本**：0.1.41
- **说明**：可召唤的领域专家阵容。22 个细分领域（前端、后端、安全、营销、设计、金融等），每个专家有独立人设和专业能力。支持单专家召唤和多专家并行团队。
- **npm**：https://www.npmjs.com/package/@michengai/dsh-agency-agents
- **GitHub**：https://github.com/MichengAI/dsh-agency-agents

#### 📦 @michengai/dsh-archive-manager — 工作区归档管理
- **版本**：0.1.34
- **说明**：管理工作区归档。支持归档、恢复、浏览历史会话，保持工作区整洁。
- **npm**：https://www.npmjs.com/package/@michengai/dsh-archive-manager
- **GitHub**：https://github.com/MichengAI/dsh-archive-manager

#### ⏰ @michengai/dsh-automation — 定时任务/自动化
- **版本**：0.1.40
- **说明**：在独立 DSH Session 中按计划执行编码任务。支持 hourly/daily/weekly/monthly/custom 计划，Web 设置页与 Agent 双入口管理。适合日报生成、代码审查、定时研究等。
- **npm**：https://www.npmjs.com/package/@michengai/dsh-automation
- **GitHub**：https://github.com/MichengAI/dsh-automation

#### 💬 @michengai/dsh-im-connect — IM 连接
- **版本**：0.1.40
- **说明**：把本机 Agent 接入 IM 平台。支持微信、企微、钉钉、飞书、QQ、Telegram。会话与网页任务分列，互不干扰。
- **npm**：https://www.npmjs.com/package/@michengai/dsh-im-connect
- **GitHub**：https://github.com/MichengAI/dsh-im-connect

#### 🧩 @michengai/dsh-skills-manager — 技能管理
- **版本**：0.1.45
- **说明**：安全加载和管理 DSH 技能。支持跨 DSH 和常见本地 Agent 的技能管理。
- **npm**：https://www.npmjs.com/package/@michengai/dsh-skills-manager
- **GitHub**：https://github.com/MichengAI/dsh-skills-manager

#### 🎨 @changfenhuang/dsh-genui — GenUI 组件
- **版本**：0.9.9
- **说明**：在助手回复中渲染交互式 UI 组件。支持布局、图表、表单、测验、Mermaid 流程图、3D 场景等。通过 ```dsh-ui 围栏语法触发，支持 action 事件回传到模型。
- **npm**：https://www.npmjs.com/package/@changfenhuang/dsh-genui
- **GitHub**：https://github.com/omdsh-dev/dsh-genui

#### 📖 @oh-story/dsh — Oh Story 短剧创作
- **版本**：0.1.8
- **说明**：短剧/漫剧/互动游戏/视频解说全链路创作工具。从剧本写作、角色设计、分镜编排到图片/视频生产，一站式完成。支持 creator-first 五文档路由、本地 Dashboard。
- **npm**：https://www.npmjs.com/package/@oh-story/dsh
- **GitHub**：https://github.com/zenstory-ai/oh-story-dsh

### 3.3 插件速查表

| 插件 | 类别 | 一句话说明 | npm |
|------|------|-----------|-----|
| dsh-dice-game | 🎮 游戏 | 6 种骰子玩法，单人 AI + 联机 | [npm](https://www.npmjs.com/package/dsh-dice-game) |
| dsh-recommend | 📊 排行 | 插件透明排行与推荐 | [npm](https://www.npmjs.com/package/dsh-recommend) |
| dshmarket | 🛒 市场 | 可视化插件市场，一键安装 | [npm](https://www.npmjs.com/package/dshmarket) |
| dsh-llm-fallbacks | 🔄 稳定 | LLM 故障自动切换备用模型 | [npm](https://www.npmjs.com/package/dsh-llm-fallbacks) |
| dsh-sticky-notes | 📝 工具 | 彩色便签，置顶、提醒、加密 | [npm](https://www.npmjs.com/package/dsh-sticky-notes) |
| dsh-vision-router | 👁️ 视觉 | 让文字模型"看"图片，OCR+定位 | [npm](https://www.npmjs.com/package/dsh-vision-router) |
| dsh-agnes-studio | 🎬 影视 | 文生图/视频，剧本+故事板 | [npm](https://www.npmjs.com/package/dsh-agnes-studio) |
| dsh-client-ui-paopaocat | 🎨 主题 | 蓝白玻璃主题，猫爪装饰 | [npm](https://www.npmjs.com/package/dsh-client-ui-paopaocat) |
| @michengai/dsh-agency-agents | 🏢 专家 | 22 个领域专家可召唤 | [npm](https://www.npmjs.com/package/@michengai/dsh-agency-agents) |
| @michengai/dsh-archive-manager | 📦 管理 | 工作区归档与恢复 | [npm](https://www.npmjs.com/package/@michengai/dsh-archive-manager) |
| @michengai/dsh-automation | ⏰ 自动 | 定时执行编码任务 | [npm](https://www.npmjs.com/package/@michengai/dsh-automation) |
| @michengai/dsh-im-connect | 💬 IM | 接入微信/企微/钉钉/飞书/QQ | [npm](https://www.npmjs.com/package/@michengai/dsh-im-connect) |
| @michengai/dsh-skills-manager | 🧩 管理 | 技能加载与管理 | [npm](https://www.npmjs.com/package/@michengai/dsh-skills-manager) |
| @changfenhuang/dsh-genui | 🎨 UI | 对话中渲染交互式组件 | [npm](https://www.npmjs.com/package/@changfenhuang/dsh-genui) |
| @oh-story/dsh | 📖 创作 | 短剧全链路创作工具 | [npm](https://www.npmjs.com/package/@oh-story/dsh) |

### 3.4 已排除的插件

| 插件 | 排除原因 |
|------|----------|
| `dsh-client-ui-seaglass` | 与 paopaocat 主题冲突（applyFluidPalettes 未定义） |
| `dsh-paperclip` | 用户要求关闭 |
| `dsh-popout-sidebar` | 用户要求关闭 |
| `dsh-mnemon` | 依赖链过深，暂不包含 |

---

## 4. 启动流程

### 4.1 start.ps1 五步启动

```
[1/5] 检查数据目录
  ├─ 首次运行：robocopy data-template → %APPDATA%\PaopaocatDSH\
  └─ 已初始化：跳过

[2/5] 检查 API Key
  ├─ .env 不存在：弹出 first-run.ps1 向导
  └─ .env 已存在：跳过

[3/5] 校验配置文件
  ├─ settings.yaml 不存在：从模板创建
  ├─ settings.yaml 损坏：用模板覆盖重建
  └─ check-settings.cjs 校验通过

[4/5] 准备运行环境
  ├─ 设置 PATH：git/cmd, node, git/mingw64/bin
  └─ 检测 Edge/Chrome 浏览器路径

[4.5] 端口检测
  ├─ 3080 已占用：直接打开浏览器
  └─ 3080 空闲：继续启动

[5/5] 启动 DSH 服务
  └─ node app/lib/bin.js web
```

### 4.2 关键环境变量

| 变量 | 值 | 说明 |
|------|----|------|
| `DSH_HOME` | `%APPDATA%\PaopaocatDSH` | DSH 数据目录 |
| `PATH` | 包含 `git/cmd` 和 `node` | 内置工具路径 |
| `PUPPETEER_EXECUTABLE_PATH` | Edge/Chrome 路径 | 无头浏览器 |

### 4.3 文件编码要求

| 文件 | 编码 | 说明 |
|------|------|------|
| `start.ps1` | UTF-8 with BOM (`EF BB BF`) | Windows PowerShell 要求 |
| `first-run.ps1` | UTF-8 with BOM | 同上 |
| `check-settings.cjs` | UTF-8 | Node.js 脚本 |

> **注意**：PowerShell 需要 BOM 才能正确识别 UTF-8 中文注释。没有 BOM 会导致 `#` 被当作命令执行。

---

## 5. 技术难点与解决方案

### 5.1 koffi 原生模块版本不匹配

**问题**：`Mismatched native Koffi modules`

**原因**：koffi 主包是 3.2.1，但 `@koromix/koffi-win32-x64` 是 3.1.6（从工作包复制）。版本不匹配导致原生模块加载失败。

**解决**：从工作包复制 koffi 3.1.6 主包，确保主包和原生二进制版本一致。

```
app/node_modules/koffi/                    → v3.1.6
app/node_modules/@koromix/koffi-win32-x64/ → v3.1.6
```

### 5.2 插件找不到（Cannot find package）

**问题**：所有插件报 `ERR_MODULE_NOT_FOUND`

**原因**：DSH 的 `cordis-plugin-loader` 使用 Node.js ESM `import()` 加载插件。解析路径从 `app/node_modules/@deepseek-ai/cordis-plugin-loader/lib/index.js` 开始，沿 `node_modules` 链向上查找。插件在 `profiles/web/node_modules/` 里，不在解析路径上。

**关键发现**：DSH 使用 `ModuleLoader.fromInternal()` 访问 Node.js 内部模块加载器。有了内部加载器，可以用 `baseUrl`（profile 目录）作为解析起点，从而找到 `profiles/web/node_modules/` 里的插件。

**解决**：安装 `node-addon-require-builtin-win32-x64-msvc`，这是访问 Node.js 内部模块加载器所必需的原生模块。

```javascript
// DSH 的解析链：
// 1. ModuleLoader.fromInternal() 获取 Node 内部加载器
// 2. internal.import(name, baseUrl, {})
//    baseUrl = profile 目录的 file:// URL
// 3. 从 profile 目录开始解析 → 找到 profiles/web/node_modules/
```

### 5.3 NSIS 中文文件名段错误

**问题**：NSIS 3.08 在 Linux 上编译时，`File /r` 遇到中文文件名会段错误。

**原因**：NSIS 的文件操作对 Unicode 文件名支持不完整。

**解决**：
1. 打包前将所有中文文件名转为英文（拼音或 hash）
2. 使用 `File /r` 直接复制 data-template（不用 zip）

```python
# 中文文件名转换示例
风格化三维.md → stylized-3d.md
Q版表达.md    → chibi-expression.md
水墨笔触.md   → ink-brush.md
```

### 5.4 pnpm vs npm 的 node_modules 结构

**问题**：npm 安装的插件在 Windows 上解析失败。

**原因**：DSH 使用 pnpm 管理依赖。pnpm 的 `nodeLinker: hoisted` 布局创建扁平化的 `node_modules`，与 npm 的嵌套结构不同。

**解决**：
1. 安装 pnpm：`npm install -g pnpm`
2. 在 `profiles/web/` 目录下用 pnpm 安装依赖
3. 使用 `pnpm install --no-frozen-lockfile`

```
profiles/web/
├── pnpm-workspace.yaml
├── pnpm-lock.yaml
└── node_modules/
    ├── .pnpm/            # pnpm 内部存储
    ├── .modules.yaml     # pnpm 配置
    ├── dsh-dice-game/    # 扁平化的真实目录（非符号链接）
    └── ...
```

### 5.5 PowerShell UTF-8 BOM 问题

**问题**：`# : 无法将"#"项识别为 cmdlet...`

**原因**：PowerShell 需要 UTF-8 BOM (`EF BB BF`) 才能正确识别 UTF-8 编码。没有 BOM 时，中文注释的第一个字节被当作命令执行。

**陷阱**：
```bash
# ❌ 错误：会创建双重 BOM
printf '\xEF\xBB\xBF' >> file.ps1  # 追加 BOM

# ✅ 正确：先去掉所有 BOM，再加一个
python3 -c "
with open('file.ps1', 'rb') as f:
    data = f.read()
data = data.replace(b'\xef\xbb\xbf', b'')
data = b'\xef\xbb\xbf' + data
with open('file.ps1', 'wb') as f:
    f.write(data)
"
```

### 5.6 PpcLayer.applyFluidPalettes 未定义

**问题**：`dsh-client-ui-paopaocat` 的 `PpcLayer.refreshTheme()` 调用了 `this.applyFluidPalettes()`，但该方法未定义。

**原因**：`applyFluidPalettes` 在 `dsh-client-ui-seaglass` 的 `AquaLayer` 中定义，但 `PpcLayer`（paopaocat 主题）也调用了这个方法却没有定义。服务器上可能通过浏览器缓存或某种机制隐藏了这个错误。

**解决**：
1. 从 bundles 中移除 `dsh-client-ui-seaglass`
2. 给 `PpcLayer` 添加 `applyFluidPalettes` 和 `fluidParams` 方法

```javascript
// 添加到 PpcLayer 类中
applyFluidPalettes() {
    this.mainFluid?.setParams(this.fluidParams());
}
fluidParams() {
    return { hue: this.settings.fluidHue, depth: this.settings.fluidDepth };
}
```

### 5.7 robocopy vs zip 解压

**问题**：zip 解压无法保留 pnpm 的符号链接结构。

**解决**：改用 robocopy（和工作包一致）：
- 安装时：`File /r` 将 data-template 复制到安装目录
- 首次运行：`robocopy $tpl $data /E` 复制到 %APPDATA%

---

## 6. DSH 插件加载机制

### 6.1 加载流程

```
node app/lib/bin.js web
  │
  ├─ loadProfile("web", installAnchor, home)
  │   ├─ resolveProfileDir("web", home)
  │   │   → %APPDATA%\PaopaocatDSH\profiles\web
  │   │
  │   ├─ readProfileManifest(dir)
  │   │   → 读取 profiles/web/package.json 的 bundles 列表
  │   │
  │   └─ for each bundle in bundles:
  │       ├─ resolveBundleDir(bundleName, installAnchor, profileDir)
  │       │   ├─ 从 installAnchor (app/) 查找
  │       │   └─ 从 profileDir 查找 ← 找到插件的关键
  │       │
  │       └─ 读取插件的 cordis.patch.yml
  │
  ├─ healProfilesModuleFallback(installAnchor, profile)
  │   ├─ 在 $DSH_HOME/profiles/node_modules/ 创建符号链接
  │   └─ 在 profile/node_modules/ 创建依赖符号链接
  │
  ├─ boot(configPath, patches, bareModuleBaseUrl)
  │   ├─ new Context()
  │   ├─ ctx.baseUrl = profile 目录的 file:// URL
  │   ├─ mountRootInclude(ctx, configPath, patches)
  │   │   └─ 创建 cordis:include 入口
  │   │
  │   └─ loader.import(name)
  │       ├─ 如果 internal 可用：internal.import(name, baseUrl, {})
  │       │   → 从 profile 目录解析 → 找到 profiles/web/node_modules/
  │       └─ 否则：import(name) ← 从 app/node_modules 解析 → 找不到！
  │
  └─ assertEntriesActivated(ctx)
      └─ 检查所有插件是否成功激活
```

### 6.2 resolveBundleDir 解析逻辑

```javascript
function resolveBundleDir(binName, packageName, installAnchor, profileDir) {
    for (const anchor of [installAnchor, join(profileDir, "package.json")]) {
        const dir = packageDirFromAnchor(anchor, packageName);
        if (dir !== undefined) return dir;
    }
    throw new Error(`cannot resolve ${packageName}`);
}

function packageDirFromAnchor(anchor, packageName) {
    // 使用 Node.js 的 createRequire 解析路径
    for (const searchPath of createRequire(anchor).resolve.paths(packageName)) {
        const candidate = join(searchPath, packageName);
        if (existsSync(join(candidate, "package.json"))) return candidate;
    }
}
```

### 6.3 ModuleLoader.fromInternal() 的作用

```javascript
// cordis-plugin-loader 的内部加载器
function fromInternal() {
    const [major] = process.versions.node.split(".").map(Number);
    if (major < 22) return;  // 需要 Node.js 22+
    
    // 需要 node-addon-require-builtin-win32-x64-msvc
    const raw = requireInternal("internal/modules/esm/loader")
        ?.getOrInitializeCascadedLoader();
    
    if (!raw) return;  // 没有原生模块 → 无法访问内部加载器
    return Object.assign(raw, { version });
}
```

**关键依赖链**：
```
cordis-plugin-loader
  → ModuleLoader.fromInternal()
    → node-addon-require-builtin
      → node-addon-native-custom-loader
        → node-addon-require-builtin-win32-x64-msvc  ← 必须有这个原生模块！
```

---

## 7. 构建流程

### 7.1 环境要求

| 工具 | 版本 | 用途 |
|------|------|------|
| NSIS | 3.08 | Windows 安装程序打包 |
| Python3 | 3.x | 脚本处理 |
| Node.js | 22+ | pnpm 安装插件 |
| pnpm | 12.x | 插件依赖管理 |

### 7.2 构建步骤

```bash
# 1. 准备目录结构
/root/dshpack-v2/
├── node/          # 从 Node.js 官网下载 Windows x64 版本
├── app/           # DSH 核心（从服务器复制）
├── git/           # Git for Windows
├── launcher/      # 启动脚本
├── data-template/ # 数据模板
├── installer.nsi  # NSIS 脚本
└── dist/          # 输出目录

# 2. 安装插件（用 pnpm）
cd data-template/profiles/web
pnpm install --no-frozen-lockfile

# 3. 从服务器复制本地开发的插件
cp -aL /dsh/profiles/web/node_modules/dsh-agnes-studio ...
cp -aL /dsh/profiles/web/node_modules/dsh-client-ui-paopaocat ...

# 4. 修复中文文件名
python3 rename_chinese.py

# 5. 修复原生模块
cp -a /working-installer/app/node_modules/koffi app/node_modules/
cp -a /working-installer/app/node_modules/@koromix/koffi-win32-x64 app/node_modules/
cp -a /working-installer/app/node_modules/node-addon-require-builtin-win32-x64-msvc app/node_modules/

# 6. 修复 paopaocat applyFluidPalettes
# （给 PpcLayer 添加缺失的方法）

# 7. 更新版本号
sed -i 's/v2\.2\.9/v2.3.0/g' installer.nsi launcher/start.ps1

# 8. 确保 start.ps1 有 UTF-8 BOM
python3 -c "
with open('launcher/start.ps1', 'rb') as f:
    data = f.read()
data = data.replace(b'\xef\xbb\xbf', b'')
data = b'\xef\xbb\xbf' + data
with open('launcher/start.ps1', 'wb') as f:
    f.write(data)
"

# 9. 编译
makensis -V2 installer.nsi
```

### 7.3 NSIS 脚本关键配置

```nsi
; installer.nsi
!define APPVERSION "2.3.0"
CRCCheck on
SetCompressor /solid lzma
Unicode true

Section "Install"
  SetOutPath "$INSTDIR"
  File /r "${SRCDIR}/node"
  File /r "${SRCDIR}/app"
  File /r "${SRCDIR}/git"
  File /r "${SRCDIR}/launcher"
  File /r "${SRCDIR}/data-template"    ; 中文文件名已转英文
  File "${SRCDIR}/paopaocat.ico"
SectionEnd
```

---

## 8. 版本迭代记录

| 版本 | 日期 | 变更 | 结果 |
|------|------|------|------|
| v2.1.3 | 09-15 | 初始版本 | first-run.ps1 内容为空 |
| v2.1.4 | 09-15 | 修复 first-run.ps1 | 能启动但插件不全 |
| v2.1.5 | 09-15 | 补充插件 | data-template 不完整 |
| v2.1.6 | 09-15 | 补充插件 | 闪退（缺 BOM） |
| v2.1.7 | 09-15 | 修复 BOM | 闪退（缺 BOM） |
| v2.1.8 | 09-15 | 修复 BOM | ✅ 能启动 |
| v2.1.9 | 09-15 | 移除 luxon | ✅ |
| v2.2.0 | 09-15 | 添加 Junction 链接 | 16 个插件 pending |
| v2.2.1 | 09-15 | 补全 mnemon 依赖 | Junction 方向错误 |
| v2.2.2 | 09-15 | 添加 dsh-base/dsh-web-app | 缺少核心 bundle |
| v2.2.3 | 09-15 | 复制 koffi-win32-x64 | koffi 版本不匹配 |
| v2.2.4 | 09-16 | pnpm + robocopy | 全部插件报 Cannot find package |
| v2.2.5 | 09-16 | 修复双重 BOM | 同上 |
| v2.2.6 | 09-16 | koffi 对齐 + node-addon 原生模块 | ✅ 进入页面！ |
| v2.2.7 | 09-16 | seaglass 降级 1.6.6 | applyFluidPalettes 错误 |
| v2.2.8 | 09-16 | 全部插件换服务器版本 | 同上 |
| v2.2.9 | 09-16 | 修复 paopaocat applyFluidPalettes | ✅ 完全正常！ |
| v2.3.0 | 09-16 | 去掉 seaglass | ✅ 最终版本 |

---

## 9. 关键文件清单

### 9.1 launcher/start.ps1

- **编码**：UTF-8 with BOM（EF BB BF）
- **行数**：~115 行
- **功能**：五步启动流程
- **关键函数**：`Log()`, `Fail()`, `Test-Settings()`

### 9.2 launcher/first-run.ps1

- **编码**：UTF-8 with BOM
- **功能**：API Key 配置向导（WinForms GUI）
- **UI 风格**：暗色主题（#1E212B 背景，#E8C97A 标题）
- **验证**：Key 长度 ≥ 10 字符

### 9.3 launcher/check-settings.cjs

- **编码**：UTF-8
- **功能**：校验 settings.yaml 格式
- **依赖**：yaml 库（内嵌）

### 9.4 data-template/profiles/web/package.json

- **bundles**：17 个插件声明
- **dependencies**：16 个依赖（含 file: 引用）

### 9.5 installer.nsi

- **压缩**：/solid lzma + CRCCheck on
- **Unicode**：true
- **输出**：dist/PaopaocatDSH-Setup-v${VERSION}-x64.exe

---

## 10. 已知限制与注意事项

### 10.1 安装路径

- **必须使用英文路径**，否则可能出现不可预知的问题
- 推荐：`D:\Programs\PaopaocatDSH`
- 避免：`D:\软件\泡泡猫DSH`

### 10.2 端口占用

- 默认端口：3080
- 如果端口被占用，启动器会直接打开浏览器（不会重复启动）

### 10.3 API Key

- 首次运行时弹出配置向导
- 支持 DeepSeek / MiMo / 任意 OpenAI 兼容 API
- Key 存储在 `%APPDATA%\PaopaocatDSH\.env`

### 10.4 数据持久化

- 所有数据在 `%APPDATA%\PaopaocatDSH\`
- 卸载安装包不会删除数据目录
- 如需完全卸载，需手动删除 `%APPDATA%\PaopaocatDSH\`

### 10.5 Windows Defender

- 首次运行可能触发 Windows Defender SmartScreen 警告
- 因为安装包没有代码签名证书
- 点击"更多信息"→"仍要运行"即可

---

## 11. 故障排查

### 11.1 启动后浏览器未自动打开

手动访问：`http://127.0.0.1:3080`

### 11.2 查看启动日志

```
%APPDATA%\PaopaocatDSH\launcher.log
```

### 11.3 插件加载失败

1. 检查 `%APPDATA%\PaopaocatDSH\profiles\web\node_modules\` 是否存在
2. 如果不存在，删除 `%APPDATA%\PaopaocatDSH\` 后重新运行

### 11.4 端口 3080 被占用

```powershell
# 查看占用端口的进程
netstat -ano | findstr :3080

# 结束进程
taskkill /PID <进程ID> /F
```

### 11.5 Node.js 错误

- 确保安装路径不含中文
- 检查 `launcher.log` 中的具体错误信息
- 如果是 koffi 错误，可能是杀毒软件拦截了原生 DLL

---

## 12. 更新插件的方法

如需更新某个插件版本：

```bash
# 1. 进入 data-template/profiles/web
cd /root/dshpack-v2/data-template/profiles/web

# 2. 用 pnpm 更新指定插件
pnpm update <插件名>

# 3. 检查是否有中文文件名
find /root/dshpack-v2/data-template -name "*[一-龥]*"

# 4. 如果有，转英文
python3 rename_chinese.py

# 5. 更新版本号
sed -i 's/v2\.3\.0/v2.3.1/g' /root/dshpack-v2/installer.nsi /root/dshpack-v2/launcher/start.ps1

# 6. 编译
cd /root/dshpack-v2 && makensis -V2 installer.nsi
```

---

## 13. 与工作包（PaopaocatDSH-Setup-x64_6.exe）的对比

| 对比项 | 工作包 | v2.3.0 |
|--------|--------|--------|
| DSH 版本 | 0.1.1-rc.2 | 0.1.5-rc.1 |
| 启动器版本 | v1.2.0 | v2.3.0 |
| Bundle 数量 | 16 | 17 |
| 包管理器 | pnpm | pnpm |
| data-template 传输 | robocopy | robocopy |
| NSIS 打包 | File /r | File /r |
| koffi | 3.1.6 | 3.1.6 |
| 安装包大小 | 109MB | 147MB |
| 含 oh-story | ❌ | ✅ |
| 含 agnes-studio | ❌ | ✅ |
| 含 dsh-llm-fallbacks | ❌ | ✅ |
| 含 dsh-sticky-notes | ❌ | ✅ |
| 含 paopaocat 主题 | ❌ | ✅ |
| 含 seaglass 主题 | ❌ | ❌（已排除） |
| 含 dsh-mnemon | ✅ | ❌（依赖链过深） |

---

*文档结束*
