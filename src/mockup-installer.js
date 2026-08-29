// 安装向导全程深色风格效果图：欢迎页 + 完成页（含广告位）
'use strict';
const sharp = require('/usr/local/lib/node_modules/@deepseek-ai/dsh/node_modules/sharp');
const fs = require('fs');

const W = 500, H = 379;
const NAV_W = 164;

function nav(side) {
  return `<rect x="0" y="0" width="${NAV_W}" height="${H}" fill="#0d1326"/>
<rect x="1.5" y="1.5" width="${NAV_W-3}" height="${H-3}" fill="none" stroke="#c5a468" stroke-width="2"/>
<circle cx="55" cy="32" r="8" fill="#e8c97a"/><circle cx="40" cy="18" r="4.5" fill="#e8c97a"/>
<circle cx="55" cy="13" r="5" fill="#e8c97a"/><circle cx="70" cy="18" r="4.5" fill="#e8c97a"/>
<text x="82" y="58" font-size="14" fill="#e8c97a" text-anchor="middle" font-family="Noto Sans CJK SC" font-weight="bold">泡泡猫 DSH</text>
<text x="82" y="76" font-size="9" fill="#9fb0d8" text-anchor="middle" font-family="Noto Sans CJK SC">桌面版 · 开箱即用</text>
<line x1="14" y1="90" x2="${NAV_W-14}" y2="90" stroke="#c5a468" stroke-width="1"/>
<text x="14" y="112" font-size="9" fill="#cfd6ea" font-family="Noto Sans CJK SC">🎲 骰子大作战</text>
<text x="14" y="128" font-size="9" fill="#cfd6ea" font-family="Noto Sans CJK SC">📎 文件上传</text>
<text x="14" y="144" font-size="9" fill="#cfd6ea" font-family="Noto Sans CJK SC">🧠 长期记忆库</text>
<text x="14" y="160" font-size="9" fill="#cfd6ea" font-family="Noto Sans CJK SC">🤖 领域专家团</text>
<text x="14" y="176" font-size="9" fill="#cfd6ea" font-family="Noto Sans CJK SC">⏰ 定时自动化</text>
<text x="14" y="192" font-size="9" fill="#cfd6ea" font-family="Noto Sans CJK SC">💬 IM 接入</text>
<text x="14" y="208" font-size="9" fill="#cfd6ea" font-family="Noto Sans CJK SC">👁 视觉识图</text>
<text x="14" y="224" font-size="9" fill="#cfd6ea" font-family="Noto Sans CJK SC">🛒 插件市场</text>
<text x="14" y="240" font-size="9" fill="#cfd6ea" font-family="Noto Sans CJK SC">…共 16 个插件</text>
<text x="82" y="${H-20}" font-size="8" fill="#5a6480" text-anchor="middle" font-family="Noto Sans CJK SC">© 2026 泡泡猫</text>`;
}

const welcome = `<rect x="${NAV_W}" y="0" width="${W-NAV_W}" height="${H}" fill="#141c38"/>
<text x="${NAV_W+(W-NAV_W)/2}" y="60" font-size="18" fill="#e8c97a" text-anchor="middle" font-family="Noto Sans CJK SC" font-weight="bold">欢迎使用泡泡猫 DSH</text>
<rect x="${NAV_W+26}" y="80" width="${W-NAV_W-52}" height="2" fill="#c5a468" opacity="0.5"/>
<text x="${NAV_W+(W-NAV_W)/2}" y="120" font-size="11" fill="#cfd6ea" text-anchor="middle" font-family="Noto Sans CJK SC">本软件将安装泡泡猫 DSH 桌面版到您的计算机。</text>
<text x="${NAV_W+(W-NAV_W)/2}" y="142" font-size="11" fill="#cfd6ea" text-anchor="middle" font-family="Noto Sans CJK SC">内置 16 个插件，开箱即用，无需额外配置。</text>
<text x="${NAV_W+(W-NAV_W)/2}" y="178" font-size="10" fill="#9fb0d8" text-anchor="middle" font-family="Noto Sans CJK SC">安装过程中不会修改您的系统设置。</text>
<text x="${NAV_W+(W-NAV_W)/2}" y="200" font-size="10" fill="#9fb0d8" text-anchor="middle" font-family="Noto Sans CJK SC">点击“下一步”继续，或“取消”退出安装。</text>
<rect x="${NAV_W+26}" y="230" width="${W-NAV_W-52}" height="1" fill="#c5a468" opacity="0.3"/>
<text x="${NAV_W+(W-NAV_W)/2}" y="260" font-size="9" fill="#8892b0" text-anchor="middle" font-family="Noto Sans CJK SC">DeepSeek API Key 将在首次启动时引导您配置</text>
<text x="${NAV_W+(W-NAV_W)/2}" y="278" font-size="9" fill="#8892b0" text-anchor="middle" font-family="Noto Sans CJK SC">所有数据仅保存在本机，不会上传任何服务器</text>`;

