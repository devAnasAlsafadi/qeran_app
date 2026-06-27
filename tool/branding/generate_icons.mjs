// Group A — app-icon PNG masters from the brand SVG sources.
//
//   branding/src/qeran_symbol_transparent.svg  ->  branding/out/{ic_adaptive_fg, ic_monochrome}.png
//                                              ->  branding/out/ic_ios_1024.png  (on wine, opaque)
//
// Run:  cd tool/branding && npm install && npm run generate:icons
//
// resvg-js rasterizes the vector crisply (no system libs); sharp composes the
// symbol onto the icon canvas, controls the safe-zone scale, and strips the
// iOS alpha channel (App Store rejects alpha on the 1024 marketing icon).

import { Resvg } from '@resvg/resvg-js';
import sharp from 'sharp';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const SRC = path.join(root, 'branding', 'src');
const OUT = path.join(root, 'branding', 'out');
fs.mkdirSync(OUT, { recursive: true });

const CANVAS = 1024;          // master size (flutter_launcher_icons downsamples)
const WINE = '#431C33';       // locked brand background
const RENDER_PX = 2048;       // oversample then downscale for clean edges
// Android adaptive: flutter_launcher_icons wraps the foreground/monochrome in an
// `android:inset="16%"` (drawable occupies the central 68%). To land the symbol
// at ~62% of the final icon — inside the 66% safe zone with margin for circular
// masks — pre-scale to 0.62 / 0.68 ≈ 0.91 here.
const ANDROID_SCALE = 0.91;
// iOS uses image_path directly (no inset), so the mark sits at a fuller 70%.
const IOS_SCALE = 0.70;

/** Render an SVG string, then trim to the artwork's tight bounding box. */
function renderTrimmed(svg) {
  const png = new Resvg(svg, {
    fitTo: { mode: 'width', value: RENDER_PX },
    background: 'rgba(0,0,0,0)',
  }).render().asPng();
  return sharp(png).trim();
}

/** Center a trimmed symbol at `scale` of the canvas, over `bg` (null = transparent). */
async function compose(symbolTrimmed, scale, bg) {
  const target = Math.round(CANVAS * scale);
  const symbol = await symbolTrimmed
    .resize({ width: target, height: target, fit: 'inside' })
    .png()
    .toBuffer();
  const background = bg === null ? { r: 0, g: 0, b: 0, alpha: 0 } : bg;
  return sharp({ create: { width: CANVAS, height: CANVAS, channels: 4, background } })
    .composite([{ input: symbol, gravity: 'center' }]);
}

const symbolSvg = fs.readFileSync(path.join(SRC, 'qeran_symbol_transparent.svg'), 'utf8');
// Monochrome layer (Android 13 themed icon): same shape, recolored white; the
// launcher tints it to match the wallpaper, so only the alpha matters.
const whiteSvg = symbolSvg.replace(/#e4c094/gi, '#ffffff');

const goldTrim = renderTrimmed(symbolSvg);
const whiteTrim = renderTrimmed(whiteSvg);

// 1) iOS / legacy-Android icon — gold symbol on wine, alpha stripped (opaque).
await (await compose(goldTrim.clone(), IOS_SCALE, WINE))
  .removeAlpha().png().toFile(path.join(OUT, 'ic_ios_1024.png'));

// 2) Android adaptive foreground — gold symbol, transparent, safe zone.
await (await compose(goldTrim.clone(), ANDROID_SCALE, null))
  .png().toFile(path.join(OUT, 'ic_adaptive_fg.png'));

// 3) Android 13+ monochrome — white silhouette, transparent, safe zone.
await (await compose(whiteTrim.clone(), ANDROID_SCALE, null))
  .png().toFile(path.join(OUT, 'ic_monochrome.png'));

for (const f of ['ic_ios_1024.png', 'ic_adaptive_fg.png', 'ic_monochrome.png']) {
  const m = await sharp(path.join(OUT, f)).metadata();
  console.log(`${f}: ${m.width}x${m.height} channels=${m.channels} hasAlpha=${m.hasAlpha}`);
}
