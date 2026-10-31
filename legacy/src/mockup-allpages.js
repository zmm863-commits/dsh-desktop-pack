// 泡泡猫 DSH v1.4.0 全程深色安装流程总览图
'use strict';
const sharp = require('/usr/local/lib/node_modules/@deepseek-ai/dsh/node_modules/sharp');
const fs = require('fs');

const PW = 500, PH = 379, NAV = 164, GAP = 18;
const totalW = PW * 5 + GAP * 4;

function nav() {
  return `<rect x="0" y="0" width="${NAV}" height="${PH}" fill="#0d1326"/>
<rect x="1.5" y="1.5" width="${NAV-3}" height="${PH-3}" fill="none" stroke="#c5a468" stroke-width="2"/>
<circle cx="55" cy="30" r="7" fill="#e8c97a"/><circle cx="41" cy="17" r="4" fill="#e8c97a"/>
<circle cx="55" cy="12" r="4.5" fill="#e8c97a"/><circle cx="69" cy="17" r="4" fill="#e8c97a"/>
<text x="82" y="52" font-size="12" fill="#e8c97a" text-anchor="middle" font-family="Noto Sans CJK SC" font-weight="bold">泡泡猫 DSH</text>
<text x="82" y="68" font-size="8" fill="#9fb0d8" text-anchor="middle" font-family="Noto Sans CJK SC">桌面版 · v1.4.0</text>
<line x1="12" y1="82" x2="${NAV-12}" y2="82" stroke="#c5a468" stroke-width="1"/>
<text x="14" y="102" font-size="8" fill="#cfd6ea" font-family="Noto Sans CJK SC">🎲 骰子大作战</text>
<text x="14" y="116" font-size="8" fill="#cfd6ea" font-family="Noto Sans CJK SC">📎 文件上传</text>
<text x="14" y="130" font-size="8" fill="#cfd6ea" font-family="Noto Sans CJK SC">🧠 长期记忆库</text>
<text x="14" y="144" font-size="8" fill="#cfd6ea" font-family="Noto Sans CJK SC">🤖 领域专家团</text>
<text x="14" y="158" font-size="8" fill="#cfd6ea" font-family="Noto Sans CJK SC">⏰ 定时自动化</text>
<text x="14" y="172" font-size="8" fill="#cfd6ea" font-family="Noto Sans CJK SC">💬 IM 接入</text>
<text x="14" y="186" font-size="8" fill="#cfd6ea" font-family="Noto Sans CJK SC">👁 视觉识图</text>
<text x="14" y="200" font-size="8" fill="#cfd6ea" font-family="Noto Sans CJK SC">…共 16 个插件</text>
<text x="82" y="${PH-16}" font-size="7" fill="#5a6480" text-anchor="middle" font-family="Noto Sans CJK SC">© 2026 泡泡猫</text>`;
}

function page(num, title, lines, extra) {
  let t = `<rect x="0" y="0" width="${PW-NAV}" height="${PH}" fill="#141c38"/>
<text x="${(PW-NAV)/2}" y="40" font-size="15" fill="#e8c97a" text-anchor="middle" font-family="Noto Sans CJK SC" font-weight="bold">${title}</text>
<rect x="20" y="52" width="${PW-NAV-40}" height="1.5" fill="#c5a468" opacity="0.5"/>`;
  let y = 78;
  for (const l of lines) {
    t += `<text x="26" y="${y}" font-size="10" fill="#cfd6ea" font-family="Noto Sans CJK SC">${l}</text>`;
    y += 20;
  }
  if (extra) t += extra;
  return `<g transform="translate(${num*(PW+GAP)},0)">${nav()}<g transform="translate(${NAV},0)">${t}</g></g>`;
}

function pageDir(num) {
  const extra = `<rect x="20" y="140" width="${PW-NAV-40}" height="18" fill="#0d1326" stroke="#c5a468" stroke-width="1"/>
<text x="26" y="153" font-size="9" fill="#9fb0d8" font-family="Noto Sans CJK SC">$LOCALAPPDATA\\Programs\\PaopaocatDSH</text>
<text x="26" y="180" font-size="9" fill="#8892b0" font-family="Noto Sans CJK SC">安装需要约 113MB 磁盘空间</text>`;
  return page(num, '选择安装位置', [
    '指定泡泡猫 DSH 的安装目录：',
    '默认位置建议保持不变。',
    '点击下一步继续。'
  ], extra);
}

