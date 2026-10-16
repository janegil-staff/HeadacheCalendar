// scripts/convert-to-webp.mjs
// Bulk-converts PNG images to WebP.
//
// Usage (from the project root):
//   node scripts/convert-to-webp.mjs <input-folder> [output-folder] [--quality=85] [--lossless] [--delete]
//
// Examples:
//   node scripts/convert-to-webp.mjs screenshots
//       -> writes screenshots/**/*.webp next to each .png
//   node scripts/convert-to-webp.mjs screenshots public/images
//       -> mirrors the folder structure into public/images
//   node scripts/convert-to-webp.mjs public/images --delete
//       -> converts in place and removes the original .png files
//
// Subfolders are included. Files whose .webp is already newer than the .png are skipped.
// Transparency is kept. Needs sharp: npm install --save-dev sharp
import fs from "node:fs";
import path from "node:path";
import sharp from "sharp";

const args = process.argv.slice(2);
const flags = Object.fromEntries(
  args
    .filter((a) => a.startsWith("--"))
    .map((a) => {
      const [key, value] = a.slice(2).split("=");
      return [key, value ?? true];
    })
);
const [inputArg, outputArg] = args.filter((a) => !a.startsWith("--"));

if (!inputArg) {
  console.error("Usage: node scripts/convert-to-webp.mjs <input-folder> [output-folder] [--quality=85] [--lossless] [--delete]");
  process.exit(1);
}

const SRC_ROOT = path.resolve(inputArg);
const OUT_ROOT = path.resolve(outputArg ?? inputArg);
const QUALITY = Number(flags.quality ?? 85);
const LOSSLESS = Boolean(flags.lossless);
const DELETE_ORIGINALS = Boolean(flags.delete);

if (!fs.existsSync(SRC_ROOT) || !fs.statSync(SRC_ROOT).isDirectory()) {
  console.error(`Not a folder: ${SRC_ROOT}`);
  process.exit(1);
}

function findPngs(dir) {
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap((entry) => {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) return entry.name === "node_modules" ? [] : findPngs(full);
    return path.extname(entry.name).toLowerCase() === ".png" ? [full] : [];
  });
}

const kb = (bytes) => `${(bytes / 1024).toFixed(0)} KB`;

const files = findPngs(SRC_ROOT);
if (files.length === 0) {
  console.log(`No .png files found in ${SRC_ROOT}`);
  process.exit(0);
}

let converted = 0;
let skipped = 0;
let failed = 0;
let bytesBefore = 0;
let bytesAfter = 0;

for (const src of files) {
  const rel = path.relative(SRC_ROOT, src);
  const out = path.join(OUT_ROOT, rel.replace(/\.png$/i, ".webp"));

  if (fs.existsSync(out) && fs.statSync(out).mtimeMs >= fs.statSync(src).mtimeMs) {
    skipped++;
    continue;
  }

  try {
    fs.mkdirSync(path.dirname(out), { recursive: true });
    await sharp(src)
      .webp(LOSSLESS ? { lossless: true } : { quality: QUALITY, alphaQuality: 100 })
      .toFile(out);

    const before = fs.statSync(src).size;
    const after = fs.statSync(out).size;
    bytesBefore += before;
    bytesAfter += after;
    converted++;
    console.log(`✓ ${rel}  ${kb(before)} -> ${kb(after)}`);

    if (DELETE_ORIGINALS) fs.unlinkSync(src);
  } catch (err) {
    failed++;
    console.error(`✗ ${rel}: ${err.message}`);
  }
}

const saved = bytesBefore ? Math.round((1 - bytesAfter / bytesBefore) * 100) : 0;
console.log(
  `\nDone: ${converted} converted, ${skipped} already up to date, ${failed} failed.` +
    (converted ? ` ${kb(bytesBefore)} -> ${kb(bytesAfter)} (${saved}% smaller).` : "")
);
process.exit(failed ? 1 : 0);
