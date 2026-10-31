'use strict';
const sharp = require('/usr/local/lib/node_modules/@deepseek-ai/dsh/node_modules/sharp');
const fs = require('fs');
(async () => {
  const W=171, H=383;
  const svg=`<svg width="${W}" height="${H}" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <linearGradient id="bg" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0" stop-color="#1a2540"/>
        <stop offset="1" stop-color="#0d1326"/>
      </linearGradient>
    </defs>
    <rect width="${W}" height="${H}" fill="url(#bg)"/>
    <!-- 泡泡猫 logo -->
    <circle cx="85" cy="90" r="50" fill="#e8c97a"/>
    <circle cx="85" cy="90" r="45" fill="#141c38"/>
    <polygon points="55,55 70,20 85,50" fill="#e8c97a"/>
    <polygon points="115,55 100,20 85,50" fill="#e8c97a"/>
    <polygon points="60,52 70,28 80,50" fill="#e8c97a" opacity="0.4"/>
    <polygon points="110,52 100,28 90,50" fill="#e8c97a" opacity="0.4"/>
    <ellipse cx="70" cy="85" rx="8" ry="10" fill="#e8c97a"/>
    <ellipse cx="100" cy="85" rx="8" ry="10" fill="#e8c97a"/>
    <ellipse cx="70" cy="85" rx="4" ry="5" fill="#141c38"/>
    <ellipse cx="100" cy="85" rx="4" ry="5" fill="#141c38"/>
    <polygon points="85,95 80,100 90,100" fill="#e8c97a" opacity="0.7"/>
    <path d="M 85 100 Q 80 108 75 105" stroke="#e8c97a" stroke-width="2" fill="none" opacity="0.6"/>
    <path d="M 85 100 Q 90 108 95 105" stroke="#e8c97a" stroke-width="2" fill="none" opacity="0.6"/>
    <line x1="40" y1="95" x2="60" y2="97" stroke="#e8c97a" stroke-width="1.5" opacity="0.5"/>
    <line x1="40" y1="105" x2="60" y2="103" stroke="#e8c97a" stroke-width="1.5" opacity="0.5"/>
    <line x1="130" y1="95" x2="110" y2="97" stroke="#e8c97a" stroke-width="1.5" opacity="0.5"/>
    <line x1="130" y1="105" x2="110" y2="103" stroke="#e8c97a" stroke-width="1.5" opacity="0.5"/>
    <text x="85" y="170" text-anchor="middle" font-size="16" fill="#e8c97a" font-family="Noto Sans CJK SC" font-weight="bold">泡泡猫</text>
    <text x="85" y="195" text-anchor="middle" font-size="11" fill="#9fb0d8" font-family="Noto Sans CJK SC">DSH 桌面版</text>
    <text x="85" y="215" text-anchor="middle" font-size="9" fill="#5a6480" font-family="Noto Sans CJK SC">v1.6.6</text>
    <line x1="30" y1="240" x2="141" y2="240" stroke="#e8c97a" stroke-width="1" opacity="0.3"/>
    <text x="85" y="270" text-anchor="middle" font-size="14" fill="#e8c97a">🎲 📎 🧠 🤖</text>
    <text x="85" y="295" text-anchor="middle" font-size="14" fill="#e8c97a">⏰ 💬 🛒 🎨</text>
    <text x="85" y="320" text-anchor="middle" font-size="9" fill="#5a6480">14 个插件预装</text>
    <line x1="30" y1="345" x2="141" y2="345" stroke="#e8c97a" stroke-width="1" opacity="0.2"/>
    <text x="85" y="365" text-anchor="middle" font-size="8" fill="#3a4460">paopaocat</text>
  </svg>`;
  const png=await sharp(Buffer.from(svg)).png().toBuffer();
  fs.writeFileSync('/tmp/left.png',png);
  const {execSync}=require('child_process');
  execSync('convert /tmp/left.png BMP3:/root/软件/dsh-desktop-pack/assets/Left.bmp');
  console.log('Left.bmp ok',fs.statSync('/root/软件/dsh-desktop-pack/assets/Left.bmp').size,'bytes');
})().catch(e=>{console.error(e);process.exit(1);});
