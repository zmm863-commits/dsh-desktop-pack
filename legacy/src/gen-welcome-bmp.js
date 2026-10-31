// 手工构造标准 24bit BMP（BITMAPINFOHEADER，底上行 BGR），规避 ImageMagick 格式差异
'use strict';
const fs = require('fs');
const sharp = require('/usr/local/lib/node_modules/@deepseek-ai/dsh/node_modules/sharp');
const W = 164, H = 302;

function bmp24(rgba) {
  const rowSize = Math.ceil((W * 3) / 4) * 4;
  const pixSize = rowSize * H;
  const buf = Buffer.alloc(54 + pixSize);
  buf.write('BM'); buf.writeUInt32LE(buf.length, 2); buf.writeUInt32LE(54, 10);
  buf.writeUInt32LE(40, 14); buf.writeInt32LE(W, 18); buf.writeInt32LE(H, 22);
  buf.writeUInt16LE(1, 26); buf.writeUInt16LE(24, 28); buf.writeUInt32LE(pixSize, 34);
  for (let y = 0; y < H; y++) {
    const srcRow = (H - 1 - y) * W * 4;
    let o = 54 + y * rowSize;
    for (let x = 0; x < W; x++) {
      const s = srcRow + x * 4;
      buf[o++] = rgba[s + 2]; buf[o++] = rgba[s + 1]; buf[o++] = rgba[s];
    }
  }
  return buf;
}

(async () => {
  // 复用 gen-welcome 的合成逻辑
  const shot = await sharp('/root/pprev/shot-30.png')
    .extract({ left: 200, top: 200, width: 1100, height: 620 })
    .resize(148, 83).png().toBuffer();
  const plugins = ['骰子大作战', '插件市场', '长期记忆库', '定时自动化', '领域专家团',
                   'IM 接入', '视觉识图', '技能管理器'].map((t, i) =>
    `<text x="14" y="${132 + i * 16}" font-size="11" fill="#cfd6ea" font-family="Noto Sans CJK SC">· ${t}</text>`).join('');
  const svg = `<svg width="164" height="302">
    <rect width="164" height="302" fill="#141c38"/>
    <rect x="1" y="1" width="162" height="300" fill="none" stroke="#c5a468" stroke-width="3"/>
    <circle cx="62" cy="34" r="9" fill="#e8c97a"/><circle cx="46" cy="20" r="5" fill="#e8c97a"/>
    <circle cx="62" cy="15" r="5.5" fill="#e8c97a"/><circle cx="78" cy="20" r="5" fill="#e8c97a"/>
    <circle cx="118" cy="26" r="7" fill="#ffffff" opacity="0.85"/>
    <text x="82" y="66" font-size="15" fill="#e8c97a" text-anchor="middle" font-family="Noto Sans CJK SC" font-weight="bold">泡泡猫 DSH</text>
    <text x="82" y="84" font-size="10" fill="#9fb0d8" text-anchor="middle" font-family="Noto Sans CJK SC">桌面版 · 开箱即用</text>
    <line x1="12" y1="96" x2="152" y2="96" stroke="#c5a468" stroke-width="1"/>
    ${plugins}
    <text x="14" y="264" font-size="10" fill="#8892b0" font-family="Noto Sans CJK SC">…共 16 个插件全部预装</text>
  </svg>`;
  const rgba = await sharp({ create: { width: W, height: H, channels: 4, background: '#141c38' } })
    .composite([{ input: Buffer.from(svg), left: 0, top: 0 }, { input: shot, left: 8, top: 206 }])
    .ensureAlpha().raw().toBuffer();
  fs.writeFileSync('/root/软件/dsh-desktop-pack/assets/welcome.bmp', bmp24(rgba));
  console.log('ok bytes:', fs.statSync('/root/软件/dsh-desktop-pack/assets/welcome.bmp').size);
})().catch(e => { console.error(e); process.exit(1); });
