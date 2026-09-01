# 🖥️ 泡泡猫 DSH 桌面版安装包

> 一键安装 DeepSeek Harness 到 Windows，开箱即用。

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)

## ✨ 特点

- 🚀 一键安装，无需配置
- 🎲 预装骰子大作战、文件上传等插件
- 🐱 泡泡猫主题皮肤
- 📦 内置 Node.js + MinGit，无需额外安装

## 📦 包含内容

| 组件 | 说明 |
|---|---|
| DeepSeek Harness | AI 助手核心 |
| dsh-paopaocat-suite | 泡泡猫插件合集 |
| Node.js v22 | 运行环境 |
| MinGit | Git 工具 |

## 🔧 构建

需要在 Linux 环境（如 Docker 容器）中构建：

```bash
# 1. 先安装泡泡猫插件合集
dsh plugin --profile web add dsh-paopaocat-suite

# 2. 运行构建脚本
chmod +x build.sh
./build.sh
```

构建完成后，安装包在 `dist/` 目录。

## 📁 目录结构

```
├── build.sh           # 构建脚本
├── src/               # 源文件（启动器、设置等）
├── installer/         # NSIS 安装脚本
├── assets/            # 图标等资源
├── payload/           # 构建产物（临时）
├── downloads/         # 下载的依赖（临时）
└── dist/              # 最终安装包
```

## 📝 使用说明

1. 下载 `dist/paopaocat-dsh-setup.exe`
2. 双击运行安装
3. 按向导完成安装
4. 桌面出现「泡泡猫 DSH」图标，双击启动

## 🔗 相关链接

- [泡泡猫插件合集](https://github.com/zmm863-commits/dsh-paopaocat-suite)
- [DeepSeek Harness](https://github.com/deepseek-ai/dsh)

## 📄 许可证

MIT
