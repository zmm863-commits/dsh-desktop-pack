#!/bin/bash
# ============================================================================
# 泡泡猫 DSH 桌面版 · macOS 构建与补丁脚本
#
# 两种用法：
#   1. 完整构建：  ./build.sh build  <app目录>        （在 Linux 构建机上准备 .app）
#   2. 应用补丁：  ./build.sh patch  <app目录>        （升级 DSH 后重做三个补丁）
#
# 本脚本做的是「不依赖 Mac 就能完成」的部分。真机验证必须另做。
# 详细背景见同目录 技术文档.md
# ============================================================================
set -euo pipefail

MODE="${1:-}"
APP="${2:-}"
[ -z "$MODE" ] || [ -z "$APP" ] && {
    echo "用法:"
    echo "  $0 build <app目录>    # 完整构建（准备骨架）"
    echo "  $0 patch <app目录>    # 只应用三个补丁（升级 DSH 后用）"
    exit 1
}

[ -d "$APP" ] || { echo "❌ 目录不存在: $APP"; exit 1; }
RES="$APP/Contents/Resources"
[ -d "$RES" ] || { echo "❌ 不是有效的 .app 结构（缺 Contents/Resources）"; exit 1; }

RED=$'\033[31m'; GRN=$'\033[32m'; YEL=$'\033[33m'; BLD=$'\033[1m'; RST=$'\033[0m'
ok()   { printf "${GRN}  ✅ %s${RST}\n" "$1"; }
warn() { printf "${YEL}  ⚠️  %s${RST}\n" "$1"; }
err()  { printf "${RED}  ❌ %s${RST}\n" "$1"; }
hdr()  { printf "\n${BLD}%s${RST}\n" "$1"; }

# ============================================================================
# 补丁 1：index.html 的 Safari polyfill
# ============================================================================
patch_index_html() {
    hdr "[补丁 1/3] Safari 兼容性 polyfill"
    local F="$RES/app/node_modules/@deepseek-ai/dsh-web-frontend/dist/index.html"
    if [ ! -f "$F" ]; then err "找不到 index.html: $F"; return 1; fi

    cp "$F" "$F.bak.$(date +%s)" 2>/dev/null || true

    python3 - "$F" << 'PYEOF'
import sys, re
p = sys.argv[1]
h = open(p, encoding='utf-8').read()

polyfill = '''    <!-- 兼容性补丁：Safari 16 及更早版本缺少的 ES2024/ES2025 API。
         必须在任何 module 脚本之前同步执行。使用 ES5 语法确保老解释器可解析。
         补丁清单：Promise.withResolvers / Promise.try / Object+Map.groupBy
                   AbortSignal.any / URL.parse / Iterator -->
    <script>
      (function () {
        var g = typeof globalThis !== 'undefined' ? globalThis : this;

        if (typeof Promise.withResolvers !== 'function') {
          Promise.withResolvers = function () {
            var r, j, q = new Promise(function (a, b) { r = a; j = b; });
            return { promise: q, resolve: r, reject: j };
          };
        }
        if (typeof Promise.try !== 'function') {
          Promise.try = function (fn) {
            var args = Array.prototype.slice.call(arguments, 1);
            return new Promise(function (res) { res(fn.apply(undefined, args)); });
          };
        }
        if (typeof Object.groupBy !== 'function') {
          Object.groupBy = function (items, cb) {
            var o = Object.create(null), i = 0;
            for (var k = 0; k < items.length; k++) {
              var y = cb(items[k], i++);
              if (!o[y]) { o[y] = []; }
              o[y].push(items[k]);
            }
            return o;
          };
        }
        if (typeof Map.groupBy !== 'function') {
          Map.groupBy = function (items, cb) {
            var o = new Map(), i = 0;
            for (var k = 0; k < items.length; k++) {
              var y = cb(items[k], i++);
              var b = o.get(y);
              if (!b) { b = []; o.set(y, b); }
              b.push(items[k]);
            }
            return o;
          };
        }
        if (typeof AbortSignal !== 'undefined' && typeof AbortSignal.any !== 'function') {
          AbortSignal.any = function (signals) {
            var ctrl = new AbortController();
            var arr = Array.prototype.slice.call(signals);
            var i;
            for (i = 0; i < arr.length; i++) {
              if (arr[i].aborted) { ctrl.abort(arr[i].reason); return ctrl.signal; }
            }
            var onAbort = function (ev) { ctrl.abort(ev.target.reason); };
            for (i = 0; i < arr.length; i++) {
              arr[i].addEventListener('abort', onAbort, { once: true });
            }
            return ctrl.signal;
          };
        }
        if (typeof URL !== 'undefined' && typeof URL.parse !== 'function') {
          URL.parse = function (url, base) {
            try { return new URL(url, base); } catch (e) { return null; }
          };
        }
        if (typeof Iterator === 'undefined') {
          var itProto = null;
          try {
            itProto = Object.getPrototypeOf(Object.getPrototypeOf([][Symbol.iterator]()));
          } catch (e) { itProto = null; }
          var Iter = function Iterator() {};
          if (itProto) {
            Iter.prototype = itProto;
            if (typeof itProto[Symbol.iterator] !== 'function') {
              itProto[Symbol.iterator] = function () { return this; };
            }
          }
          Iter.from = function (src) {
            return src && typeof src[Symbol.iterator] === 'function' ? src[Symbol.iterator]() : src;
          };
          try { g.Iterator = Iter; } catch (e) { window.Iterator = Iter; }
        }
      })();
    </script>
'''

# 清掉旧的补丁块（幂等）
h = re.sub(r'<!-- 兼容性补丁.*?</script>\s*', '', h, count=1, flags=re.S)

a = '<script type="module"'
if a not in h:
    print('ANCHOR_MISSING')
    sys.exit(2)
h = h.replace(a, polyfill + a, 1)
open(p, 'w', encoding='utf-8').write(h)
print('OK')
PYEOF
    local rc=$?
    if [ $rc -ne 0 ]; then err "注入失败（锚点未命中？）"; return 1; fi

    local n=0
    for k in withResolvers "Promise.try" groupBy "AbortSignal.any" "URL.parse" Iterator; do
        c=$(grep -c "$k" "$F" 2>/dev/null || echo 0)
        [ "$c" -gt 0 ] && n=$((n+1))
    done
    if [ "$n" -ge 6 ]; then ok "7 个 polyfill 已注入（检测到 $n/6 项）"
    else warn "只检测到 $n/6 项，请检查"; fi
}

