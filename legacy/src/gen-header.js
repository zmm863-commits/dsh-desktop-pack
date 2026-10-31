'use strict';
const sharp = require('/usr/local/lib/node_modules/@deepseek-ai/dsh/node_modules/sharp');
const fs = require('fs');
(async () => {
  const W=150,H=57;
  const svg=`<svg width="${W}" height="${H}" xmlns="http://www.w3.org/2000/svg">
    <rect width="${W}" height="${H}" fill="#141c38"/>
    <circle cx="22" cy="28" r="14" fill="#e8c97a"/>
    <circle cx="22" cy="28" r="12" fill="#141c38"/>
    <polygon points="12,18 16,8 22,16" fill="#e8c97a"/>
    <polygon points="32,18 28,8 22,16" fill="#e8c97a"/>
    <ellipse cx="18" cy="26" rx="2" ry="2.5" fill="#e8c97a"/>
    <ellipse cx="26" cy="26" rx="2" ry="2.5" fill="#e8c97a"/>
    <polygon points="22,30 21,32 23,32" fill="#e8c97a" opacity="0.7"/>
    <text x="44" y="24" font-size="11" fill="#e8c97a" font-family="Noto Sans CJK SC" font-weight="bold">泡泡猫 DSH</text>
    <text x="44" y="38" font-size="8" fill="#9fb0d8" font-family="Noto Sans CJK SC">v1.6.6</text>
  </svg>`;
  const png=await sharp(Buffer.from(svg)).png().toBuffer();
  fs.writeFileSync('/tmp/header.png',png);
  const {execSync}=require('child_process');
  execSync('convert /tmp/header.png BMP3:/root/软件/dsh-desktop-pack/assets/header.bmp');
  console.log('header.bmp ok',fs.statSync('/root/软件/dsh-desktop-pack/assets/header.bmp').size,'bytes');
})().catch(e=>{console.error(e);process.exit(1);});
