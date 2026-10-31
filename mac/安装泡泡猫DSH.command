#!/bin/bash
# ============================================================
#  泡泡猫 DSH 桌面版 — macOS 一键安装
# ============================================================
#
#  用法：
#    1) 把本文件和安装包（PaopaocatDSH-macOS-*.tar.gz 或 .zip）
#       放在同一个文件夹里
#    2) 双击本文件
#       · 如果系统提示「无法打开，因为来自身份不明的开发者」，
#         请在文件上【右键 → 打开】，再点一次「打开」
#    3) 剩下的全自动：解压 → 安装到「应用程序」→ 清除安全拦截 → 启动
#
#  也可以不放安装包：双击后会弹出文件选择框，让你手动选。
# ============================================================

# 关于严格模式：
#   这里刻意【不】使用 `set -u`。
#   macOS 自带的是 2007 年的 bash 3.2，它在处理「变量后紧跟多字节字符」
#   时会把中文/全角标点的字节误当成变量名的一部分 —— 例如变量 VAR 后面直接
#   跟一个全角括号时，bash 会去找名为 "VAR（" 的变量，从而抛 unbound variable
#   并中断安装。
#   本脚本已把这类写法统一改成 ${VAR} 形式规避，但为了不让终端用户因为
#   任何一处疏漏而卡在半途，这里宁可选宽松模式 —— 安装脚本能跑完比严格更重要。
#   同时下方所有写操作都带显式错误检查。

# ── 配置 ──
VERSION="3.1.15"
APP_NAME="PaopaocatDSH.app"
APP_DISPLAY="泡泡猫 DSH 桌面版"
MIN_MACOS_MAJOR=11

# 官网提供 macOS 版之后，把直链填在这里即可启用「自动下载」模式
# 例如：DOWNLOAD_URL="https://soft.zmm168.top/d/deepseek-harness/macos"
DOWNLOAD_URL=""

# ── 彩色输出 ──
if [ -t 1 ]; then
  C_OK=$'\033[32m'; C_ERR=$'\033[31m'; C_INFO=$'\033[36m'
  C_WARN=$'\033[33m'; C_BOLD=$'\033[1m'; C_END=$'\033[0m'
else
  C_OK=""; C_ERR=""; C_INFO=""; C_WARN=""; C_BOLD=""; C_END=""
fi

# 输出函数用 %b，让消息里的 \n 在终端显示为真实换行
ok()    { printf '%s  ✅  %b%s\n' "$C_OK"   "$1" "$C_END"; }
err()   { printf '%s  ❌  %b%s\n' "$C_ERR"  "$1" "$C_END"; }
info()  { printf '%s  ▸   %b%s\n' "$C_INFO" "$1" "$C_END"; }
warn()  { printf '%s  ⚠   %b%s\n' "$C_WARN" "$1" "$C_END"; }
step()  { printf '\n%s── %s ──%s\n' "$C_BOLD" "$1" "$C_END"; }

# 把消息转成可安全嵌入 AppleScript 字符串的形式。
# 要点：
#   1) AppleScript 字符串不支持 \n 转义，换行必须写成  " & return & "
#   2) 消息里若含双引号，必须转义为 \" ，否则会破坏字符串
#   3) 两条替换的顺序不能颠倒：先转义原有引号，再插入用于拼接的新引号
# 另注：bash 的 ${var//pat/rep} 中 pat 是 glob 而非正则，无法替换字面的 \n，
#       故必须借助 sed；而 sed 的 replacement 里 & 有特殊含义，需转义为 \& 。
as_msg() { printf '%s' "$1" | sed 's/"/\\"/g; s/\\n/" \& return \& "/g'; }

# 以对话框形式报错（双击运行时用户看不到终端的情况也能收到）
fail() {
  err "$1"
  osascript -e "display dialog \"$(as_msg "$1")\" buttons {\"好\"} default button 1 with title \"$APP_DISPLAY\" with icon stop" >/dev/null 2>&1
  printf '\n按回车键关闭窗口...'
  read -r _ 2>/dev/null
  exit 1
}