const finish = `<rect x="${NAV_W}" y="0" width="${W-NAV_W}" height="${H}" fill="#141c38"/>
<text x="${NAV_W+(W-NAV_W)/2}" y="55" font-size="18" fill="#e8c97a" text-anchor="middle" font-family="Noto Sans CJK SC" font-weight="bold">安装完成</text>
<rect x="${NAV_W+26}" y="75" width="${W-NAV_W-52}" height="2" fill="#c5a468" opacity="0.5"/>
<text x="${NAV_W+(W-NAV_W)/2}" y="108" font-size="11" fill="#cfd6ea" text-anchor="middle" font-family="Noto Sans CJK SC">泡泡猫 DSH 已成功安装到您的计算机。</text>
<rect x="${NAV_W+40}" y="125" width="14" height="14" fill="none" stroke="#c5a468" stroke-width="1.5"/>
<text x="${NAV_W+62}" y="137" font-size="11" fill="#ffe9b0" font-family="Noto Sans CJK SC">安装完成后立即启动泡泡猫 DSH</text>
<rect x="${NAV_W+26}" y="160" width="${W-NAV_W-52}" height="1" fill="#c5a468" opacity="0.4"/>
<text x="${NAV_W+(W-NAV_W)/2}" y="190" font-size="10" fill="#e8c97a" text-anchor="middle" font-family="Noto Sans CJK SC">如果觉得本软件有用，欢迎支持我们 ❤</text>
<rect x="${NAV_W+50}" y="205" width="120" height="26" rx="4" fill="#c5a468"/>
<text x="${NAV_W+110}" y="223" font-size="10" fill="#141c38" text-anchor="middle" font-family="Noto Sans CJK SC" font-weight="bold">🔗 推荐赚佣金</text>
<rect x="${NAV_W+180}" y="205" width="120" height="26" rx="4" fill="none" stroke="#c5a468" stroke-width="1.5"/>
<text x="${NAV_W+240}" y="223" font-size="10" fill="#c5a468" text-anchor="middle" font-family="Noto Sans CJK SC">❤ 打赏支持</text>
<rect x="${NAV_W+26}" y="248" width="${W-NAV_W-52}" height="1" fill="#c5a468" opacity="0.3"/>
<text x="${NAV_W+(W-NAV_W)/2}" y="275" font-size="8" fill="#8892b0" text-anchor="middle" font-family="Noto Sans CJK SC">本软件插件除骰子大作战和文件上传功能为泡泡猫制作</text>
<text x="${NAV_W+(W-NAV_W)/2}" y="290" font-size="8" fill="#8892b0" text-anchor="middle" font-family="Noto Sans CJK SC">其余插件均收集整合自开源社区，仅供学习交流使用</text>
<text x="${NAV_W+(W-NAV_W)/2}" y="305" font-size="8" fill="#8892b0" text-anchor="middle" font-family="Noto Sans CJK SC">任何使用问题请联系：zmm168@163.com</text>
<text x="${NAV_W+(W-NAV_W)/2}" y="330" font-size="7" fill="#5a6480" text-anchor="middle" font-family="Noto Sans CJK SC">点击上方按钮将打开您的推广/打赏链接</text>`;

(async () => {
  const pages = [
    { svg: `<svg width="${W}" height="${H}">${nav()}${welcome}</svg>`, name: 'mockup-welcome.png' },
    { svg: `<svg width="${W}" height="${H}">${nav()}${finish}</svg>`, name: 'mockup-finish-ad.png' },
  ];
  for (const p of pages) {
    const buf = await sharp(Buffer.from(p.svg)).png().toBuffer();
    fs.writeFileSync('/root/软件/dsh-desktop-pack/assets/' + p.name, buf);
    console.log(p.name, buf.length, 'bytes');
  }
})().catch(e => { console.error(e); process.exit(1); });
