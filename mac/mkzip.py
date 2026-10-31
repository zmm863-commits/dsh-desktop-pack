#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
泡泡猫 DSH 桌面版 · macOS zip 打包脚本（沿用 2.3.2 验证过的写法）

两个坑（见技术文档 7.3）：
  1. ZipFile.write() 会把符号链接存成实体副本 → 体积膨胀（python3 从 10 字节变 17MB）。
     必须手工构造 ZipInfo：S_IFLNK 标记 + ZIP_STORED（不压缩）+ 内容=链接目标。
  2. 目录要写显式条目，否则空目录丢失。

用法：
  python3 mkzip.py <PaopaocatDSH.app 路径> <输出 zip 路径>
"""
import os
import stat
import sys
import time
import zipfile

APP_DIR_NAME = 'PaopaocatDSH.app'


def build(app, out):
    parent = os.path.dirname(app)
    files = syms = 0
    with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED, compresslevel=6) as z:
        # 顶层 .app 目录本体
        st = os.lstat(app)
        zi = zipfile.ZipInfo(APP_DIR_NAME + '/')
        zi.external_attr = ((stat.S_IFDIR | (st.st_mode & 0o7777)) << 16) | 0x10
        zi.date_time = time.localtime(st.st_mtime)[:6]
        z.writestr(zi, b'')

        for root, dirs, names in os.walk(app, followlinks=False):
            dirs.sort()
            names.sort()
            rel_root = os.path.relpath(root, parent)

            for d in dirs:
                p = os.path.join(root, d)
                st = os.lstat(p)
                rel = os.path.join(rel_root, d)
                if stat.S_ISLNK(st.st_mode):
                    zi = zipfile.ZipInfo(rel)
                    zi.external_attr = (stat.S_IFLNK | 0o777) << 16
                    zi.compress_type = zipfile.ZIP_STORED
                    z.writestr(zi, os.readlink(p).encode())
                    syms += 1
                else:
                    zi = zipfile.ZipInfo(rel + '/')
                    zi.external_attr = ((stat.S_IFDIR | (st.st_mode & 0o7777)) << 16) | 0x10
                    zi.date_time = time.localtime(st.st_mtime)[:6]
                    z.writestr(zi, b'')

            for f in names:
                p = os.path.join(root, f)
                st = os.lstat(p)
                rel = os.path.join(rel_root, f)
                if stat.S_ISLNK(st.st_mode):
                    zi = zipfile.ZipInfo(rel)
                    zi.external_attr = (stat.S_IFLNK | 0o777) << 16
                    zi.compress_type = zipfile.ZIP_STORED
                    z.writestr(zi, os.readlink(p).encode())
                    syms += 1
                else:
                    zi = zipfile.ZipInfo(rel)
                    zi.external_attr = (stat.S_IFREG | (st.st_mode & 0o7777)) << 16
                    zi.compress_type = zipfile.ZIP_DEFLATED
                    with open(p, 'rb') as fh:
                        z.writestr(zi, fh.read())
                    files += 1

    size_mb = os.path.getsize(out) / 1048576
    print(f'✅ {out}')
    print(f'   文件 {files} · 符号链接 {syms} · {size_mb:.1f} MB')


def verify(zip_path):
    """体检：绝对路径符号链接（死链）必须为 0。"""
    bad = []
    with zipfile.ZipFile(zip_path) as z:
        for i in z.infolist():
            if stat.S_ISLNK((i.external_attr >> 16) & 0xFFFF):
                target = z.read(i).decode('utf-8', 'replace')
                if target.startswith('/'):
                    bad.append((i.filename, target))
    if bad:
        print(f'❌ 发现 {len(bad)} 个指向绝对路径的符号链接（在用户机器上必然是死链）：')
        for f, t in bad:
            print('   -', f, '->', t)
        return 1
    print('✅ 无绝对路径符号链接（无死链）')
    return 0


if __name__ == '__main__':
    if len(sys.argv) < 3:
        print(__doc__)
        raise SystemExit(2)
    app_path, out_path = sys.argv[1], sys.argv[2]
    if not os.path.isdir(app_path):
        print('❌ 不是目录:', app_path)
        raise SystemExit(2)
    if os.path.exists(out_path):
        os.remove(out_path)
    build(app_path, out_path)
    raise SystemExit(verify(out_path))
