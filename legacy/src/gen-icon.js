// 用服务器端 sharp 把爪印 SVG 光栅化并打包为多尺寸 PNG 帧 ICO
const sharp = require('/usr/local/lib/node_modules/@deepseek-ai/dsh/node_modules/sharp');
const fs = require('fs');

const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 256 256">
  <rect x="8" y="8" width="240" height="240" rx="52" fill="#16203f"/>
  <rect x="8" y="8" width="240" height="240" rx="52" fill="none" stroke="#e8c97a" stroke-width="7"/>
  <ellipse cx="128" cy="158" rx="56" ry="46" fill="#e8c97a"/>
  <circle cx="74" cy="98" r="25" fill="#e8c97a"/>
  <circle cx="128" cy="76" r="27" fill="#e8c97a"/>
  <circle cx="182" cy="98" r="25" fill="#e8c97a"/>
  <circle cx="200" cy="52" r="15" fill="#ffffff" opacity="0.9"/>
  <circle cx="222" cy="76" r="8" fill="#ffffff" opacity="0.7"/>
</svg>`;

(async () => {
  const sizes = [256, 128, 64, 48, 32, 16];
  const frames = [];
  for (const s of sizes) {
    const buf = await sharp(Buffer.from(svg), { density: 512 }).resize(s, s).png().toBuffer();
    frames.push({ s, buf });
  }
  let offset = 6 + 16 * frames.length;
  const header = Buffer.alloc(6);
  header.writeUInt16LE(0, 0); header.writeUInt16LE(1, 2); header.writeUInt16LE(frames.length, 4);
  const entries = [], blobs = [];
  for (const { s, buf } of frames) {
    const e = Buffer.alloc(16);
    e[0] = s === 256 ? 0 : s; e[1] = s === 256 ? 0 : s;
    e[2] = 0; e[3] = 0;
    e.writeUInt16LE(1, 4); e.writeUInt16LE(32, 6);
    e.writeUInt32LE(buf.length, 8); e.writeUInt32LE(offset, 12);
    offset += buf.length;
    entries.push(e); blobs.push(buf);
  }
  const out = process.argv[2];
  fs.writeFileSync(out, Buffer.concat([header, ...entries, ...blobs]));
  console.log('ICO written:', out, fs.statSync(out).size, 'bytes');
})().catch(e => { console.error(e); process.exit(1); });
