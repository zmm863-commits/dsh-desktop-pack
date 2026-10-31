#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
payload 三重校验（对打包产物自身，而不是构建中间态）：

  1) 版本一致性审计 —— profiles/web/node_modules 里每个 @deepseek-ai/* 必须与
     随包 app 的版本一致。旧版残留会遮蔽新版并让运行期崩溃
     （实测：0.1.0-rc.8 的 dsh-host-webserver 被 0.1.7 的认证层调用，
      每个页面请求都抛异常 → 被兜底成空 body 的 HTTP 400 → 界面完全打不开）。
  2) 逐个插件 import —— 抓到 "Cannot find package ..." 这类解析缺口。
  3) HTTP 冒烟测试 —— 真启动一次，走完 token → cookie → 首页，断言拿到 200
     的真实 HTML；这一步能挡住"能启动但页面打不开"的故障。

用法：
  python3 verify-payload.py <payload根目录>        # 目录里应有 app/ 与 data-template/
  python3 verify-payload.py <payload根目录> --skip-http
"""
import json
import os
import shutil
import socket
import subprocess
import sys
import time
import urllib.request

LINUX_BINDING = 'node-addon-require-builtin-linux-x64-gnu'
SKIPPED = []   # 被跳过的检查（跳过 ≠ 通过）
BINDING_CACHE = '/tmp/nbt3/node_modules/' + LINUX_BINDING


def version_of(pkg_dir):
    try:
        return json.load(open(os.path.join(pkg_dir, 'package.json'), encoding='utf-8'))['version']
    except Exception:
        return None


def check_versions(root):
    app = os.path.join(root, 'app', 'node_modules', '@deepseek-ai')
    web = os.path.join(root, 'data-template', 'profiles', 'web', 'node_modules', '@deepseek-ai')
    if not os.path.isdir(web):
        print(f'  ⚠️ 找不到 {web}')
        return True
    ref = {}
    if os.path.isdir(app):
        for n in os.listdir(app):
            ref[n] = version_of(os.path.join(app, n))
    bad = []
    for n in sorted(os.listdir(web)):
        wv = version_of(os.path.join(web, n))
        av = ref.get(n)
        if wv and av and wv != av:
            bad.append((n, wv, av))
    if bad:
        print('  ❌ 版本错配（会被旧副本遮蔽）：')
        for n, wv, av in bad:
            print(f'     {n}: profiles/web={wv}  随包app={av}')
        return False
    print(f'  ✅ @deepseek-ai 版本全部一致（{len(os.listdir(web))} 个）')
    return True


def check_imports(root):
    profile = os.path.join(root, 'data-template', 'profiles', 'web')
    bundles = json.load(open(os.path.join(profile, 'package.json'), encoding='utf-8'))['dsh']['profile']['bundles']
    skip = {'@deepseek-ai/dsh-base', '@deepseek-ai/dsh-web-app'}
    bad = []
    for b in bundles:
        if b in skip:
            continue
        r = subprocess.run(['node', '--input-type=module', '-e', f"await import('{b}')"],
                           cwd=profile, capture_output=True, text=True, timeout=200)
        if r.returncode:
            line = next((l for l in (r.stderr or '').split('\n') if 'Cannot find' in l or 'Error' in l), '')
            print(f'  ❌ {b}  {line[:120]}')
            bad.append(b)
    if bad:
        return False
    print(f'  ✅ 插件 import 通过 {len(bundles)-len(skip)}/{len(bundles)-len(skip)}')
    return True



def check_mnemon_cli(root):
    """校验随包内置的 Mnemon CLI（长期记忆的存储后端）完整且平台正确。

    插件通过 MNEMON_CLI_PATH（由启动器注入）找到它；缺了会在记忆插件里显示
    「未找到 Mnemon CLI」，记忆空间的存储操作不可用。
    """
    cli = os.path.join(root, 'data-template', 'mnemon-cli', 'node_modules', '@mnemon-dev')
    launcher = os.path.join(cli, 'mnemon', 'bin', 'mnemon.js')
    if not os.path.isfile(launcher):
        print(f'  ❌ 缺少内置 Mnemon CLI 启动器：{launcher}')
        return False
    try:
        name = json.load(open(os.path.join(cli, 'mnemon', 'package.json'), encoding='utf-8'))['name']
    except Exception:
        name = None
    if name != '@mnemon-dev/mnemon':
        print(f'  ❌ CLI 启动器包名异常：{name}')
        return False

    # 判定 payload 的目标平台（看 app 里带的原生包）
    app_nm = os.path.join(root, 'app', 'node_modules')
    want = []
    if os.path.isdir(os.path.join(app_nm, 'node-addon-require-builtin-win32-x64-msvc')):
        want = ['mnemon-win32-x64']
    elif os.path.isdir(os.path.join(app_nm, 'node-addon-require-builtin-darwin-arm64')):
        want = ['mnemon-darwin-arm64', 'mnemon-darwin-x64']
    present = [d for d in os.listdir(cli) if d.startswith('mnemon-')]
    if want:
        missing = [w for w in want if w not in present]
        if missing:
            print(f'  ❌ 缺少目标平台的 CLI 二进制包：{missing}（现有 {present}）')
            return False
        print(f'  ✅ 内置 Mnemon CLI 完整（启动器 + {", ".join(want)}）')
    else:
        print(f'  ⚠️ 无法判定目标平台，已带 CLI 平台包：{present}')

    # 功能性检查：用插件自己的解析函数确认它能认出内置 CLI
    # （可指定 platform，因此不必真机即可验证 win32 / darwin 两种目标）
    platform = 'win32' if want[:1] == ['mnemon-win32-x64'] else ('darwin' if want else 'linux')
    profile = os.path.join(root, 'data-template', 'profiles', 'web')
    script = (
        "import { findMnemonCommand, mnemonNpmLauncher } from"
        " 'dsh-mnemon-source-memory-spaces/native-cli';"
        "const cli=process.argv[1], plat=process.argv[2];"
        "const found=findMnemonCommand({cliPath:cli},{platform:plat,env:{},home:'/tmp/x'});"
        "if(!found){console.error('NOT_FOUND');process.exit(1)}"
        "console.log(JSON.stringify({hit:found===cli,npm:Boolean(mnemonNpmLauncher(found))}))"
    )
    r = subprocess.run(['node', '--input-type=module', '-e', script, launcher, platform],
                       cwd=profile, capture_output=True, text=True, timeout=120)
    if r.returncode != 0 or '"hit":true' not in (r.stdout or ''):
        print(f'  ❌ 插件无法识别内置 CLI（platform={platform}）：{(r.stdout or r.stderr or "").strip()[:120]}')
        return False
    if '"npm":true' not in r.stdout:
        print(f'  ❌ 内置 CLI 未被识别为 npm 启动器（会当二进制直接 spawn）')
        return False
    print(f'  ✅ 插件可识别内置 CLI（platform={platform}，将用 node 执行）')
    return True


def check_launcher(root):
    """启动器必须带齐三项关键守卫（缺一项就会在真机上退化成已知故障）。"""
    cands = [os.path.join(root, 'launcher', 'start.ps1'),
             os.path.join(root, 'launcher', 'start.command')]
    path = next((c for c in cands if os.path.isfile(c)), None)
    if path is None:
        print('  ⚠️ 未找到启动器脚本，跳过检查')
        return True
    text = open(path, encoding='utf-8', errors='replace').read()
    required = {
        'settings.yaml.imported': 'Mnemon 接管后不再重建 settings.yaml 的守卫',
        'MNEMON_CLI_PATH': '内置 Mnemon CLI 的路径注入',
    }
    if path.endswith('.ps1'):
        required['needSync'] = '依赖提升层缺失时的补同步守卫'
    else:
        required['LAYER_OK'] = '依赖提升层标记守卫'
    missing = [f'{k}（{v}）' for k, v in required.items() if k not in text]
    if missing:
        print('  ❌ 启动器缺少关键守卫：')
        for m in missing:
            print('     -', m)
        return False
    print(f'  ✅ 启动器守卫齐全（{os.path.basename(path)}：{len(required)} 项）')
    return True


def check_git_shim(root):
    """mac 包必须带 git 包装器：避免 macOS 自带 /usr/bin/git 占位桩弹出下载框。

    结构：launcher/bin/git 可执行；启动器 PATH 前置该目录。
    功能：模拟已装命令行工具（假 xcode-select 指向含 git 的 devdir）时能正确转发。
    """
    launcher = os.path.join(root, 'launcher', 'start.command')
    if not os.path.isfile(launcher):
        return True          # 非 mac payload
    shim = os.path.join(root, 'launcher', 'bin', 'git')
    if not os.path.isfile(shim) or not os.access(shim, os.X_OK):
        print(f'  ❌ 缺少可执行的 git 包装器：{shim}')
        return False
    text = open(launcher, encoding='utf-8', errors='replace').read()
    if 'launcher/bin' not in text or 'export PATH' not in text:
        print('  ❌ 启动器没有把 launcher/bin 前置到 PATH')
        return False
    # 功能：模拟已装 CLT（假 xcode-select 指向含 git 的 devdir）→ 应转发给真 git
    tmp = '/tmp/.verify-gitshim'
    shutil.rmtree(tmp, ignore_errors=True)
    os.makedirs(os.path.join(tmp, 'dev', 'usr', 'bin'))
    os.makedirs(os.path.join(tmp, 'fakebin'))
    fake_git = os.path.join(tmp, 'dev', 'usr', 'bin', 'git')
    open(fake_git, 'w', encoding='utf-8').write('#!/bin/bash\necho FAKE-REAL-GIT "$@"\n')
    os.chmod(fake_git, 0o755)
    fake_xs = os.path.join(tmp, 'fakebin', 'xcode-select')
    open(fake_xs, 'w', encoding='utf-8').write(f'#!/bin/bash\necho "{tmp}/dev"\n')
    os.chmod(fake_xs, 0o755)
    r = subprocess.run([shim, '--version'], capture_output=True, text=True, timeout=60,
                       env=dict(os.environ, PATH=f'{tmp}/fakebin:/bin:/usr/bin'))
    if 'FAKE-REAL-GIT' not in (r.stdout or ''):
        print(f'  ❌ git 包装器未正确转发给真 git：rc={r.returncode} out={(r.stdout or "").strip()[:80]}')
        return False
    # 无 CLT 时的失败必须是「干净失败 + 可执行提示」，而不是触发系统下载框
    body = open(shim, encoding='utf-8', errors='replace').read()
    if 'xcode-select --install' not in body or '127' not in body:
        print('  ❌ git 包装器在无 git 时缺少提示或退出码处理')
        return False
    print('  ✅ git 包装器就位（结构 + PATH 前置 + 转发验证通过）')
    return True

def free_port():
    with socket.socket() as s:
        s.bind(('127.0.0.1', 0))
        return s.getsockname()[1]


def check_http(root):
    app = os.path.join(root, 'app')
    # darwin payload：故意**不**装 linux 预编译，让启动走
    # node-addon-require-builtin 的 JS 回退垫片（与旧版 macOS 上真实走的路径一致），
    # 从而验证「原生不可用时靠 --expose-internals 也能起来」。
    is_darwin = any(d.startswith('node-addon-require-builtin-darwin')
                    for d in os.listdir(os.path.join(app, 'node_modules')))
    if is_darwin:
        print('  ℹ️  darwin payload：不安装 linux 预编译，验证 JS 回退垫片路径')
    binding_dst = os.path.join(app, 'node_modules', LINUX_BINDING)
    if not is_darwin and not os.path.isdir(binding_dst):
        if os.path.isdir(BINDING_CACHE):
            shutil.copytree(BINDING_CACHE, binding_dst, symlinks=False)
        else:
            print(f'  ⚠️ 未验证：缺少 {LINUX_BINDING}，HTTP 冒烟测试被跳过'
                  f'（可执行：mkdir -p /tmp/nbt3 && cd /tmp/nbt3 && npm i --registry '
                  f'https://registry.npmjs.org {LINUX_BINDING}@0.1.6）')
            SKIPPED.append('http-smoke')
            return True

    # 临时 DSH_HOME 必须与 payload 同文件系统（跨文件系统的 cp -al 会静默失败，
    # 留下残缺的 home，导致插件误报 "failed to import"）。放在 payload 同级目录。
    root_abs = os.path.abspath(root)
    home = os.path.join(os.path.dirname(root_abs), '.verify-payload-home')
    shutil.rmtree(home, ignore_errors=True)
    os.makedirs(home)
    src = os.path.join(root, 'data-template')
    r = subprocess.run(f'cp -al "{src}/." "{home}/"', shell=True,
                       capture_output=True, text=True)
    if r.returncode != 0:                      # EXDEV 等：回退为真实拷贝
        shutil.rmtree(home, ignore_errors=True)
        shutil.copytree(src, home, symlinks=True)

    # ⚠️ 端口必须"先删再写"：home 里的文件与 payload 共享 inode（硬链接），
    # 就地改写会连源 payload 一起改掉（曾经把 payload 的 3080 改成随机端口）。
    patch = os.path.join(home, 'profiles', 'web', 'cordis.patch.yml')
    port = free_port()
    if os.path.isfile(patch):
        text = open(patch, encoding='utf-8').read()
        patched = __import__('re').sub(r'port:\s*\d+', f'port: {port}', text)
        os.remove(patch)
        open(patch, 'w', encoding='utf-8').write(patched)

    env = dict(os.environ, DSH_HOME=home)
    log = open('/tmp/verify-payload-http.log', 'w')
    proc = subprocess.Popen(['node', '--expose-internals',
                             os.path.join(app, 'lib', 'bin.js'), 'web',
                             '--no-open', '--port', str(port)],
                            cwd=home, env=env, stdout=log, stderr=subprocess.STDOUT)
    try:
        token = None
        for _ in range(60):
            time.sleep(2)
            try:
                text = open('/tmp/verify-payload-http.log', encoding='utf-8', errors='replace').read()
            except Exception:
                text = ''
            for line in text.split('\n'):
                if 'token=' in line:
                    token = line.split('token=')[1].strip()
                    break
            if token:
                break
            if 'startup failed' in text:
                print('  ❌ 启动失败，日志：')
                print('     ' + '\n     '.join(text.strip().split('\n')[:8]))
                return False
        if not token:
            print('  ❌ 60s 内没拿到 token（服务未起来）')
            return False

        base = f'http://127.0.0.1:{port}'
        # 1) token → 303 + Set-Cookie
        req = urllib.request.Request(f'{base}/?token={token}')
        opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor())
        try:
            r = opener.open(req, timeout=20)
            code = r.status
            body = r.read()
        except urllib.error.HTTPError as e:
            code, body = e.code, e.read()
        if code not in (200, 303):
            print(f'  ❌ 带 token 请求返回 {code}（应 200/303）')
            return False
        # 2) 跟随到首页
        try:
            r = opener.open(f'{base}/', timeout=20)
            code, body = r.status, r.read()
        except urllib.error.HTTPError as e:
            code, body = e.code, e.read()
        if code != 200 or len(body) < 5000 or b'<!doctype html' not in body.lower():
            print(f'  ❌ 首页异常：状态 {code}，body {len(body)} 字节'
                  f'（期望 200 且为真实 HTML）')
            return False
        print(f'  ✅ HTTP 冒烟通过：首页 200 · {len(body):,} 字节 HTML')
        return True
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=10)
        except Exception:
            proc.kill()
        log.close()
        shutil.rmtree(home, ignore_errors=True)


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        raise SystemExit(2)
    root = sys.argv[1]
    skip_http = '--skip-http' in sys.argv
    print(f'▶ 校验 payload：{root}')
    # 记录端口，校验结束后断言未被改动（防止校验工具自身污染 payload）
    patch = os.path.join(root, 'data-template', 'profiles', 'web', 'cordis.patch.yml')
    before = open(patch, encoding='utf-8').read() if os.path.isfile(patch) else None
    ok = True
    ok &= check_versions(root)
    ok &= check_imports(root)
    ok &= check_mnemon_cli(root)
    ok &= check_launcher(root)
    ok &= check_git_shim(root)
    if not skip_http:
        ok &= check_http(root)
    if before is not None and os.path.isfile(patch):
        after = open(patch, encoding='utf-8').read()
        if after != before:
            print('  ❌ 校验过程改动了 payload 的 cordis.patch.yml（工具缺陷）')
            ok = False
        else:
            print('  ✅ payload 未被校验过程改动')
    if ok and SKIPPED:
        print(f'结论：⚠️ 已完成检查全部通过，但有 {len(SKIPPED)} 项未执行：{SKIPPED}')
    else:
        print('结论：' + ('✅ 全部通过' if ok else '❌ 存在问题'))
    raise SystemExit(0 if ok else 1)


if __name__ == '__main__':
    main()
