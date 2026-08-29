// settings.yaml 预检：用法 node check-settings.cjs <安装根目录> <settings路径>
// 退出码 0=合法 7=读不到 8=yaml库缺失 9=解析失败(stderr 给出行列)
'use strict';
const path = require('path');
const fs = require('fs');
const root = process.argv[2];
const file = process.argv[3];
let Yaml;
try { Yaml = require(path.join(root, 'app', 'node_modules', 'yaml')); }
catch (e) { console.error('yaml lib missing: ' + e.message); process.exit(8); }
let text;
try { text = fs.readFileSync(file, 'utf8'); }
catch (e) { console.error('read fail: ' + e.message); process.exit(7); }
text = text.replace(/^\uFEFF/, '');
const doc = Yaml.parseDocument(text, { prettyErrors: true });
if (doc.errors.length > 0) {
  console.error(doc.errors.map(e => {
    const at = e.linePos && e.linePos[0];
    return `${e.code || 'ERR'}${at ? ` @ line ${at.line} col ${at.col}` : ''}`;
  }).join('; '));
  process.exit(9);
}
const js = doc.toJS();
if (js === null || typeof js !== 'object' || Array.isArray(js)) {
  console.error('root is not a map');
  process.exit(9);
}
process.exit(0);
