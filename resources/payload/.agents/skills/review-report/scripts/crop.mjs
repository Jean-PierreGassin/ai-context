// Cut a tight, unscaled crop out of a screenshot: node crop.mjs <in.png> <out.png> <x> <y> <width> <height>
// Needs the playwright package, found from the working directory or NODE_PATH, and a headless Chromium: its own
// (npx playwright install chromium-headless-shell), or any installed one passed as CHROMIUM_PATH.
import { readFileSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';

const [source, out, ...box] = process.argv.slice(2);
const [x, y, width, height] = box.map(Number);

if (!source || !out || [x, y].some((value) => !Number.isFinite(value) || value < 0) || [width, height].some((value) => !Number.isFinite(value) || value <= 0)) {
  console.error('usage: node crop.mjs <in.png> <out.png> <x> <y> <width> <height>, with width and height above 0');
  process.exit(2);
}

const { chromium } = createRequire(`${process.cwd()}/`)('playwright');
const browser = await chromium.launch(process.env.CHROMIUM_PATH ? { executablePath: process.env.CHROMIUM_PATH } : {});

try {
  const page = await browser.newPage();
  const data = `data:image/png;base64,${readFileSync(source).toString('base64')}`;
  const result = await page.evaluate(async ({ data, x, y, width, height }) => {
    const image = new Image();
    image.src = data;
    await image.decode();

    if (x >= image.naturalWidth || y >= image.naturalHeight) {
      return { error: `the crop starts at ${x},${y}, outside the ${image.naturalWidth}x${image.naturalHeight} image` };
    }

    const canvas = document.createElement('canvas');
    canvas.width = Math.min(width, image.naturalWidth - x);
    canvas.height = Math.min(height, image.naturalHeight - y);
    canvas.getContext('2d').drawImage(image, x, y, canvas.width, canvas.height, 0, 0, canvas.width, canvas.height);

    return { png: canvas.toDataURL('image/png').split(',')[1] };
  }, { data, x, y, width, height });

  if (result.error) {
    console.error(`crop: ${result.error}`);
    process.exitCode = 1;
  } else {
    writeFileSync(out, Buffer.from(result.png, 'base64'));
    console.log(out);
  }
} finally {
  await browser.close();
}
