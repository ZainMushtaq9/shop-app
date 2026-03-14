  const { chromium } = require('playwright');
  const cfg = require('./test_config');

  const FLOWS = [
    {
      name: '01_login_to_dashboard',
      desc: 'Login and see dashboard',
      fn: async (page) => {
        await page.goto(cfg.URL);
        await page.waitForTimeout(3000);
        await page.fill('input[type="email"]', cfg.EMAIL);
        await page.fill('input[type="password"]', cfg.PASSWORD);
        await page.keyboard.press('Enter');
        await page.waitForTimeout(5000);
      }
    },
    {
      name: '02_complete_sale_pos',
      desc: 'Complete sale in POS',
      fn: async (page) => {
        await page.goto(`${cfg.URL}/#/pos`);
        await page.waitForTimeout(3000);
        const inputs = await page.$$('input');
        if (inputs[0]) {
          await inputs[0].fill('chawal');
          await page.waitForTimeout(2000);
        }
        const cards = await page.$$('[class*="product"]');
        if (cards.length > 0) {
          await cards[0].click();
          await page.waitForTimeout(1000);
        }
        await page.waitForTimeout(3000);
      }
    },
    {
      name: '03_dark_mode_toggle',
      desc: 'Dark mode and light mode toggle',
      fn: async (page) => {
        await page.goto(`${cfg.URL}/#/settings`);
        await page.waitForTimeout(2000);
        const dark = await page.$('text=Dark, text=Andhera');
        if (dark) {
          await dark.click();
          await page.waitForTimeout(2000);
        }
        const light = await page.$('text=Light, text=Roshan');
        if (light) {
          await light.click();
          await page.waitForTimeout(2000);
        }
      }
    },
    {
      name: '04_urdu_rtl_mode',
      desc: 'Switch to Urdu RTL',
      fn: async (page) => {
        await page.goto(`${cfg.URL}/#/settings`);
        await page.waitForTimeout(2000);
        const urdu = await page.$('text=اردو, text=Urdu');
        if (urdu) {
          await urdu.click();
          await page.waitForTimeout(2000);
          await page.goto(`${cfg.URL}/#/dashboard`);
          await page.waitForTimeout(3000);
        }
      }
    },
    {
      name: '05_ad_banner_close',
      desc: 'Ad banner appears and close button works',
      fn: async (page) => {
        await page.goto(`${cfg.URL}/#/dashboard`);
        await page.waitForTimeout(3000);
        const closeBtn = await page.$(
          '[class*="ad"] button, [class*="close"]'
        );
        if (closeBtn) {
          await page.waitForTimeout(2000);
          await closeBtn.click();
          await page.waitForTimeout(2000);
        }
      }
    },
    {
      name: '06_products_management',
      desc: 'Adding and managing products',
      fn: async (page) => {
        await page.goto(`${cfg.URL}/#/inventory`);
        await page.waitForTimeout(3000);
        const chips = await page.$$('[class*="chip"]');
        for (const chip of chips.slice(0,3)) {
          await chip.click().catch(() => {});
          await page.waitForTimeout(1000);
        }
        await page.waitForTimeout(2000);
      }
    },
    {
      name: '07_reports_date_filter',
      desc: 'Reports with date filtering',
      fn: async (page) => {
        await page.goto(`${cfg.URL}/#/reports`);
        await page.waitForTimeout(3000);
        const btns = ['text=Aaj','text=Hafte','text=Mahine'];
        for (const btn of btns) {
          try {
            await page.click(btn, { timeout: 1000 });
            await page.waitForTimeout(1500);
          } catch (_) {}
        }
      }
    },
    {
      name: '08_offline_sync',
      desc: 'Go offline and come back online',
      fn: async (page) => {
        await page.goto(`${cfg.URL}/#/pos`);
        await page.waitForTimeout(2000);
        await page.context().setOffline(true);
        await page.waitForTimeout(3000);
        await page.context().setOffline(false);
        await page.waitForTimeout(3000);
      }
    },
    {
      name: '09_customer_portal',
      desc: 'Customer portal login screen',
      fn: async (page) => {
        await page.goto(`${cfg.URL}/#/customer/login`);
        await page.waitForTimeout(4000);
      }
    },
    {
      name: '10_mobile_responsive',
      desc: 'Mobile responsive layout',
      fn: async (page) => {
        const routes = ['/#/dashboard','/#/pos','/#/inventory'];
        for (const r of routes) {
          await page.goto(`${cfg.URL}${r}`);
          await page.waitForTimeout(2000);
        }
      }
    },
  ];

  async function recordAll() {
    const browser = await chromium.launch({
      headless: false,
      slowMo: 200,
    });

    for (const flow of FLOWS) {
      console.log(`🎬 Recording: ${flow.name}`);
      const ctx = await browser.newContext({
        viewport: { width: 1440, height: 900 },
        recordVideo: {
          dir: 'test/videos/',
          size: { width: 1440, height: 900 },
        },
      });
      const page = await ctx.newPage();

      // Login first
      await page.goto(cfg.URL);
      await page.waitForTimeout(3000);
      try {
        await page.fill('input[type="email"]', cfg.EMAIL);
        await page.fill('input[type="password"]', cfg.PASSWORD);
        await page.keyboard.press('Enter');
        await page.waitForTimeout(4000);
      } catch (_) {}

      try {
        await flow.fn(page);
      } catch (e) {
        console.log(`  Error: ${e.message}`);
      }

      await ctx.close();

      // Rename video
      const fs   = require('fs');
      const path = require('path');
      const files = fs.readdirSync('test/videos/')
        .filter(f => f.endsWith('.webm'))
        .map(f => ({
          f,
          t: fs.statSync(path.join('test/videos/', f)).mtimeMs,
        }))
        .sort((a,b) => b.t - a.t);

      if (files.length > 0) {
        const src  = path.join('test/videos/', files[0].f);
        const dest = path.join('test/videos/', `${flow.name}.webm`);
        try {
          fs.renameSync(src, dest);
          console.log(`  ✅ Saved: ${dest}`);
        } catch (e) {
          console.log(`  ⚠️ Rename failed: ${e.message}`);
        }
      }
    }

    await browser.close();
    console.log('\\n✅ All videos recorded!');
    console.log('📁 test/videos/');
  }

  recordAll().catch(console.error);
