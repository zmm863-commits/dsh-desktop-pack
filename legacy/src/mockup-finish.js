// 合成安装完成页效果图（含免责声明位）
'use strict';
const sharp = require('/usr/local/lib/node_modules/@deepseek-ai/dsh/node_modules/sharp');
const fs = require('fs');

const W = 500, H = 379; // NSIS MUI 完成页标准尺寸

function text(str, x, y, size, fill, weight) {
  return `<text x="${x}" y="${y}" font-size="${size}" fill="${fill}" font-family="Noto Sans CJK SC" font-weight="${weight || 'normal'}">${str}</text>`;
}

const bg = `<rect width="${W}" height="${H}" fill="#141c38"/>
<rect x="0" y="0" width="164" height="${H}" fill="#0d1326"/>
<rect x="1.5" y="1.5" width="161" height="${H-3}" fill="none" stroke="#c5a468" stroke-width="2"/>
<circle cx="55" cy="32" r="8" fill="#e8c97a"/><circle cx="40" cy="18" r="4.5" fill="#e8c97a"/>
<circle cx="55" cy="13" r="5" fill="#e8c97a"/><circle cx="70" cy="18" r="4.5" fill="#e8c97a"/>
<text x="82" y="58" font-size="14" fill="#e8c97a" text-anchor="middle" font-family="Noto Sans CJK SC" font-weight="bold">泡泡猫 DSH</text>
<text x="82" y="76" font-size="9" fill="#9fb0d8" text-anchor="middle" font-family="Noto Sans CJK SC">桌面版 · 开箱即用</text>
<line x1="14" y1="90" x2="150" y2="90" stroke="#c5a468" stroke-width="1"/>
<text x="14" y="112" font-size="9" fill="#cfd6ea" font-family="Noto Sans CJK SC">🎲 骰子大作战</text>
<text x="14" y="128" font-size="9" fill="#cfd6ea" font-family="Noto Sans CJK SC">🧠 长期记忆库</text>
<text x="14" y="144" font-size="9" fill="#cfd6ea" font-family="Noto Sans CJK SC">🤖 领域专家团</text>
<text x="14" y="160" font-size="9" fill="#cfd6ea" font-family="Noto Sans CJK SC">⏰ 定时自动化</text>
<text x="14" y="176" font-size="9" fill="#cfd6ea" font-family="Noto Sans CJK SC">💬 IM 接入</text>
<text x="14" y="192" font-size="9" fill="#cfd6ea" font-family="Noto Sans CJK SC">👁 视觉识图</text>
<text x="14" y="208" font-size="9" fill="#cfd6ea" font-family="Noto Sans CJK SC">…共 16 个插件</text>`;

const main = `<rect x="164" y="0" width="336" height="${H}" fill="#141c38"/>
<text x="332" y="60" font-size="18" fill="#e8c97a" text-anchor="middle" font-family="Noto Sans CJK SC" font-weight="bold">安装完成</text>
<rect x="190" y="90" width="284" height="2" fill="#c5a468" opacity="0.5"/>
<text x="332" y="130" font-size="11" fill="#cfd6ea" text-anchor="middle" font-family="Noto Sans CJK SC">泡泡猫 DSH 桌面版 已成功安装到您的计算机。</text>
<text x="332" y="152" font-size="11" fill="#cfd6ea" text-anchor="middle" font-family="Noto Sans CKB SC">勾选下方选项将立即启动。</text>
<rect x="200" y="185" width="14" height="14" fill="none" stroke="#c5a468" stroke-width="1.5"/>
<text x="222" y="197" font-size="11" fill="#ffe9b0" font-family="Noto Sans CJK SC">安装完成后立即启动泡泡猫 DSH</text>
<rect x="190" y="220" width="284" height="1" fill="#c5a468" opacity="0.4"/>
<text x="332" y="255" font-size="9" fill="#8892b0" text-anchor="middle" font-family="Noto Sans CJK SC">本软件插件均收集整合自开源社区，仅供学习交流使用</text>
<text x="332" y="272" font-size="9" fill="#8892b0" text-anchor="middle" font-family="Noto Sans CJK SC">任何使用问题请联系：zmm168@163.com</text>
<text x="332" y="298" font-size="8" fill="#5a6480" text-anchor="middle" font-family="Noto Sans CJK SC">© 2026 泡泡猫 DSH · 保留所有权利</text>`;

(async () => {
  const svg = `<svg width="${W}" height="${H}" xmlns="http://www.w3.org/2000/svg">${bg}${main}</svg>`;
  const buf = await sharp(Buffer.from(svg)).png().toBuffer();
  fs.writeFileSync('/root/软件/dsh-desktop-pack/assets/mockup-finish.png', buf);
  console.log('ok', buf.length, 'bytes');
})().catch(e => { console.error(e); process.exit(1); });