# ============================================================================
# 补丁 2：terminal-bash 的 PATH 传递
# ============================================================================
patch_path() {
    hdr "[补丁 2/3] PATH 传递（内置 Python 能否被 agent 探测到）"
    local F="$RES/app/node_modules/@deepseek-ai/dsh-terminal-bash/lib/index.js"
    if [ ! -f "$F" ]; then err "找不到 terminal-bash: $F"; return 1; fi

    cp "$F" "$F.bak.$(date +%s)" 2>/dev/null || true

    python3 - "$F" << 'PYEOF'
import sys
p = sys.argv[1]
c = open(p, encoding='utf-8').read()
if 'PATH: process.env.PATH' in c:
    print('ALREADY')
    sys.exit(0)
old = 'const common = {' + chr(10) + chr(9) + chr(9) + 'TERM: "dumb",'
new = ('const common = {' + chr(10) +
       chr(9) + chr(9) + '// macOS 补丁：DSH 原本不把父进程环境传给子 shell，导致启动器注入的' + chr(10) +
       chr(9) + chr(9) + '// PATH（内置便携 Python/Node）在 agent 执行命令时丢失，技能探测 python3' + chr(10) +
       chr(9) + chr(9) + '// 会命中 /usr/bin/python3（Xcode 占位符）并触发系统下载弹窗。' + chr(10) +
       chr(9) + chr(9) + '// 仅补 PATH，保持其余环境隔离不变。' + chr(10) +
       chr(9) + chr(9) + 'PATH: process.env.PATH,' + chr(10) +
       chr(9) + chr(9) + 'TERM: "dumb",')
if old not in c:
    print('ANCHOR_MISSING')
    sys.exit(2)
open(p, 'w', encoding='utf-8').write(c.replace(old, new, 1))
print('OK')
PYEOF
    local rc=$?
    if [ $rc -eq 2 ]; then err "锚点未命中，DSH 版本可能已变"; return 1; fi

    if grep -q "PATH: process.env.PATH" "$F"; then
        ok "PATH 补丁已生效"
        if command -v node >/dev/null 2>&1; then
            node --check "$F" >/dev/null 2>&1 && ok "语法检查通过" || warn "语法检查失败"
        fi
    else
        err "补丁未生效"; return 1
    fi
}