pause_exit() {
  printf '\n%s按回车键关闭窗口...%s' "$C_INFO" "$C_END"
  read -r _ 2>/dev/null
  exit "${1:-0}"
}

# 询问（返回 0=是）
ask() {
  local r
  r=$(osascript -e "display dialog \"$(as_msg "$1")\" buttons {\"取消\", \"确定\"} default button \"确定\" with title \"$APP_DISPLAY\"" 2>/dev/null)
  case "$r" in *确定*) return 0 ;; *) return 1 ;; esac
}

printf '\n%s' "$C_BOLD"
echo "=============================================="
echo "   泡泡猫 DSH 桌面版  一键安装（macOS）"
echo "   版本 v$VERSION"
echo "=============================================="
printf '%s\n' "$C_END"

# ============================================================
step "1/6  检查运行环境"
# ============================================================

[ "$(uname -s)" = "Darwin" ] || fail "本安装脚本只能在 macOS 上运行。"
ok "系统：macOS $(sw_vers -productVersion 2>/dev/null)"

MACOS_VER="$(sw_vers -productVersion 2>/dev/null | cut -d. -f1)"
if [ -n "$MACOS_VER" ] && [ "$MACOS_VER" -lt "$MIN_MACOS_MAJOR" ] 2>/dev/null; then
  warn "当前系统 macOS ${MACOS_VER}，本软件要求 macOS $MIN_MACOS_MAJOR.0 或更高"
  ask "你的系统版本较低（macOS ${MACOS_VER}），软件可能无法启动。\n\n仍要继续安装吗？" || fail "已取消安装。"
fi

# 芯片架构
if [ "$(sysctl -n hw.optional.arm64 2>/dev/null)" = "1" ]; then
  ARCH="Apple Silicon（M 系列）"
else
  ARCH="Intel"
fi
ok "芯片：$ARCH"

# 可用空间（GB）
FREE_GB=$(df -g . 2>/dev/null | awk 'NR==2 {print $4}')
if [ -n "$FREE_GB" ] && [ "$FREE_GB" -lt 3 ] 2>/dev/null; then
  fail "磁盘可用空间不足（当前约 $FREE_GB GB，需要至少 3 GB）。\n请清理后重试。"
fi
[ -n "$FREE_GB" ] && ok "可用空间：约 $FREE_GB GB"

# ============================================================
step "2/6  查找安装包"
# ============================================================

SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
ARCHIVE=""

