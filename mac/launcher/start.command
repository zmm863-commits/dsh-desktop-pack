#!/bin/bash
# 泡泡猫 DSH 桌面版 — macOS 启动器 v3.1.15
# 兼容 macOS 11.0+ ，同时支持 Apple Silicon 与 Intel
# 注意：本脚本需兼容 macOS 自带的 bash 3.2，勿使用 bash 4+ 语法


APP_NAME="泡泡猫 DSH"
VERSION="3.1.15"
PORT=3080

# ── 定位自身与资源目录（解析符号链接）──
SELF="$0"
while [ -L "$SELF" ]; do
  LINK="$(readlink "$SELF")"
  case "$LINK" in
    /*) SELF="$LINK" ;;
    *)  SELF="$(dirname "$SELF")/$LINK" ;;
  esac
done
LAUNCHER_DIR="$(cd "$(dirname "$SELF")" && pwd)"
ROOT="$(cd "$LAUNCHER_DIR/.." && pwd)"

DATA="$HOME/Library/Application Support/PaopaocatDSH"
LOG="$DATA/launcher.log"

mkdir -p "$DATA" 2>/dev/null
: > "$LOG" 2>/dev/null

# ── 工具函数 ──
log() {
  printf '%s  %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" >> "$LOG" 2>/dev/null
  printf '    %s\n' "$1"
}

alert() {
  osascript -e "display dialog \"$1\" buttons {\"好\"} default button 1 with title \"$APP_NAME\" with icon stop" >/dev/null 2>&1
}

fatal() {
  log "FAIL: $1"
  alert "$1

详细日志：$LOG"
  printf '\n启动失败：%s\n日志文件：%s\n' "$1" "$LOG"
  printf '\n按回车键关闭窗口...'
  read -r _ 2>/dev/null
  exit 1
}

port_busy() {
  nc -z 127.0.0.1 "$PORT" >/dev/null 2>&1
}

# 优先用 Chrome/Edge 打开界面。
# 原因：DSH 前端在 Safari 下会一直白屏（cookie 策略 / ES Module crossorigin 更严格），
# 换 Chrome/Edge 立即正常。这里替用户做选择，避免他们以为装坏了。
open_url() {
  local url="$1" b
  # 先确认浏览器真的装了再调 open，避免逐个尝试时系统弹「找不到应用程序」的框
  for b in "Google Chrome" "Microsoft Edge" "Brave Browser" "Chromium" "Vivaldi"; do
    if [ -d "/Applications/$b.app" ] || [ -d "$HOME/Applications/$b.app" ]; then
      if open -a "$b" "$url" 2>/dev/null; then
        log "step5 已用 $b 打开界面"
        printf '    已用 %s 打开界面\n' "$b"
        return 0
      fi
    fi
  done
  log 'step5 未找到 Chrome/Edge，回退到系统默认浏览器'
  printf '\n    ⚠️  未检测到 Chrome / Edge，已用系统默认浏览器打开。\n'
  printf '        若界面一片空白，那是 Safari 的兼容问题 ——\n'
  printf '        请安装 Chrome 后重新双击启动即可。\n\n'
  open "$url" 2>/dev/null
  return 0
}

# ── 芯片架构探测（按硬件而非进程，避免 Rosetta 干扰）──
detect_arch() {
  if [ "$(sysctl -n hw.optional.arm64 2>/dev/null)" = "1" ]; then
    echo "arm64"
    return
  fi
  case "$(uname -m)" in
    arm64) echo "arm64" ;;
    *)     echo "x64" ;;
  esac
}
ARCH="$(detect_arch)"
NODE_BIN="$ROOT/runtime/node-$ARCH/bin/node"

# ── 开场 ──
printf '\n'
printf '泡泡猫 DSH 桌面版 %s（macOS / %s）\n' "$VERSION" "$ARCH"
printf '日志文件：%s\n' "$LOG"
log "==================== launcher start ===================="
log "arch = $ARCH"
log "root = $ROOT"

[ -x "$NODE_BIN" ] || fatal "缺少 $ARCH 版运行环境（${NODE_BIN}），请重新安装"

# ── 1/5 初始化 / 升级数据目录 ──
printf '\n[1/5] 检查数据目录...\n'
TPL="$ROOT/data-template"
VERFILE="$ROOT/launcher/version.txt"
STAMP="$DATA/.install-version"

INSTVER=""
[ -f "$VERFILE" ] && INSTVER="$(tr -d ' \t\r\n' < "$VERFILE")"
RECVER=""
[ -f "$STAMP" ] && RECVER="$(tr -d ' \t\r\n' < "$STAMP")"

# 依赖提升层（profiles/node_modules）是插件解析传递依赖所必需的。
# 判断依据是模板里的「层标记文件」，而不是目录是否存在 —— 目录可能被 DSH 的
# 兜底机制或旧安装建出来却内容残缺，仅凭存在性会误判为已就绪。
LAYERDIR="$DATA/profiles/node_modules"
LAYERMARK="$LAYERDIR/.paopaocat-deps-layer"
TPLLAYERMARK="$TPL/profiles/node_modules/.paopaocat-deps-layer"
LAYER_OK=0
if [ -f "$LAYERMARK" ] && [ -f "$TPLLAYERMARK" ] && [ "$(cat "$LAYERMARK" 2>/dev/null)" = "$(cat "$TPLLAYERMARK" 2>/dev/null)" ]; then
  LAYER_OK=1
fi

if [ ! -d "$DATA/profiles/web/node_modules" ]; then
  log 'step1 初始化数据目录'
  [ -d "$TPL" ] || fatal "缺少模板目录，请重新安装"
  if rsync -a "$TPL/" "$DATA/" >>"$LOG" 2>&1; then
    if [ -n "$INSTVER" ]; then printf '%s' "$INSTVER" > "$STAMP"; fi
    log 'step1 完成'
  else
    fatal "初始化数据目录失败，详见日志"
  fi
elif { [ -n "$INSTVER" ] && [ "$INSTVER" != "$RECVER" ]; } || [ "$LAYER_OK" = "0" ]; then
  if port_busy; then
    log 'step1 检测到 DSH 正在运行，本次不同步（下次启动生效）'
  elif [ ! -d "$TPL" ]; then
    log 'step1 模板缺失，跳过同步'
  else
    if [ -n "$RECVER" ]; then
      log "step1 版本 $RECVER -> ${INSTVER}，同步程序文件"
    else
      log "step1 旧版本未记录，按 v$INSTVER 同步程序文件"
    fi
    printf '    正在更新到 v%s，保留你的设置、API Key 与会话...\n' "$INSTVER"
    # profile 的 node_modules 整层重建：rsync -a 只覆盖不删除，上一次安装遗留的
    # 旧依赖会一直留着并污染解析（表现为插件 failed to import）。
    rm -rf "$DATA/profiles/web/node_modules" "$DATA/profiles/node_modules"
    if rsync -a \
        --exclude='.env' \
        --exclude='settings.yaml' \
        --exclude='.credentials.yaml' \
        --exclude='launcher.log' \
        --exclude='sessions' \
        --exclude='archives' \
        "$TPL/" "$DATA/" >>"$LOG" 2>&1; then
      printf '%s' "$INSTVER" > "$STAMP"
      log 'step1 同步完成'
    else
      log 'step1 同步失败（继续启动）'
    fi
  fi
else
  log 'step1 跳过（已是最新）'
fi

# ── 2/5 API Key ──
printf '[2/5] 检查 API Key...\n'
ENVFILE="$DATA/.env"
if [ ! -f "$ENVFILE" ]; then
  log 'step2 弹出密钥向导'
  KEY="$(osascript <<'APPLESCRIPT' 2>/dev/null
display dialog "欢迎使用 泡泡猫 DSH 桌面版 ✨

首次使用需要一把 API Key（AI 模型的钥匙）。

免费获取方式：
· DeepSeek：platform.deepseek.com → API keys
· 也可使用任何兼容 OpenAI 的 Key

请粘贴你的 Key（至少 10 个字符）：" default answer "" with hidden answer buttons {"取消", "确定"} default button "确定" with title "泡泡猫 DSH — 首次配置"
return text returned of result
APPLESCRIPT
)"
  KEY="$(printf '%s' "$KEY" | tr -d ' \t\r\n')"
  if [ ${#KEY} -lt 10 ]; then
    fatal '未输入有效的 API Key，已取消'
  fi
  printf 'DEEPSEEK_API_KEY=%s\n' "$KEY" > "$ENVFILE"
  chmod 600 "$ENVFILE" 2>/dev/null
  log 'step2 密钥已写入'
else
  log 'step2 跳过（.env 已存在）'
fi

# ── 3/5 校验配置文件 ──
printf '[3/5] 校验配置文件...\n'
SETTINGS="$DATA/settings.yaml"
CHECKER="$ROOT/launcher/check-settings.cjs"
SETTINGS_IMPORTED="$DATA/settings.yaml.imported"
if [ ! -f "$SETTINGS" ]; then
  if [ -f "$SETTINGS_IMPORTED" ]; then
    # Mnemon 已接管 settings.yaml（改名 imported 并转存配置），不要再从模板重建，
    # 否则每次启动都会重演「旧设置导入」，两个插件抢同一把写锁会告警超时。
    log 'step3 settings.yaml 已由 Mnemon 接管（settings.yaml.imported 存在），跳过重建'
  elif [ -f "$TPL/settings.yaml" ]; then
    cp "$TPL/settings.yaml" "$SETTINGS"
    log 'step3 settings.yaml 缺失，已从模板创建'
  else
    log 'step3 settings.yaml 缺失，跳过'
  fi
elif [ -f "$CHECKER" ]; then
  if ! "$NODE_BIN" "$CHECKER" "$ROOT" "$SETTINGS" >>"$LOG" 2>&1; then
    log 'step3 settings.yaml 损坏，用模板覆盖重建'
    if [ -f "$TPL/settings.yaml" ]; then
      cp "$TPL/settings.yaml" "$SETTINGS"
    fi
  fi
fi
log 'step3 settings.yaml 校验通过'

# ── 4/5 准备运行环境 ──
printf '[4/5] 准备运行环境（内置 Node / Python、系统 Git）...\n'

# 内置 Python 3 必须排在 PATH 最前面：
# Oh Story 的小说创作技能会探测 python3，而 macOS 上的 /usr/bin/python3 其实是
# Xcode 命令行工具的占位符 —— 未安装时被调用会弹出「要下载安装命令行开发者工具」
# 的系统弹窗（好几个 GB）。这里用内置的便携 Python 顶上去，用户无需安装任何东西。
# 自愈：部分解压工具会丢掉可执行位（安装脚本也会修，这里再兜一层）
[ -x "$ROOT/launcher/bin/git" ] || chmod 755 "$ROOT/launcher/bin/git" 2>/dev/null

# 把 git 包装器放在 PATH 最前面：macOS 自带的 /usr/bin/git 是占位桩，
# 没装命令行开发者工具时一执行就会弹「下载命令行工具」的系统框
# （DSH 的 workspace-changes 会在会话事件里跑 git rev-parse）。
# 包装器有真 git 就转发，没有就干净失败并给出提示 —— 不会弹框。
export PATH="$ROOT/launcher/bin:$ROOT/runtime/python-$ARCH/bin:$ROOT/runtime/node-$ARCH/bin:$PATH"

# 自检：确认内置 Python 可用（不可用也不阻断启动，仅记录）
if [ -x "$ROOT/runtime/python-$ARCH/bin/python3" ]; then
  log "step4 内置 Python: $ROOT/runtime/python-$ARCH/bin/python3"
else
  log "step4 内置 Python 缺失（${ARCH}），相关创作技能可能不可用"
fi

if "$ROOT/launcher/bin/git" --version >/dev/null 2>&1; then
  log "step4 git: 可用（$(command -v git)）"
else
  log 'step4 本机无可用 git（未安装命令行开发者工具）：git 相关功能不可用；需要时执行 xcode-select --install'
fi

# ── 4.5 已在运行则只开页面 ──
if port_busy; then
  log '端口 3080 已监听，视为已在运行'
  open "http://127.0.0.1:$PORT"
  log 'launcher exit(0)'
  printf '\nDSH 已经在运行，已为你打开浏览器。\n'
  exit 0
fi

# ── 5/5 启动服务 ──
printf '[5/5] 正在启动服务...\n'
printf '（关闭本窗口即停止 DSH）\n'
printf '\n正在启动 DSH 服务，请稍等一会（首次启动约需 10~30 秒）...\n'
printf '启动完成后会自动打开浏览器，请不要关闭本窗口。\n\n'

export DSH_HOME="$DATA"

# 随包内置的 Mnemon CLI（长期记忆的存储后端）；缺失时不设置，回退到用户自装的 mnemon
MNEMON_CLI="$DATA/mnemon-cli/node_modules/@mnemon-dev/mnemon/bin/mnemon.js"
if [ -f "$MNEMON_CLI" ]; then
  export MNEMON_CLI_PATH="$MNEMON_CLI"
  log "step5 Mnemon CLI: $MNEMON_CLI"
fi
log 'step5 启动 DSH web 服务'

RUNLOG="$DATA/.run-output.log"
: > "$RUNLOG" 2>/dev/null

# 后台守候：抓到 token 后用「首选浏览器」打开界面。
# 不让 DSH 自己开，是因为它只会用系统默认浏览器（Safari），而 Safari 上会白屏。
(
  n=0
  while [ "$n" -lt 180 ]; do
    TOKEN="$(grep -o 'token=[A-Za-z0-9_-]*' "$RUNLOG" 2>/dev/null | head -1 | cut -d= -f2)"
    if [ -n "$TOKEN" ]; then
      URL="http://127.0.0.1:$PORT/?token=$TOKEN"
      printf '\n    ───────────────────────────────────────────────────────\n'
      printf '     界面地址：%s\n' "$URL"
      printf '     （首次请用此地址访问；成功一次后，以后直接访问\n'
      printf '       http://127.0.0.1:%s 即可）\n' "$PORT"
      printf '    ───────────────────────────────────────────────────────\n\n'
      open_url "$URL"
      break
    fi
    n=$((n + 1))
    sleep 1
  done
) &
WATCHER=$!

# --expose-internals：让 DSH 能访问 Node 内部模块加载器解析 profile 插件，
#   从而不依赖那个要求 macOS 15 的原生库，使最低系统降到 macOS 11。
# --no-open：阻止 DSH 自己用 Safari 打开（交由上面的守候逻辑选浏览器）。
"$NODE_BIN" --expose-internals "$ROOT/app/lib/bin.js" web --no-open 2>&1 | tee "$RUNLOG"
CODE="${PIPESTATUS[0]}"

kill "$WATCHER" 2>/dev/null

log "node 退出码 ${CODE}"
printf '\n泡泡猫 DSH 已退出（退出码 %s）。日志：%s\n' "$CODE" "$LOG"
if [ "$CODE" != "0" ]; then
  alert "服务异常退出（代码 ${CODE}）

日志文件：$LOG"
fi
printf '\n按回车键关闭窗口...'
read -r _ 2>/dev/null
exit 0
