#!/usr/bin/env bash
# 泡泡猫 DSH 桌面版 · 一键重建脚本（在本 Linux 容器内执行）
set -euo pipefail
R=/root/软件/dsh-desktop-pack

echo "[1/7] 复制 DSH 主程序树（展平符号链接）"
rm -rf "$R/payload"; mkdir -p "$R"/payload/{node,app,data-template,launcher}
cp -rL /usr/local/lib/node_modules/@deepseek-ai/dsh/. "$R/payload/app/"

echo "[2/7] 下载 Node v22 win-x64 与便携 MinGit（bash 工具内置）"
curl -s -o "$R/downloads/node.zip" https://nodejs.org/dist/v22.23.2/node-v22.23.2-win-x64.zip
unzip -o -q "$R/downloads/node.zip" '*/node.exe' '*/LICENSE' -d "$R/payload/tmp"
mv "$R/payload/tmp"/*/node.exe "$R/payload/tmp"/*/LICENSE "$R/payload/node/"; rm -rf "$R/payload/tmp"
mkdir -p "$R/payload/git"
curl -sL -o "$R/downloads/minging.zip" https://npmmirror.com/mirrors/git-for-windows/v2.47.1.windows.1/MinGit-2.47.1-64-bit.zip
unzip -o -q "$R/downloads/minging.zip" -d "$R/payload/git"
cp "$R/payload/git/usr/bin/sh.exe" "$R/payload/git/usr/bin/bash.exe"   # MinGit 只带 sh.exe，复制即 bash

echo "[3/7] 替换原生模块为 win32-x64 版本"
NM="$R/payload/app/node_modules"
rm -rf "$NM"/@koromix/koffi-* "$NM"/@img/sharp-* "$NM"/@img/sharp-libvips-* \
       "$NM"/node-addon-require-builtin-* \
       "$NM"/@deepseek-ai/node-addon-landlock-run-linux-* \
       "$NM"/@vscode/ripgrep-linux-x64
mkdir -p "$NM"/@koromix/koffi-win32-x64 "$NM"/@img/sharp-win32-x64 \
         "$NM"/@vscode/ripgrep-win32-x64 "$NM"/node-addon-require-builtin-win32-x64-msvc
cd "$R/downloads"
npm pack @koromix/koffi-win32-x64@3.1.6 @img/sharp-win32-x64@0.35.3 \
         node-addon-require-builtin-win32-x64-msvc@0.1.5 @vscode/ripgrep-win32-x64@1.18.0
tar -xzf koromix-koffi-win32-x64-3.1.6.tgz              -C "$NM/@koromix/koffi-win32-x64" --strip-components=1
tar -xzf img-sharp-win32-x64-0.35.3.tgz                 -C "$NM/@img/sharp-win32-x64" --strip-components=1
tar -xzf vscode-ripgrep-win32-x64-1.18.0.tgz            -C "$NM/@vscode/ripgrep-win32-x64" --strip-components=1
tar -xzf node-addon-require-builtin-win32-x64-msvc-0.1.5.tgz -C "$NM/node-addon-require-builtin-win32-x64-msvc" --strip-components=1

echo "[4/7] 组装数据模板（profiles 全插件 + 预设，绑定 127.0.0.1）"
DT="$R/payload/data-template"
mkdir -p "$DT/profiles" "$DT/.agent-presets"
cp -rL /dsh/profiles/web "$DT/profiles/web"
cp -rL /dsh/.agent-presets/liangshen "$DT/.agent-presets/liangshen"
sed -i 's/host: 0.0.0.0/host: 127.0.0.1/' "$DT/profiles/web/cordis.patch.yml"
sed -i 's|link:/dsh/profiles/web/node_modules/dsh-deep-whale/maid-atelier|file:./node_modules/dsh-deep-whale/maid-atelier|' \
    "$DT/profiles/web/package.json"
cp "$R/src/settings.yaml"   "$DT/settings.yaml"
printf '\xEF\xBB\xBF' > "$DT/.env.example"; cat "$R/src/env.example" >> "$DT/.env.example"

echo "[5/7] 启动器与说明（bat→GBK、ps1→UTF-8 BOM；⚠️文件名必须纯 ASCII，makensis 打不开中文路径）"
iconv -f UTF-8 -t GBK "$R/src/dsh-launcher.bat" > "$R/payload/launcher/dsh-launcher.bat"
printf '\xEF\xBB\xBF' > "$R/payload/launcher/first-run.ps1"; cat "$R/src/first-run.ps1" >> "$R/payload/launcher/first-run.ps1"
printf '\xEF\xBB\xBF' > "$R/payload/README.txt"; cat "$R/src/使用说明.txt" >> "$R/payload/README.txt"

echo "[6/7] 图标"
node "$R/src/gen-icon.js" "$R/assets/paopaocat.ico"
cp "$R/assets/paopaocat.ico" "$R/payload/paopaocat.ico"

echo "[7/7] 编译 NSIS 安装包（在 ASCII 镜像路径编译，规避 makensis 中文路径段错误/打不开）"
rm -rf /root/dshpack && mkdir -p /root/dshpack/dist
cp -a "$R/payload" "$R/installer" "$R/assets" /root/dshpack/
sed -i "s|$R|/root/dshpack|" /root/dshpack/installer/paopaocat-dsh.nsi
cd /root/dshpack && makensis -V2 installer/paopaocat-dsh.nsi
mkdir -p "$R/dist" && cp /root/dshpack/dist/*.exe "$R/dist/"
ls -lh "$R/dist/"
