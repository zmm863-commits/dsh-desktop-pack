# macOS 构建

产出两个 zip：

| 产物 | 内容 |
|---|---|
| `PaopaocatDSH-macOS-v<版本>-universal.zip` | 完整 `.app`（通用二进制，Intel + Apple Silicon） |
| `PaopaocatDSH-macOS-v<版本>-脚本安装.zip` | 上面的 zip + `安装泡泡猫DSH.command` + `使用说明.txt` |

用户只走「脚本安装」这一条路：解压 → 双击 `.command` → 装进 `/Applications` → 启动。**不提供 dmg/pkg。**

## 1. `.app` 骨架

`.app` 结构（`build.sh` 负责拼装与打补丁）：

```
PaopaocatDSH.app/
├── Contents/
│   ├── Info.plist              CFBundleExecutable=PaopaocatDSH；版本号在这里（3 处之一）
│   ├── PkgInfo
│   ├── MacOS/PaopaocatDSH      205 字节的 shell stub：打开终端跑 launcher/start.command
│   └── Resources/
│       ├── app/                DSH 本体（含 node_modules）
│       ├── runtime/
│       │   ├── node-arm64/  node-x64/        双架构 Node 22
│       │   └── python-arm64/ python-x64/     便携 Python 3.11（标准库精简）
│       ├── data-template/      释放到 ~/Library/Application Support/PaopaocatDSH
│       └── launcher/           start.command / check-settings.cjs / bin/git / version.txt
```

`build.sh` 的三处补丁：Safari polyfill（前端在 Safari 下有兼容问题）、PATH 顺序、原生包体检。

## 2. 打 zip（必须用 `mkzip.py`）

```bash
cd mac
python3 mkzip.py dist/PaopaocatDSH.app dist/PaopaocatDSH-macOS-v3.1.15-universal.zip
```

**为什么不能直接 `zip -r` / `ZipFile.write()`**：payload 里有大量符号链接（Node 的 `bin`、各种包内的
链接层）。用普通写法会把链接**解引用成实体副本**，体积涨约 30 MB，且部分相对链接在解压后失效。
`mkzip.py` 用 `ZipInfo` 手工写：`S_IFLNK | 0o777` + `ZIP_STORED`（不压缩），内容就是链接目标字符串；
打完还会自检**无绝对路径死链**。

## 3. 启动器（`launcher/`，会被注入 `.app`）

`start.command` 做五步：检查数据目录 → 同步程序文件（版本变了才同步，先整层删 `node_modules` 再拷）
→ 校验 `settings.yaml` → 准备环境 → 启动 DSH 并等 token 出界面。

三件必须保留的事：

1. **`--expose-internals` 启动参数**：给 `cordis-plugin-loader` 访问 Node 内部 ESM loader。
2. **JS 回退垫片**（`launcher/` 注入的 `node-addon-require-builtin` 实现）：官方 darwin 预编译二进制
   `minos=15.0.0`，macOS 11~14 上 `dlopen` 会被拒；而 DSH 0.1.7 的 `dsh-app-boot` 启动时**无条件**加载它。
   垫片逻辑：原生可用 → 走原生；原生不可用且带 `--expose-internals` → 用 `require('internal/…')`。
3. **`launcher/bin/git` 包装器**：macOS 自带的 `/usr/bin/git` 是占位桩，未装命令行开发者工具时
   一执行就弹系统下载框（DSH 的 `dsh-workspace-changes` 会在会话事件里调 git）。
   包装器把 `launcher/bin` 前置到 PATH：有真 git 就转发，没有就干净失败并提示 `xcode-select --install`。

## 4. 安装脚本做了什么

`安装泡泡猫DSH.command` 六步：检查环境（macOS ≥ 11、芯片、空间）→ 找同目录的
`PaopaocatDSH-macOS-*.zip` → 解压 → **修可执行权限**（解压工具常丢 +x）→ 复制到 `/Applications`
（先 `rm -rf` 旧版）→ `xattr -cr` 清隔离标记 + **校验包结构** + `lsregister -f` 刷新系统注册 + 启动。

> 为什么要 `lsregister`：同一路径被反复原地替换后，LaunchServices 会留陈旧记录，
> `open` 会报 `kLSNoExecutableErr: The executable is missing`（可执行文件明明在）。

## 5. 版本号有 3 处，必须同步

- [ ] `launcher/start.command` 的 `VERSION="..."`（本仓库 `mac/launcher/start.command`）
- [ ] `launcher/version.txt`
- [ ] `Contents/Info.plist` 的 `CFBundleShortVersionString`

打完包跑：

```bash
7z 解包后：python3 tools/verify-payload.py <解包后的 Resources 目录>
```

mac 包会走**垫片路径**校验（`verify-payload.py` 故意不安装 linux 预编译，强制验证回退实现）。
