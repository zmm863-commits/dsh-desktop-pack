#!/bin/bash
# ============================================================================
# 泡泡猫 DSH 桌面版 · Windows 安装包重建脚本
#
# 用法：  ./rebuild.sh
# 产物：  <本目录>/dist/PaopaocatDSH-Setup-v<版本>-x64.exe
#
# ────────────────────────────────────────────────────────────────────────────
# 本机 NSIS 3.08 的三个坑（都实测过，别再踩）：
#
# 坑 1｜locale：默认 POSIX/C 环境下 makensis 遇到任何非 ASCII 字符
#        （中文文件名、中文 UI 串）会**段错误**（exit 139）。
#        必须 `LC_ALL=C.UTF-8 makensis ...`。
#
# 坑 2｜构建目录必须干净：makensis 处理 `File /r "<目录>"` 时会连带遍历该目录
#        **父目录里的兄弟目录**。若直接在本目录编译，
#        构建暂存目录 tpl/ 与 tpl2/ 会被一起打进安装包（实测多出 806 个文件、
#        未压缩体积多 87MB）。解决：先把 payload 单独复制到干净目录再编译。
#
# 坑 3｜payload 里不能有指向外部绝对路径的符号链接：NSIS 会跟随链接把外部内容
#        一起打包（例如 dsh-agnes-studio 里指向 /dsh/... 的 6 个 npm 链接）。
#        这些链接在用户机器上本来也是死链，必须先实体化成真实目录。
#
# 另注：`SetCompressor /solid lzma` 在本机 NSIS 3.08 上也会段错误，用默认 zlib。
# ============================================================================
set -euo pipefail

# 路径自洽：脚本所在目录即 Windows 工程目录，其父目录为仓库根。
# 这样别人 clone 下来放到任意位置都能用，不依赖本机固定布局。
WIN="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$WIN/.." && pwd)"
BUILD="${BUILD_DIR:-$REPO/win-build}"
# 校验脚本可能在 <repo>/tools/ 下（开源仓库布局），也可能就在 <repo>/ 根（本地工作区布局）
if [ -f "$REPO/tools/verify-payload.py" ]; then TOOLS="$REPO/tools"; else TOOLS="$REPO"; fi
VERSION=$(grep -oP '!define APPVERSION "\K[^"]+' "$WIN/installer.nsi")
PAYLOAD=(node app git launcher data-template)

echo "▶ 版本：$VERSION"

# ── 0. 修复 profile 依赖提升层（幂等） ──
# 打包只带 profiles/web 会少掉 dev 环境里的 profiles/node_modules 提升层，
# 插件（agnes-studio / vision-router / automation 等）import 时会报
# "Cannot find package '@deepseek-ai/xxx'"。此步按插件逐个补齐。
echo "▶ [0/5] 修复 profile 依赖提升层"
python3 "$TOOLS/fix-profile-deps.py" "$WIN" | tail -3

# ── 1. 实体化 payload 里指向外部绝对路径的符号链接 ──
echo "▶ [1/5] 检查并实体化外部绝对符号链接"
python3 - "$WIN" <<'PY'
import os, sys, shutil
win = sys.argv[1]
dirs = ['node', 'app', 'git', 'launcher', 'data-template']
fixed = 0
for d in dirs:
    base = os.path.join(win, d)
    if not os.path.isdir(base):
        continue
    for root, subdirs, files in os.walk(base, followlinks=False):
        for name in list(subdirs) + list(files):
            p = os.path.join(root, name)
            if not os.path.islink(p):
                continue
            target = os.readlink(p)
            if not target.startswith('/'):
                continue
            real = os.path.realpath(p)
            os.remove(p)
            if os.path.isdir(real):
                shutil.copytree(real, p, symlinks=False)
            else:
                shutil.copy2(real, p)
            fixed += 1
            print('   实体化:', os.path.relpath(p, win))
            if name in subdirs:
                subdirs.remove(name)
print(f'   共处理 {fixed} 个外部链接')
PY

