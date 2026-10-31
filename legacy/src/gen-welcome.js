// 安装向导欢迎页侧边图 164×302：品牌+插件清单+迷你界面截图
'use strict';
const sharp = require('/usr/local/lib/node_modules/@deepseek-ai/dsh/node_modules/sharp');
const fs = require('fs');
const { execSync } = require('child_process');

(async () => {
  // 迷你截图：从 30vh 实拍取中景缩到 148×83
  const shot = await sharp('/root/pprev/shot-30.png')
    .extract({ left: 200, top: 200, width: 1100, height: 620 })
    .resize(148, 83).png().toBuffer();

  const plugins = ['骰子大作战', '插件市场', '长期记忆库', '定时自动化', '领域专家团',
                   'IM 接入', '视觉识图', '技能管理器'].map((t, i) =>
    `<text x="14" y="${132 + i * 16}" font-size="11" fill="#cfd6ea" font-family="Noto Sans CJK SC">· ${t}</text>`).join('');

  const svg = `<svg width="164" height="302">
    <rect width="164" height="302" fill="#141c38"/>
    <rect x="1.5" y="1.5" width="161" height="299" fill="none" stroke="#c5a468" stroke-width="3"/>
    <circle cx="62" cy="34" r="9" fill="#e8c97a"/><circle cx="46" cy="20" r="5" fill="#e8c97a"/>
    <circle cx="62" cy="15" r="5.5" fill="#e8c97a"/><circle cx="78" cy="20" r="5" fill="#e8c97a"/>
    <circle cx="118" cy="26" r="7" fill="#ffffff" opacity="0.85"/>
    <text x="82" y="66" font-size="15" fill="#e8c97a" text-anchor="middle" font-family="Noto Sans CJK SC" font-weight="bold">泡泡猫 DSH</text>
    <text x="82" y="84" font-size="10" fill="#9fb0d8" text-anchor="middle" font-family="Noto Sans CJK SC">桌面版 · 开箱即用</text>
    <line x1="12" y1="96" x2="152" y2="96" stroke="#c5a468" stroke-width="1"/>
    ${plugins}
    <text x="14" y="264" font-size="10" fill="#8892b0" font-family="Noto Sans CJK SC">…共 16 个插件全部预装</text>
    <rect x="8" y="274" width="148" height="24" fill="#0d1326"/>
  </svg>`;

  const base = await sharp({ create: { width: 164, height: 302, channels: 3, background: '#141c38' } })
    .composite([{ input: Buffer.from(svg), left: 0, top: 0 },
                { input: shot, left: 8, top: 206 }])
    .png().toBuffer();
  fs.writeFileSync('/root/dsh-desktop-pack-tmp.png', base);
  execSync('convert /root/dsh-desktop-pack-tmp.png BMP3:/root/软件/dsh-desktop-pack/assets/welcome.bmp');
  fs.unlinkSync('/root/dsh-desktop-pack-tmp.png');
  console.log('welcome.bmp:', fs.statSync('/root/软件/dsh-desktop-pack/assets/welcome.bmp').size, 'bytes');
})().catch(e => { console.error(e); process.exit(1); });
