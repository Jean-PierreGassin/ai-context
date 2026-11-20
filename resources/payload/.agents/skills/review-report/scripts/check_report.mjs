// Check a built report in one go: node check_report.mjs <report.html> <screenshot-dir>
// Loads it at each size in VIEWPORTS (space-separated WIDTHxHEIGHT, default a laptop 1440x900, a large display
// 2560x1300 and a phone 390x844), saves a full-page screenshot of each, and opens a screenshot full size. Fails on
// script errors, network requests, sideways scroll, broken images or videos, a flag missing from the page, or a
// screenshot that does not open.
// Needs the playwright package, found from the working directory or NODE_PATH, and a headless Chromium: its own
// (npx playwright install chromium-headless-shell), or any installed one passed as CHROMIUM_PATH.
import { mkdirSync } from 'node:fs';
import { createRequire } from 'node:module';
import { resolve } from 'node:path';
import { pathToFileURL } from 'node:url';

const [report, dir] = process.argv.slice(2);

if (!report || !dir) {
  console.error('usage: node check_report.mjs <report.html> <screenshot-dir>');
  process.exit(2);
}

const viewports = (process.env.VIEWPORTS || '1440x900 2560x1300 390x844')
  .trim()
  .split(/\s+/)
  .map((size) => size.split('x').map(Number));

if (viewports.some(([width, height]) => !(width > 0 && height > 0))) {
  console.error(`VIEWPORTS must be space-separated WIDTHxHEIGHT sizes, got "${process.env.VIEWPORTS}"`);
  process.exit(2);
}

mkdirSync(dir, { recursive: true });
const url = pathToFileURL(resolve(report)).href;
const { chromium } = createRequire(`${process.cwd()}/`)('playwright');
const browser = await chromium.launch(process.env.CHROMIUM_PATH ? { executablePath: process.env.CHROMIUM_PATH } : {});
const problems = [];

try {
  for (const [width, height] of viewports) {
    const page = await browser.newPage({ viewport: { width, height }, deviceScaleFactor: 1 });
    const errors = [];
    const requests = [];
    page.on('pageerror', (error) => errors.push(error.message));
    page.on('request', (request) => /^(https?|wss?):/.test(request.url()) && requests.push(request.url()));
    const started = Date.now();
    await page.goto(url, { waitUntil: 'load' });
    const loadMs = Date.now() - started;
    await page.waitForTimeout(250);
    const state = await page.evaluate(() => ({
      overflow: document.documentElement.scrollWidth > window.innerWidth,
      broken: [
        ...[...document.images]
          .filter((image) => image.getAttribute('src') && image.complete && image.naturalWidth === 0)
          .map((image) => image.getAttribute('src')),
        ...[...document.querySelectorAll('video')]
          .filter((video) => video.error)
          .map((video) => video.currentSrc || video.getAttribute('src')),
      ],
      flags: JSON.parse(document.getElementById('report-data').textContent.replace(/<\\\//g, '</')).flags.length,
      shown: document.querySelectorAll('section.issue').length,
    }));
    await page.screenshot({ path: `${dir}/page-${width}.png`, fullPage: true });
    const imageButton = page.locator('figure button:has(img)');
    let zoom = 'no screenshots';

    if (await imageButton.count()) {
      await imageButton.first().click();
      await page.waitForTimeout(200);
      zoom = (await page.locator('.zoom.open').count()) ? 'opens' : 'did not open';
      await page.keyboard.press('Escape');
    }

    console.log(`${width}x${height}: load ${loadMs}ms, ${requests.length} network requests, ${errors.length} errors, overflow ${state.overflow}, ${state.shown} of ${state.flags} issues shown, screenshot ${zoom}`);

    if (errors.length) problems.push(`${width}px script errors: ${errors.join('; ')}`);
    if (requests.length) problems.push(`${width}px network requests: ${requests.join(', ')}`);
    if (state.overflow) problems.push(`${width}px scrolls sideways`);
    if (state.broken.length) problems.push(`${width}px broken images or videos: ${state.broken.join(', ')}`);
    if (state.shown !== state.flags) problems.push(`${width}px shows ${state.shown} of ${state.flags} issues`);
    if (zoom === 'did not open') problems.push(`${width}px a screenshot did not open full size`);

    await page.close();
  }
} finally {
  await browser.close();
}

if (problems.length) {
  console.error(problems.join('\n'));
  process.exit(1);
}

console.log(`screenshots in ${dir}`);
