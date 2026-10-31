# PR: 添加泡泡猫 DSH 桌面版

## 提交到

- 仓库：https://github.com/fendouai/awesome-deepseek-harness
- 分类：客户端（桌面与终端）

## PR 标题

feat: add 泡泡猫 DSH Desktop installer

## PR 描述

```markdown
### 泡泡猫 DSH 桌面版

开箱即用的 Windows 安装包，基于 DeepSeek Harness 0.1.5-rc.1 构建。

**特点：**
- 🚀 一键安装（NSIS 安装程序，双击运行）
- 🎨 泡泡猫玻璃主题（glassmorphism 风格）
- 🔌 内置 17 个插件（骰子游戏、影视工具、视觉路由、领域专家、定时任务、IM 连接等）
- 🛡️ 零依赖（内置 Node.js v22 + Git for Windows）
- 💾 首次运行自动配置（robocopy 复制数据模板）

**下载：**
- [GitHub Release](https://github.com/zmm863-commits/dsh-desktop-pack/releases/tag/v2.3.0)
- 安装包 147MB（分两卷下载，需合并）

**仓库：**
- https://github.com/zmm863-commits/dsh-desktop-pack
- 技术文档：[TECHNICAL_DOC.md](https://github.com/zmm863-commits/dsh-desktop-pack/blob/main/TECHNICAL_DOC.md)

**截图：**
![实际运行截图](https://github.com/zmm863-commits/dsh-desktop-pack/releases/download/v2.3.0/Screenshot_20260916225508.png)

**与同类项目对比：**

| 对比项 | 泡泡猫桌面版 | 其他桌面版 |
|--------|-------------|-----------|
| 安装方式 | NSIS 安装程序 | Electron 应用 |
| 插件预装 | 17 个 | 需手动安装 |
| 主题 | 泡泡猫玻璃主题 | 默认主题 |
| 包大小 | 147MB | 通常 >200MB |
```

## 插入位置

在 `README.zh-CN.md` 的「客户端（桌面与终端）」分类中，添加一行：

```markdown
| [泡泡猫 DSH 桌面版](https://github.com/zmm863-commits/dsh-desktop-pack) | ⭐ | 开箱即用的 Windows 安装包，内置 17 个插件，支持 DeepSeek/MiMo API |
```

## 提交步骤

1. Fork https://github.com/fendouai/awesome-deepseek-harness
2. 编辑 `README.zh-CN.md`
3. 在「客户端（桌面与终端）」分类添加上述行
4. 提交 PR

## 注意事项

- README 是中英双语，如果需要英文版，也可以在 `README.md` 中添加
- 该仓库有自动链接核验，确保 URL 可访问
- 该仓库有质量等级系统，新项目可能标记为「待验证」
