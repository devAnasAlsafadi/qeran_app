// Group B — Android notification small-icon.
//
//   branding/src/qeran_symbol_transparent.svg  --recolor white-->  VectorDrawable
//        ->  android/app/src/main/res/drawable/ic_stat_qeran.xml
//
// Android renders the small icon as a pure-alpha silhouette (tinted by the
// accent color), so the source must be white-on-transparent. The full mark
// stays legible because the vector renders at device density (72px on 3x,
// 96px on 4x) — not a literal 24px.

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import s2v from 'svg2vectordrawable';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const SRC = path.join(root, 'branding', 'src');
const RES = path.join(root, 'android', 'app', 'src', 'main', 'res', 'drawable');
fs.mkdirSync(RES, { recursive: true });

// Inline the CSS-class fills to explicit white so svg2vectordrawable (which does
// not resolve CSS) produces a solid silhouette. Drop the <style> block.
const raw = fs.readFileSync(path.join(SRC, 'qeran_symbol_transparent.svg'), 'utf8');
const whiteSvg = raw
  .replace(/<defs>[\s\S]*?<\/defs>/, '')
  .replace(/class="cls-2"/g, 'fill="#ffffff"');

// --- VectorDrawable ---
// Notification small-icons use a 24dp intrinsic size; keep the 1024 viewport.
const vd = (await s2v(whiteSvg, { floatPrecision: 2, fillColor: '#FFFFFF' }))
  .replace('android:width="1024dp"', 'android:width="24dp"')
  .replace('android:height="1024dp"', 'android:height="24dp"');
fs.writeFileSync(path.join(RES, 'ic_stat_qeran.xml'), vd);
const pathCount = (vd.match(/<path/g) || []).length;
console.log(`VectorDrawable: ${pathCount} <path> elements -> res/drawable/ic_stat_qeran.xml`);
