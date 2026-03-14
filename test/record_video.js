const { chromium } = require('playwright');

const URL  = 'https://super-business-shop-yous.onrender.com';
const EMAIL = 'mushtaqzain180@gmail.com';
const PASS  = '112233';

async function record() {
  const browser = await chromium.launch({
    headless: false, slowMo: 200 });

  const ctx = await browser.newContext({
    viewport:    { width: 1440, height: 900 },
    recordVideo: { dir: 'test/videos/',
      size: { width: 1440, height: 900 } },
  });

  const page = await ctx.newPage();
  const w = (ms) => page.waitForTimeout(ms);

  console.log('🎬 Recording full app demo...');

  // Load
  await page.goto(URL, { waitUntil: 'networkidle' });
  await w(4000);

  // Login
  await page.fill('input[type="email"]', EMAIL).catch(()=>{});
  await w(500);
  await page.fill('input[type="password"]', PASS).catch(()=>{});
  await w(500);
  await page.keyboard.press('Enter');
  await w(5000);

  // Dashboard
  await w(3000);

  // Navigate all screens
  const nav = [
    ['/#/pos',              3000],
    ['/#/inventory',        3000],
    ['/#/customers',        3000],
    ['/#/finance/expenses', 2000],
    ['/#/reports',          3000],
    ['/#/settings',         2000],
    ['/#/customer/login',   3000],
    ['/#/dashboard',        2000],
  ];

  for (const [route, delay] of nav) {
    await page.goto(`${URL}${route}`).catch(()=>{});
    await w(delay);
  }

  // Dark mode demo
  await page.goto(`${URL}/#/settings`);
  await w(2000);
  for (const sel of ['text=Dark','text=Andhera']) {
    try {
      await page.click(sel, { timeout: 1000 });
      await w(2000);
      break;
    } catch(_) {}
  }
  await page.goto(`${URL}/#/dashboard`);
  await w(2000);

  // Light mode back
  await page.goto(`${URL}/#/settings`);
  for (const sel of ['text=Light','text=Roshan']) {
    try {
      await page.click(sel, { timeout: 1000 });
      await w(1000);
      break;
    } catch(_) {}
  }

  // Offline demo
  await page.goto(`${URL}/#/pos`);
  await w(2000);
  await ctx.setOffline(true);
  await w(3000);
  await ctx.setOffline(false);
  await w(3000);

  await ctx.close();
  await browser.close();

  // Rename video
  const fs   = require('fs');
  const path = require('path');
  const files = fs.readdirSync('test/videos/')
    .filter(f => f.endsWith('.webm'))
    .sort((a,b) => {
      return fs.statSync(path.join('test/videos/',b)).mtimeMs -
             fs.statSync(path.join('test/videos/',a)).mtimeMs;
    });

  if (files.length > 0) {
    const src  = path.join('test/videos/', files[0]);
    const dest = 'test/videos/FULL_APP_DEMO.webm';
    fs.renameSync(src, dest);
    console.log('✅ Video: test/videos/FULL_APP_DEMO.webm');
  }
}

record().catch(console.error);