# 1) 先在本脚本所在目录里找
for f in "$SELF_DIR"/PaopaocatDSH-macOS-*.tar.gz "$SELF_DIR"/PaopaocatDSH-macOS-*.zip \
         "$SELF_DIR"/*.tar.gz "$SELF_DIR"/*.zip; do
  if [ -f "$f" ]; then
    ARCHIVE="$f"
    break
  fi
done

if [ -n "$ARCHIVE" ]; then
  ok "发现安装包：$(basename "$ARCHIVE")"
else
  # 2) 没有就弹对话框让用户选
  info "当前文件夹里没找到安装包，请在弹出的窗口中选择"
  PICKED=$(osascript <<'APPLESCRIPT' 2>/dev/null
try
    set f to choose file with prompt "请选择下载好的安装包（PaopaocatDSH-macOS-… 的 .zip 或 .tar.gz）"
    return POSIX path of f
on error
    return ""
end try
APPLESCRIPT
)
  [ -n "$PICKED" ] || fail "没有选择安装包，已取消。"
  [ -f "$PICKED" ] || fail "找不到你选择的文件。"
  ARCHIVE="$PICKED"
  ok "已选择：$(basename "$ARCHIVE")"
fi

# 体积合理性检查
ARCHIVE_MB=$(( $(stat -f%z "$ARCHIVE" 2>/dev/null || echo 0) / 1048576 ))
if [ "$ARCHIVE_MB" -lt 100 ] 2>/dev/null; then
  warn "安装包只有 ${ARCHIVE_MB}MB，明显偏小，可能下载不完整"
  ask "安装包看起来不完整（仅 ${ARCHIVE_MB}MB，正常约 245~280MB）。\n\n仍要继续吗？" || fail "已取消。"
fi
ok "安装包大小：${ARCHIVE_MB}MB"

# ============================================================
step "3/6  解压（约需 1~2 分钟，请耐心等待）"
# ============================================================

WORK="$(mktemp -d /tmp/paopaocat-install.XXXXXX)" || fail "无法创建临时目录。"
cleanup() { rm -rf "$WORK" 2>/dev/null; }
trap cleanup EXIT

info "正在解压到临时目录..."
case "$ARCHIVE" in
  *.zip)
    # ditto 能正确保留 macOS 权限；失败则退回 unzip
    if ! ditto -x -k "$ARCHIVE" "$WORK" 2>/dev/null; then
      ( cd "$WORK" && unzip -q -o "$ARCHIVE" ) || fail "解压失败，安装包可能已损坏。"
    fi
    ;;
  *.tar.gz|*.tgz)
    tar -xzf "$ARCHIVE" -C "$WORK" || fail "解压失败，安装包可能已损坏。"
    ;;
  *)
    fail "无法识别的文件格式：$(basename "$ARCHIVE")"
    ;;
esac

# 有时会多包一层目录，往下找一层
if [ ! -d "$WORK/$APP_NAME" ] && [ ! -d "$WORK/PaopaocatDSH.app" ]; then
  INNER=$(find "$WORK" -maxdepth 2 -name "*.app" -type d 2>/dev/null | head -1)
  [ -n "$INNER" ] && WORK="$(dirname "$INNER")"
fi

[ -d "$WORK/$APP_NAME" ] || fail "解压后没有找到 ${APP_NAME}，安装包可能不完整。"
ok "解压完成（$(du -sh "$WORK/$APP_NAME" 2>/dev/null | cut -f1)）"

# ============================================================
step "4/6  检查与修复文件权限"
# ============================================================

# 权限丢失会导致双击毫无反应，这里主动修一遍
FIXED=0
for f in \
  "$WORK/$APP_NAME/Contents/MacOS/PaopaocatDSH" \
  "$WORK/$APP_NAME/Contents/Resources/launcher/start.command" \
  "$WORK/$APP_NAME/Contents/Resources/launcher/bin/git" \
  "$WORK/$APP_NAME/Contents/Resources/runtime/node-arm64/bin/node" \
  "$WORK/$APP_NAME/Contents/Resources/runtime/node-x64/bin/node" ; do
  if [ -e "$f" ] && [ ! -x "$f" ]; then
    chmod 755 "$f" 2>/dev/null && FIXED=$((FIXED + 1))
  fi
done
# node-pty 的辅助进程也必须可执行
find "$WORK/$APP_NAME/Contents/Resources/app/node_modules/node-pty/prebuilds" \
     -name "spawn-helper" -type f 2>/dev/null | while IFS= read -r h; do
  [ -x "$h" ] || chmod 755 "$h" 2>/dev/null
done

if [ "$FIXED" -gt 0 ]; then
  ok "已修复 $FIXED 个文件的可执行权限"
else
  ok "可执行权限正常"
fi

# ============================================================
step "5/6  安装到「应用程序」"
# ============================================================

if [ -w /Applications ]; then
  DEST_DIR="/Applications"
else
  DEST_DIR="$HOME/Applications"
  mkdir -p "$DEST_DIR" 2>/dev/null
  warn "当前账户对 /Applications 无写权限，将安装到 ~/Applications"
fi

DEST="$DEST_DIR/$APP_NAME"

# 已存在旧版本？
if [ -d "$DEST" ]; then
  warn "已经装过一份：$DEST"
  OLD_VER=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$DEST/Contents/Info.plist" 2>/dev/null || echo "未知")
  info "已安装版本：$OLD_VER  →  即将安装：$VERSION"
  ask "检测到已安装的泡泡猫 DSH（版本 ${OLD_VER}）。\n\n要用新版本替换它吗？\n（你的设置和聊天记录不会受影响）" \
    || fail "已取消安装。"
  # 若正在运行，先退出，否则删不掉
  if pgrep -f "$DEST/Contents/Resources" >/dev/null 2>&1; then
    info "正在关闭旧版本..."
    pkill -f "$DEST/Contents/Resources" 2>/dev/null
    sleep 2
  fi
  rm -rf "$DEST" || fail "无法删除旧版本，请手动删除后重试：$DEST"
fi

info "正在复制到 ${DEST_DIR}（约需 1 分钟）..."
cp -R "$WORK/$APP_NAME" "$DEST" || fail "复制失败，请检查磁盘空间。"
ok "已安装到：$DEST"

# 清除从网络继承的隔离标记 —— 这一步能让 app 直接双击打开，无需再手动放行
if xattr -cr "$DEST" 2>/dev/null; then ok "已清除安全隔离标记"; else warn "未能清除隔离标记（一般不影响使用）"; fi

# ── 安装后校验：以前这一步缺失，导致解压不完整时只报出一句
#    LaunchServices 的 "kLSNoExecutableErr: The executable is missing"，很难定位 ──
BUNDLE_EXE="$DEST/Contents/MacOS/PaopaocatDSH"
[ -f "$BUNDLE_EXE" ] || fail "安装不完整：缺少 $BUNDLE_EXE\n\n多半是解压不完整。请删除已装的那份，重新解压安装包后再运行本脚本。"
[ -x "$BUNDLE_EXE" ] || chmod 755 "$BUNDLE_EXE" 2>/dev/null
[ -x "$BUNDLE_EXE" ] || fail "安装后的可执行文件没有执行权限：$BUNDLE_EXE"
[ -x "$DEST/Contents/Resources/launcher/start.command" ] || chmod 755 "$DEST/Contents/Resources/launcher/start.command" 2>/dev/null
[ -x "$DEST/Contents/Resources/launcher/bin/git" ] || chmod 755 "$DEST/Contents/Resources/launcher/bin/git" 2>/dev/null
ok "程序包结构完整（可执行文件就位）"

# 刷新 LaunchServices 注册：替换安装后系统常保留旧记录，
# 表现为 open 报 kLSNoExecutableErr（可执行文件明明在）。这一步不影响用户数据。
LSREG="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
if [ -x "$LSREG" ]; then
  "$LSREG" -f "$DEST" >/dev/null 2>&1 && ok "已刷新系统应用注册" || true
fi

# ============================================================
step "6/6  完成"
# ============================================================

printf '\n%s' "$C_OK"
echo "  ┌────────────────────────────────────────────┐"
echo "  │   安装成功！                                 │"
echo "  └────────────────────────────────────────────┘"
printf '%s\n' "$C_END"
echo
echo "     位置： $DEST"
echo "     版本： v$VERSION"
echo

# 启动
if ask "是否现在就启动「${APP_DISPLAY}」？\n\n首次启动会弹出一个终端窗口显示进度，\n并让你填写 API Key（AI 模型的钥匙）。"; then
  info "正在启动..."
  # 优先直接用终端运行启动脚本：绕开 app 注册（注册异常时 open 会失败），
  # 成功与否都能如实反馈，不再像以前那样无论结果都打印「已启动」。
  if open -a Terminal "$DEST/Contents/Resources/launcher/start.command" 2>/dev/null; then
    ok "已启动，请看新弹出的终端窗口"
  elif open "$DEST" 2>/dev/null; then
    ok "已启动"
  else
    warn "自动启动失败——请手动双击：$DEST"
    warn "或在「终端」里执行：open -a Terminal \"$DEST/Contents/Resources/launcher/start.command\""
  fi
  echo
  echo "     浏览器稍后会自动打开 http://127.0.0.1:3080"
  echo "     （如果没自动打开，手动访问即可）"
else
  echo "     稍后可在「启动台」或「应用程序」里双击启动。"
fi

echo
echo "  提示：首次运行如果没有联网，或提示端口占用，"
echo "        可以查看日志：~/Library/Application Support/PaopaocatDSH/launcher.log"
echo

pause_exit 0
