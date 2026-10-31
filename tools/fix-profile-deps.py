#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
修复打包后 profile 的依赖解析缺口（系统级）。

背景：dev 环境下 /dsh/profiles/node_modules 是一层指向全局 DSH 依赖的链接层
（164 个链接 / 240 个 @deepseek-ai 包），插件嵌套包的 peer 依赖靠它解析。
打包只带了 profiles/web，缺了这一层 → 插件 import 时报
"Cannot find package '@deepseek-ai/xxx'"（真机表现为 "failed to import"）。

做法：
  1) 移除 dsh-agnes-studio 下嵌套的 @deepseek-ai 旧副本（来自旧版全局安装，
     版本与随包 app 不一致，会导致 cosmokit/cordis 版本冲突）；备份后可回滚。
  2) 迭代：逐个 import profile 里声明的每个插件，缺什么就从随包 app/node_modules
     复制什么到 data-template/profiles/node_modules/（提升层）。
     全部取自随包 app，保证版本自洽。直到所有插件 import 通过。

用法：python3 fix-profile-deps.py <payload根目录>
      win → <repo>/win
      mac → .../PaopaocatDSH.app/Contents/Resources
"""
import json, os, re, shutil, subprocess, sys

root = sys.argv[1]
APP = os.path.join(root, 'app', 'node_modules')
PROFILE = os.path.join(root, 'data-template', 'profiles', 'web')
LAYER = os.path.join(root, 'data-template', 'profiles', 'node_modules')
SKIP = {'@deepseek-ai/dsh-base', '@deepseek-ai/dsh-web-app'}

# 1) 移除并备份【所有插件】下的嵌套 @deepseek-ai 旧副本
#    这些副本来自旧的全局安装，版本比随包 app 旧，会在解析时遮蔽提升层，
#    导致插件 import 失败（实测：cosmokit 1.8.3 缺 createVolatile 导出）。
nm = os.path.join(PROFILE, 'node_modules')
for plug in sorted(os.listdir(nm)):
    if plug.startswith('@'):
        continue
    nested = os.path.join(nm, plug, 'node_modules', '@deepseek-ai')
    if not os.path.isdir(nested):
        continue
    bak = os.path.join(root, 'backups', f'nested-at-deepseek-ai-{plug}')
    os.makedirs(bak, exist_ok=True)
    for name in os.listdir(nested):
        s, t = os.path.join(nested, name), os.path.join(bak, name)
        if not os.path.exists(t):
            shutil.move(s, t)
    shutil.rmtree(nested, ignore_errors=True)
    print(f'已移除 {plug}/node_modules/@deepseek-ai → 备份于 {bak}')

os.makedirs(os.path.join(LAYER, '@deepseek-ai'), exist_ok=True)

bundles = [b for b in json.load(open(os.path.join(PROFILE, 'package.json')))['dsh']['profile']['bundles']
           if b not in SKIP]

def try_import(pkg):
    r = subprocess.run(['node', '--input-type=module', '-e', f"await import('{pkg}')"],
                       cwd=PROFILE, capture_output=True, text=True, timeout=300)
    return r.returncode, (r.stderr or '') + (r.stdout or '')

copied, stuck = [], []
for round_no in range(60):
    missing = {}
    for b in bundles:
        rc, out = try_import(b)
        if rc == 0:
            continue
        m = re.search(r"Cannot find package '([^']+)'", out)
        if m:
            missing[b] = m.group(1)
        else:
            stuck.append((b, out.strip().split('\n')[0][:120]))
    if not missing:
        print(f'✅ 第 {round_no} 轮：全部插件 import 通过')
        break
    progressed = False
    for b, pkg in missing.items():
        src, dst = os.path.join(APP, pkg), os.path.join(LAYER, pkg)
        if os.path.isdir(src) and not os.path.exists(dst):
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            shutil.copytree(src, dst, symlinks=False)
            copied.append(pkg)
            print(f'  + {pkg}   (被 {b} 需要)')
            progressed = True
        elif os.path.exists(dst):
            print(f'  ⚠️ {pkg} 已在层内，{b} 仍报缺失')
        else:
            print(f'  ❌ {pkg} 被 {b} 需要，但 app 内没有')
    if not progressed:
        print('⛔ 无法继续补齐，剩余缺失：', missing)
        break

print(f'\n共补入 {len(copied)} 个包：{copied}')
if stuck:
    print('非缺包类失败：')
    for b, msg in stuck:
        print('  -', b, '::', msg)