function pageInst(num) {
  const extra = `<rect x="20" y="130" width="${PW-NAV-40}" height="14" fill="#0d1326"/>
<rect x="20" y="130" width="${(PW-NAV-40)*0.6}" height="14" fill="#c5a468"/>
<text x="${(PW-NAV)/2}" y="160" font-size="9" fill="#9fb0d8" text-anchor="middle" font-family="Noto Sans CJK SC">正在安装… 60%</text>`;
  return page(num, '正在安装', [
    '正在复制文件，请稍候。',
    '首次安装可能需要 1-3 分钟。'
  ], extra);
}

function pageFinish(num) {
  const extra = `<rect x="20" y="120" width="12" height="12" fill="#c5a468"/>
<text x="38" y="130" font-size="10" fill="#ffe9b0" font-family="Noto Sans CJK SC">安装完成后立即启动泡泡猫 DSH</text>
<rect x="20" y="148" width="${PW-NAV-40}" height="1" fill="#c5a468" opacity="0.4"/>
<rect x="20" y="160" width="120" height="22" rx="4" fill="#c5a468"/>
<text x="80" y="175" font-size="9" fill="#141c38" text-anchor="middle" font-family="Noto Sans CJK SC" font-weight="bold">☁️ 阿里云推荐配置</text>
<rect x="150" y="160" width="120" height="22" rx="4" fill="none" stroke="#c5a468" stroke-width="1.5"/>
<text x="210" y="175" font-size="9" fill="#c5a468" text-anchor="middle" font-family="Noto Sans CJK SC">❤ 爱发电支持</text>
<rect x="20" y="192" width="${PW-NAV-40}" height="1" fill="#c5a468" opacity="0.3"/>
<text x="26" y="210" font-size="7.5" fill="#8892b0" font-family="Noto Sans CJK SC">本软件插件除骰子大作战和文件上传功能为泡泡猫制作，</text>
<text x="26" y="224" font-size="7.5" fill="#8892b0" font-family="Noto Sans CJK SC">其余插件均收集整合自开源社区，仅供学习交流使用。</text>
<text x="26" y="238" font-size="7.5" fill="#8892b0" font-family="Noto Sans CJK SC">任何使用问题请联系：zmm168@163.com</text>`;
  return page(num, '安装完成', [
    '泡泡猫 DSH 已成功安装到您的计算机。',
    '您可以立即开始使用。'
  ], extra);
}

(async () => {
  const p1 = page(0, '欢迎', [
    '欢迎使用泡泡猫 DSH 桌面版。',
    '本软件将安装泡泡猫 DSH 到您的计算机。',
    '内置 16 个插件，开箱即用。',
    '安装过程不会修改您的系统设置。',
    '点击下一步继续。'
  ], '');
  const p2 = page(1, '插件清单', [
    '内置以下插件，全部预装完毕：',
    '🎲 骰子大作战  📎 文件上传',
    '🧠 长期记忆库  🤖 领域专家团',
    '⏰ 定时自动化  💬 IM 接入',
    '🛒 插件市场    👁 视觉识图',
    '🎨 皮肤        ⚙️ 核心框架',
    '默认暗色主题；立绘为原版尺寸。'
  ], '');
  const p3 = pageDir(2);
  const p4 = pageInst(3);
  const p5 = pageFinish(4);

  const svg = `<svg width="${totalW}" height="${PH+40}" xmlns="http://www.w3.org/2000/svg">
<rect width="100%" height="100%" fill="#0a0e1a"/>
<text x="${totalW/2}" y="22" font-size="11" fill="#c5a468" text-anchor="middle" font-family="Noto Sans CJK SC" font-weight="bold">泡泡猫 DSH v1.4.0 · 安装向导全程预览</text>
${p1}${p2}${p3}${p4}${p5}
</svg>`;
  const buf = await sharp(Buffer.from(svg)).png().toBuffer();
  fs.writeFileSync('/root/软件/dsh-desktop-pack/assets/mockup-allpages.png', buf);
  console.log('ok', buf.length, 'bytes');
})().catch(e => { console.error(e); process.exit(1); });