# ── 2. 准备干净构建目录（只含 payload）──
echo "▶ [2/5] 准备干净构建目录 $BUILD"
rm -rf "$BUILD"
mkdir -p "$BUILD/dist"
for d in "${PAYLOAD[@]}"; do
    cp -al "$WIN/$d" "$BUILD/$d"
done
cp -a "$WIN/paopaocat.ico" "$WIN/README.txt" "$BUILD/"
sed "s|!define SRCDIR \".*\"|!define SRCDIR \"$BUILD\"|" "$WIN/installer.nsi" > "$BUILD/installer.nsi"
echo "   构建目录内容: $(ls "$BUILD" | tr '\n' ' ')"

# ── 3. 编译（必须带 LC_ALL=C.UTF-8）──
echo "▶ [3/5] 编译（makensis，约 5–10 分钟）"
cd "$BUILD"
LC_ALL=C.UTF-8 makensis installer.nsi

# ── 4. 验证：产物条目必须恰好等于 payload ──
echo "▶ [4/5] 验证产物条目"
EXE="$BUILD/dist/PaopaocatDSH-Setup-v${VERSION}-x64.exe"
7z l -slt "$EXE" > /tmp/nsi-verify.txt
python3 - "$WIN" <<'PY'
import collections
prefixes = collections.Counter()
for line in open('/tmp/nsi-verify.txt', encoding='utf-8', errors='replace'):
    if line.startswith('Path = '):
        p = line[7:].rstrip('\n').replace('\\', '/')
        prefixes[p.split('/')[0]] += 1
allowed = {'node', 'app', 'git', 'launcher', 'data-template',
           'paopaocat.ico', 'README.txt', '$PLUGINSDIR', 'Uninstall.exe'}
# 忽略 7z 自报的容器条目（空路径 / dist/…exe / 文件名本身）
stray = {k: v for k, v in prefixes.items()
         if k not in allowed and k != '' and k != 'dist' and not k.endswith('.exe')}
for k, v in sorted(prefixes.items(), key=lambda x: -x[1]):
    print(f'   {v:6d}  {k}')
if stray:
    print('❌ 出现不该有的条目:', stray)
    raise SystemExit(1)
print('✅ 条目全部属于 payload')
PY

# ── 4.5 不变量：插件嵌套 node_modules 里不得再出现 @deepseek-ai ──
# 它们来自旧的全局安装（版本比随包 app 旧），会遮蔽提升层并让插件 import 失败
# （真机症状：agnes-studio failed to import，报 cosmokit 缺 createVolatile 导出）。
echo "▶ [4/5*] 检查是否存在遮蔽提升层的嵌套 @deepseek-ai"
NM="$BUILD/data-template/profiles/web/node_modules"
NESTED=$( { find "$NM" -type d -path '*/node_modules/@deepseek-ai' 2>/dev/null | grep -v "^$NM/@deepseek-ai$" || true; } | head -5 )
if [ -n "$NESTED" ]; then
    echo "❌ 发现嵌套 @deepseek-ai（会遮蔽提升层）："
    echo "$NESTED" | sed 's/^/     /'
    echo "   请运行 fix-profile-deps.py 清理后再构建。"
    exit 1
fi
echo "   无嵌套 @deepseek-ai ✅"

# ── 5. 三重校验：版本一致性 + 插件 import + HTTP 冒烟 ──
# 注意：只查 import 是不够的 —— 实测「旧版 dsh-host-webserver 遮蔽新版」这种情况
# 16 个插件 import 全部通过，但页面请求会崩溃返回空 body 的 HTTP 400，界面打不开。
echo "▶ [5/5] payload 三重校验（版本一致性 / import / HTTP 冒烟）"
python3 "$TOOLS/verify-payload.py" "$BUILD" || {
    echo "❌ payload 校验未通过，已中止（不产出安装包）"
    exit 1
}

cp "$EXE" "$WIN/dist/"
echo
echo "✅ 完成: $WIN/dist/PaopaocatDSH-Setup-v${VERSION}-x64.exe"
ls -l "$WIN/dist/PaopaocatDSH-Setup-v${VERSION}-x64.exe"