# ============================================================================
# 补丁 3：检查 darwin 原生包是否齐全
# ============================================================================
check_native_packages() {
    hdr "[补丁 3/3] darwin 原生包完整性"

    python3 - "$RES" << 'PYEOF'
import json, os, glob, sys
res = sys.argv[1]

roots = [res + "/app/node_modules", res + "/data-template/profiles/web/node_modules"]
missing, seen = [], set()
for root in roots:
    if not os.path.isdir(root):
        continue
    for pj in glob.glob(root + "/**/package.json", recursive=True):
        if "node_modules/.bin" in pj:
            continue
        try:
            d = json.load(open(pj, encoding='utf-8'))
        except Exception:
            continue
        deps = list(d.get("optionalDependencies", {}).keys()) + \
               list(d.get("dependencies", {}).keys())
        for dep in deps:
            if "darwin" not in dep:
                continue
            key = (root, dep)
            if key in seen:
                continue
            seen.add(key)
            c1 = os.path.join(os.path.dirname(pj), "node_modules", dep)
            c2 = os.path.join(root, dep)
            if not os.path.exists(c1) and not os.path.exists(c2):
                missing.append(dep)

# 去重
missing = sorted(set(missing))
# node-addon-require-builtin 已被 --expose-internals 绕过，不算问题
missing = [m for m in missing if "node-addon-require-builtin" not in m]

if not missing:
    print("ALL_OK")
else:
    for m in missing:
        print("MISSING " + m)
PYEOF

    local out
    out=$(python3 - "$RES" << 'PYEOF'
import json, os, glob, sys
res = sys.argv[1]
roots = [res + "/app/node_modules", res + "/data-template/profiles/web/node_modules"]
seen = set()
for root in roots:
    if not os.path.isdir(root): continue
    for pj in glob.glob(root + "/**/package.json", recursive=True):
        if "node_modules/.bin" in pj: continue
        try: d = json.load(open(pj, encoding='utf-8'))
        except Exception: continue
        deps = list(d.get("optionalDependencies", {}).keys()) + list(d.get("dependencies", {}).keys())
        for dep in deps:
            if "darwin" not in dep or "node-addon-require-builtin" in dep: continue
            if dep in seen: continue
            c1 = os.path.join(os.path.dirname(pj), "node_modules", dep)
            c2 = os.path.join(root, dep)
            if not os.path.exists(c1) and not os.path.exists(c2):
                seen.add(dep)
for m in sorted(seen): print(m)
PYEOF
)

    if [ -z "$out" ]; then
        ok "所有 darwin 原生包齐全"
    else
        err "缺少以下原生包："
        echo "$out" | sed 's/^/       /'
        echo ""
        echo "     补装方法（按当前架构）："
        echo "       ARCH=\$([ \"\$(uname -m)\" = arm64 ] && echo arm64 || echo x64)"
        echo "$out" | while read -r p; do
            echo "       npm pack $p  # 然后解压到 app/node_modules/"
        done
        return 1
    fi
}

