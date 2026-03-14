const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');
const config = require('./config');

let screenshotCounter = 1;

async function screenshot(page, name, folder = 'general') {
  const dir = path.join('test/images/screenshots', folder);
  fs.mkdirSync(dir, { recursive: true });

  const num = String(screenshotCounter++).padStart(3, '0');
  const filename = `${num}_${name.replace(/\s+/g, '_')}.png`;
  const filepath = path.join(dir, filename);

  await page.screenshot({ path: filepath, fullPage: true });
  console.log(`📸 Screenshot saved: ${filepath}`);
  return filepath;
}

async function screenshotResponsive(page, name, folder) {
  await page.setViewportSize({ width: config.SCREENSHOT.width, height: config.SCREENSHOT.height });
  await screenshot(page, `${name}_desktop`, folder);

  await page.setViewportSize(config.SCREENSHOT.mobile);
  await screenshot(page, `${name}_mobile`, folder);

  await page.setViewportSize(config.SCREENSHOT.tablet);
  await screenshot(page, `${name}_tablet`, folder);

  await page.setViewportSize({ width: config.SCREENSHOT.width, height: config.SCREENSHOT.height });
}

async function saveVideo(page, flowName) {
  const video = await page.video();
  if (video) {
    const dir = 'test/videos/flows';
    fs.mkdirSync(dir, { recursive: true });
    const filepath = path.join(dir, `${flowName.replace(/\s+/g, '_')}.webm`);
    await video.saveAs(filepath);
    console.log(`🎥 Video saved: ${filepath}`);
    return filepath;
  }
}

async function waitForLoad(page) {
  try {
    await page.waitForLoadState('networkidle', { timeout: config.TIMEOUT });
  } catch (_) {}
  await page.waitForTimeout(config.WAIT_FOR_LOAD);
}

async function waitForAction(page) {
  await page.waitForTimeout(config.WAIT_AFTER_ACTION);
}

async function highlight(page, selector) {
  try {
    await page.evaluate((sel) => {
      const el = document.querySelector(sel);
      if (el) {
        el.style.outline = '3px solid red';
        el.style.outlineOffset = '2px';
      }
    }, selector);
    await page.waitForTimeout(300);
  } catch (_) {}
}

async function annotate(page, text, x, y) {
  try {
    await page.evaluate(({ text, x, y }) => {
      const div = document.createElement('div');
      div.innerHTML = text;
      div.style.cssText = `
        position: fixed; left: ${x}px; top: ${y}px;
        background: #FF4444; color: white;
        padding: 6px 12px; border-radius: 4px;
        font-size: 14px; font-weight: bold;
        z-index: 99999; pointer-events: none;
      `;
      document.body.appendChild(div);
    }, { text, x, y });
  } catch (_) {}
}

async function loginAs(page, email, password) {
  await page.goto(config.APP_URL);
  await waitForLoad(page);

  try {
    await page.fill('input[type="email"]', email, { timeout: 5000 });
    await page.fill('input[type="password"]', password);
    await page.click('button[type="submit"]');
    await waitForLoad(page);
  } catch (e) {
    // Try data-testid selectors
    try {
      await page.fill('[data-testid="email-input"]', email);
      await page.fill('[data-testid="password-input"]', password);
      await page.click('[data-testid="login-button"]');
      await waitForLoad(page);
    } catch (e2) {
      console.warn('Login selectors not found — app may already be logged in');
    }
  }
}

module.exports = {
  screenshot,
  screenshotResponsive,
  saveVideo,
  waitForLoad,
  waitForAction,
  highlight,
  annotate,
  loginAs,
};
