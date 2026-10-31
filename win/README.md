# Windows 构建

产出：`dist/PaopaocatDSH-Setup-v<版本>-x64.exe`（NSIS 安装器，约 389 MB）。

## 1. 先把 payload 准备好

`rebuild.sh` 打包的是本目录下这五个目录，仓库里只带**脚手架**，大件需要自己拿：

| 目录 | 内容 | 怎么来 |
|---|---|---|
| `app/` | DSH 本体（含 `node_modules`） | `npm pack @deepseek-ai/dsh@0.1.7-rc.2` 解开，或从 `npm i -g` 的目录取 |
| `node/` | Node 22 win-x64 | 官方 `node-v22.x.x-win-x64.zip` 解包（保留 `node.exe`） |
| `git/` | MinGit | 官方 MinGit zip 解包（`git/cmd/git.exe` 那一套） |
| `data-template/` | 安装后释放到 `%APPDATA%\PaopaocatDSH` 的模板 | 本仓库已带脚手架，需自己装插件依赖（见下） |
| `launcher/` | 启动器 | 本仓库已带 ✅ |

**装 data-template 的插件依赖**（仓库不带 `node_modules`）：

```bash
cd win/data-template/profiles/web
npm install --legacy-peer-deps        # 按 package.json 的 dependencies 拉插件
```

装完跑一次依赖层修复（幂等，可重复执行）：

```bash
python3 tools/fix-profile-deps.py win
```

它做两件事：① 删掉插件内部嵌套的旧 `@deepseek-ai/*` 副本（这些副本会遮蔽提升层导致
`failed to import`）；② 按插件逐个把缺失依赖补进 `data-template/profiles/node_modules` 提升层。
补完记得改 `data-template/profiles/node_modules/.paopaocat-deps-layer` 里的标记（启动器靠它判断
要不要重新同步）。

## 2. 一条命令构建

```bash
bash win/rebuild.sh
```

脚本内部五步：

1. **修依赖层** — `tools/fix-profile-deps.py`
2. **实体化外部绝对符号链接** — NSIS 会跟随链接把外部内容打进包，用户机上是死链
3. **干净构建目录** — `cp -al` 到 `../win-build/`（见铁律 2）
4. **`LC_ALL=C.UTF-8 makensis`** — 见铁律 1
5. **五项校验** — `tools/verify-payload.py`，不通过就不产出安装包

## 3. NSIS 铁律

1. **必须带 `LC_ALL=C.UTF-8`**。默认 POSIX locale 下，安装脚本里任何非 ASCII（中文文件名、中文提示语）
   都会段错误 `exit 139`，且报错信息毫无提示性——这是本项目历史上最费时间的一个坑。
2. **不要用 `SetCompressor /solid lzma` / `bzip2`**：同样段错误，用默认 `zlib`。
3. **编译目录必须只含 payload**。`File /r` 会连带遍历父目录的兄弟目录；在本目录直接编译会把
   `tpl/`、`tpl2/` 之类暂存目录打进包（实测 +806 条目 / +87 MB）。
4. **payload 里不能有绝对符号链接**（见上）。

## 4. 安装器做了什么

- 覆盖安装前 `RMDir /r` 清空 `app / node / git / launcher / data-template`（铁律 6：只覆盖不删除会留下旧副本）
- 先跑 `launcher/stop-running.ps1` 关掉正在运行的实例，否则 `File /r` 覆盖失败
- 写完 `launcher/version.txt`（启动器靠它判断要不要重新同步程序文件）
- 结束页直接拉起 `launcher/start.ps1`

## 5. 发版时的同步清单

- [ ] `installer.nsi` 的 `!define APPVERSION`
- [ ] `data-template/profiles/web/package.json` 的插件清单（bundle 数量变了要一并改 launcher 提示）
- [ ] `data-template/profiles/node_modules/.paopaocat-deps-layer` 的标记
- [ ] `README.txt` 里的版本号与插件说明
- [ ] 打完包跑 `python3 tools/verify-payload.py <解包目录>`