# ============================================================================
# 健康检查
# ============================================================================
health_check() {
    hdr "[健康检查]"

    # launcher 语法
    local LC="$RES/launcher/start.command"
    if [ -f "$LC" ]; then
        bash -n "$LC" 2>/dev/null && ok "start.command 语法通过" || err "start.command 语法错误"
        if grep -q '^set -u' "$LC" 2>/dev/null; then
            warn "存在 set -u（bash 3.2 上可能中断，建议移除）"
        else
            ok "无 set -u（避免 bash 3.2 中断）"
        fi

        # bash 3.2 变量边界
        local bad
        bad=$(python3 -c "
import re
lines = open('$LC', encoding='utf-8', errors='replace').read().split('\n')
pat = re.compile(r'\\\$([A-Za-z_][A-Za-z0-9_]*)(?=[^\x00-\x7f])')
hits = [(i, m.group(0)) for i, l in enumerate(lines, 1) for m in pat.finditer(l)]
print(len(hits))
" 2>/dev/null || echo "?")
        [ "$bad" = "0" ] && ok "无 bash 3.2 变量边界隐患" || warn "有 $bad 处变量后跟非 ASCII"
    else
        warn "未找到 launcher/start.command"
    fi

    # 内置凭据泄漏检查
    local leaked
    leaked=$(find "$APP" \( -name ".env" -o -name ".credentials.yaml" \) -not -name "*.example" 2>/dev/null | head -5)
    if [ -z "$leaked" ]; then ok "包内无内置凭据（.env / .credentials.yaml）"
    else err "发现凭据文件，发布前必须移除："; echo "$leaked" | sed 's/^/       /'; fi

    # 运行时
    local r
    for r in node python; do
        for a in arm64 x64; do
            if [ -x "$RES/runtime/$r-$a/bin/$r" ] || [ -x "$RES/runtime/$r-$a/bin/${r}3" ]; then
                ok "$r-$a 运行时就位"
            else
                err "$r-$a 运行时缺失"
            fi
        done
    done
}

# ============================================================================
# 权限规范
# ============================================================================
normalize_permissions() {
    hdr "[权限规范]"
    find "$APP" -type f -perm -u+x 2>/dev/null | sed "s|$APP/||" > /tmp/dsh-exec-list.txt
    local n
    n=$(wc -l < /tmp/dsh-exec-list.txt)
    find "$APP" -type d -exec chmod 755 {} \; 2>/dev/null
    find "$APP" -type f -exec chmod 644 {} \; 2>/dev/null
    while IFS= read -r f; do
        [ -n "$f" ] && chmod 755 "$APP/$f" 2>/dev/null
    done < /tmp/dsh-exec-list.txt
    ok "目录 755 / 文件 644 / 恢复 $n 个可执行位"
}

# ============================================================================
# 打包
# ============================================================================
do_pack() {
    hdr "[打包]"
    local DIST
    DIST=$(dirname "$APP")
    local NAME
    NAME=$(basename "$APP")
    local VER=""
    [ -f "$RES/launcher/version.txt" ] && VER=$(cat "$RES/launcher/version.txt")
    local OUT="PaopaocatDSH-macOS-v${VER:-unknown}-universal"

    ( cd "$DIST" && tar -czf "$OUT.tar.gz" "$NAME" ) && ok "$OUT.tar.gz ($(du -h "$DIST/$OUT.tar.gz" | cut -f1))"

    # zip：保留符号链接与权限
    python3 - "$DIST" "$NAME" "$OUT.zip" << 'PYEOF'
import zipfile, os, stat, time, sys
dist, app, out = sys.argv[1], sys.argv[2], sys.argv[3]
files = links = 0
with zipfile.ZipFile(os.path.join(dist, out), 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as z:
    for root, dirs, names in os.walk(os.path.join(dist, app)):
        rel = os.path.relpath(root, dist)
        for d in dirs:
            p = os.path.join(root, d)
            st = os.lstat(p)
            zi = zipfile.ZipInfo(os.path.join(rel, d) + '/')
            zi.external_attr = ((stat.S_IFDIR | (st.st_mode & 0o7777)) << 16) | 0x10
            zi.date_time = time.localtime(st.st_mtime)[:6]
            z.writestr(zi, b'')
        for f in names:
            p = os.path.join(root, f)
            arc = os.path.join(rel, f)
            st = os.lstat(p)
            zi = zipfile.ZipInfo(arc)
            zi.date_time = time.localtime(st.st_mtime)[:6]
            if stat.S_ISLNK(st.st_mode):
                zi.external_attr = (stat.S_IFLNK | 0o777) << 16
                zi.compress_type = zipfile.ZIP_STORED
                z.writestr(zi, os.readlink(p).encode())
                links += 1
            else:
                zi.external_attr = (stat.S_IFREG | (st.st_mode & 0o7777)) << 16
                zi.compress_type = zipfile.ZIP_DEFLATED
                with open(p, 'rb') as fh:
                    z.writestr(zi, fh.read())
                files += 1
print(f"OK {files} files, {links} symlinks")
PYEOF
    [ -f "$DIST/$OUT.zip" ] && ok "$OUT.zip ($(du -h "$DIST/$OUT.zip" | cut -f1))"

    hdr "[校验和]"
    ( cd "$DIST" && md5sum "$OUT.tar.gz" "$OUT.zip" 2>/dev/null | sed 's/^/  /' )
}

# ============================================================================
# 主流程
# ============================================================================
main() {
    printf "${BLD}泡泡猫 DSH macOS 构建脚本${RST}\n"
    echo "  模式: $MODE"
    echo "  目标: $APP"
    echo "  架构: $(uname -m)"

    case "$MODE" in
        patch)
            patch_index_html
            patch_path
            check_native_packages || true
            health_check
            ;;
        build)
            patch_index_html
            patch_path
            check_native_packages || true
            normalize_permissions
            health_check
            do_pack
            ;;
        *) echo "未知模式: $MODE"; exit 1 ;;
    esac

    hdr "[完成]"
    echo "  下一步（必须真机验证）："
    echo "    1. 在 Mac 上安装并启动"
    echo "    2. 让 agent 执行: echo \$PATH && which python3"
    echo "       期望 which python3 指向 app 内的 runtime/python-*/bin/python3"
    echo "    3. 用 Safari 打开界面，确认无 Console 报错"
    echo "    4. 用一下 Oh Story 的导入功能，确认不弹「下载开发者工具」"
}

main
