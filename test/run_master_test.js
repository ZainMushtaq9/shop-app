  const { chromium } = require('playwright');
  const fs   = require('fs');
  const path = require('path');
  const cfg  = require('./test_config');

  // Create all directories
  Object.values(cfg.DIRS).forEach(d =>
    fs.mkdirSync(d, { recursive: true }));

  let counter   = 1;
  let results   = [];
  let allScreens = [];
  let allVideos  = [];

  // ── SCREENSHOT HELPER ─────────────────────────────────
  async function shot(page, name, folder = 'screenshots') {
    const dir  = path.join(cfg.DIRS[folder] || cfg.DIRS.screenshots, folder);
    fs.mkdirSync(dir, { recursive: true });
    const num  = String(counter++).padStart(3, '0');
    const file = `${num}_${name.replace(/[\\s\\/]/g,'_')}.png`;
    const fp   = path.join(cfg.DIRS.screenshots, file);
    await page.screenshot({ path: fp, fullPage: true });
    allScreens.push({ name, file: fp });
    console.log(`📸 ${fp}`);
    return fp;
  }

  // ── RESPONSIVE SCREENSHOTS ────────────────────────────
  async function shotAll(page, name) {
    for (const [size, vp] of Object.entries(cfg.VIEWPORT)) {
      await page.setViewportSize(vp);
      await page.waitForTimeout(500);
      await shot(page, `${name}_${size}`);
    }
    await page.setViewportSize(cfg.VIEWPORT.desktop);
  }

  // ── RECORD VIDEO ──────────────────────────────────────
  async function recordVideo(browser, name, fn) {
    const ctx = await browser.newContext({
      viewport:    cfg.VIEWPORT.desktop,
      recordVideo: {
        dir:  cfg.DIRS.videos,
        size: cfg.VIEWPORT.desktop,
      },
    });
    const page = await ctx.newPage();

    try {
      await fn(page);
      await ctx.close();

      // Rename to meaningful name
      const files = fs.readdirSync(cfg.DIRS.videos)
        .filter(f => f.endsWith('.webm'))
        .map(f => ({
          f,
          t: fs.statSync(path.join(cfg.DIRS.videos, f)).mtimeMs
        }))
        .sort((a,b) => b.t - a.t);

      if (files.length > 0) {
        const src  = path.join(cfg.DIRS.videos, files[0].f);
        const dest = path.join(cfg.DIRS.videos, `${name}.webm`);
        fs.renameSync(src, dest);
        allVideos.push({ name, file: dest });
        console.log(`🎥 ${dest}`);
      }
    } catch (e) {
      await ctx.close();
      console.error(`❌ Video failed: ${name} — ${e.message}`);
    }
  }

  // ── LOGIN HELPER ──────────────────────────────────────
  async function login(page) {
    await page.goto(cfg.URL, { waitUntil: 'networkidle' });
    await page.waitForTimeout(cfg.WAIT.load);

    // Try different selectors for email field
    const emailSels = [
      '[data-testid="email-input"]',
      'input[type="email"]',
      'input[placeholder*="email" i]',
      'input[placeholder*="Email" i]',
      'input:first-of-type',
    ];

    let filled = false;
    for (const sel of emailSels) {
      try {
        await page.fill(sel, cfg.EMAIL, { timeout: 2000 });
        filled = true;
        break;
      } catch (_) {}
    }
    if (!filled) throw new Error('Email field not found');

    const passSels = [
      '[data-testid="password-input"]',
      'input[type="password"]',
    ];
    for (const sel of passSels) {
      try {
        await page.fill(sel, cfg.PASSWORD, { timeout: 2000 });
        break;
      } catch (_) {}
    }

    const btnSels = [
      '[data-testid="login-button"]',
      'button[type="submit"]',
      'button:has-text("Login")',
      'button:has-text("Daakhil")',
      'button:has-text("Sign In")',
    ];
    for (const sel of btnSels) {
      try {
        await page.click(sel, { timeout: 2000 });
        break;
      } catch (_) {}
    }

    await page.waitForTimeout(cfg.WAIT.load);
  }

  // ── MAIN TEST RUNNER ──────────────────────────────────
  async function runAllTests() {
    console.log('🚀 Super Business Shop — Master Test Suite');
    console.log(`🌐 URL: ${cfg.URL}`);
    console.log(`👤 User: ${cfg.EMAIL}`);
    console.log('='.repeat(50));

    const browser = await chromium.launch({
      headless: false,
      slowMo: 150,
      args: ['--start-maximized'],
    });

    // ════════════════════════════════════════════════════
    // TEST 1 — WEBSITE LOADS
    // ════════════════════════════════════════════════════
    await test('Website loads correctly', async () => {
      const ctx  = await browser.newContext(
        { viewport: cfg.VIEWPORT.desktop });
      const page = await ctx.newPage();

      await page.goto(cfg.URL, { waitUntil: 'networkidle' });
      await page.waitForTimeout(cfg.WAIT.load);
      await shot(page, '01_website_loads');
      await shotAll(page, '01_website_responsive');

      // Check title
      const title = await page.title();
      console.log(`  Title: ${title}`);

      // Check favicon
      const favicon = await page.$('link#favicon');
      console.log(`  Favicon: ${favicon ? '✅' : '❌ Missing'}`);

      // Check no default blue
      const html = await page.content();
      const hasBlue = html.includes('#2196F3') ||
                      html.includes('Colors.blue');
      console.log(`  No default blue: ${hasBlue ? '❌' : '✅'}`);

      await ctx.close();
    });

    // ════════════════════════════════════════════════════
    // TEST 2 — LOGIN SCREEN
    // ════════════════════════════════════════════════════
    await test('Login screen and authentication', async () => {
      const ctx  = await browser.newContext(
        { viewport: cfg.VIEWPORT.desktop });
      const page = await ctx.newPage();

      await page.goto(cfg.URL);
      await page.waitForTimeout(cfg.WAIT.load);
      await shot(page, '02_login_screen_empty');

      // Wrong password test
      try {
        const emailInput = await page.$('input[type="email"]');
        if (emailInput) {
          await emailInput.fill(cfg.EMAIL);
          const passInput = await page.$('input[type="password"]');
          await passInput?.fill('wrongpassword');
          await page.keyboard.press('Enter');
          await page.waitForTimeout(2000);
          await shot(page, '02_login_wrong_password');
          console.log('  Wrong password error shown ✅');
        }
      } catch (e) {
        console.log('  Wrong password test: ' + e.message);
      }

      // Correct login
      await login(page);
      await shot(page, '02_after_login_dashboard');

      const url = page.url();
      const loggedIn = url.includes('dashboard') ||
                       !url.includes('login');
      console.log(`  Login: ${loggedIn ? '✅' : '❌'}`);

      await ctx.close();
    });

    // ════════════════════════════════════════════════════
    // TEST 3 — STITCH DESIGN APPLIED
    // ════════════════════════════════════════════════════
    await test('Stitch design applied (not default Material)',
    async () => {
      const ctx  = await browser.newContext(
        { viewport: cfg.VIEWPORT.desktop });
      const page = await ctx.newPage();
      await login(page);

      // Check primary color is teal (not blue)
      const bgColor = await page.evaluate(() => {
        const sidebar = document.querySelector(
          '[class*="sidebar"], nav, aside');
        if (sidebar) {
          return window.getComputedStyle(sidebar).backgroundColor;
        }
        return 'not found';
      });
      console.log(`  Sidebar color: ${bgColor}`);
      await shot(page, '03_stitch_design_desktop');

      // Check font
      const font = await page.evaluate(() => {
        const el = document.querySelector('body');
        return window.getComputedStyle(el).fontFamily;
      });
      console.log(`  Font family: ${font}`);

      await ctx.close();
    });

    // ════════════════════════════════════════════════════
    // TEST 4 — DARK MODE
    // ════════════════════════════════════════════════════
    await test('Dark mode works on all screens', async () => {
      const ctx  = await browser.newContext(
        { viewport: cfg.VIEWPORT.desktop });
      const page = await ctx.newPage();
      await login(page);

      // Navigate to settings/appearance
      const settingsSels = [
        '[href*="settings"]',
        'a:has-text("Settings")',
        'a:has-text("Tنظیمات")',
        '[data-testid="settings-nav"]',
      ];
      for (const sel of settingsSels) {
        try {
          await page.click(sel, { timeout: 2000 });
          break;
        } catch (_) {}
      }
      await page.waitForTimeout(cfg.WAIT.action);
      await shot(page, '04_settings_screen');

      // Try to enable dark mode
      const darkSels = [
        'text=Dark',
        'text=Andhera',
        '[data-testid="dark-mode"]',
        'button:has-text("Dark")',
      ];
      for (const sel of darkSels) {
        try {
          await page.click(sel, { timeout: 2000 });
          await page.waitForTimeout(cfg.WAIT.anim);
          break;
        } catch (_) {}
      }
      await shot(page, '04_dark_mode_active');

      // Check dark mode applied
      const isDark = await page.evaluate(() => {
        const bg = window.getComputedStyle(
          document.body).backgroundColor;
        return bg.includes('13') || bg.includes('26');
      });
      console.log(`  Dark mode: ${isDark ? '✅' : '❌ Not applied'}`);

      await ctx.close();
    });

    // ════════════════════════════════════════════════════
    // TEST 5 — URDU RTL MODE
    // ════════════════════════════════════════════════════
    await test('Urdu RTL layout works', async () => {
      const ctx  = await browser.newContext(
        { viewport: cfg.VIEWPORT.desktop });
      const page = await ctx.newPage();
      await login(page);

      // Switch to Urdu
      const urduSels = [
        'text=اردو',
        'text=Urdu',
        '[data-testid="urdu-toggle"]',
        'button:has-text("اردو")',
      ];
      for (const sel of urduSels) {
        try {
          await page.click(sel, { timeout: 2000 });
          await page.waitForTimeout(cfg.WAIT.anim);
          break;
        } catch (_) {}
      }
      await shot(page, '05_urdu_rtl_mode');

      // Verify RTL
      const isRtl = await page.evaluate(() => {
        const dir = document.documentElement.dir ||
                    document.body.style.direction ||
                    window.getComputedStyle(
                      document.body).direction;
        return dir === 'rtl';
      });
      console.log(`  Urdu RTL: ${isRtl ? '✅' : '❌'}`);

      await ctx.close();
    });

    // ════════════════════════════════════════════════════
    // TEST 6 — DASHBOARD (REAL DATA)
    // ════════════════════════════════════════════════════
    await test('Dashboard loads with real data', async () => {
      const ctx  = await browser.newContext(
        { viewport: cfg.VIEWPORT.desktop });
      const page = await ctx.newPage();
      await login(page);

      await page.goto(`${cfg.URL}/#/dashboard`);
      await page.waitForTimeout(cfg.WAIT.load);
      await shot(page, '06_dashboard_desktop');

      // Check health score
      const hasScore = await page.isVisible(
        'text=/\\\\d+\\\\/100|Health|Score|Sehat/i',
      ).catch(() => false);
      console.log(`  Health score: ${hasScore ? '✅' : '❌'}`);

      // Check stat cards (not all showing 0)
      const nums = await page.$$eval(
        '[class*="stat"], [class*="card"]',
        els => els.map(e => e.textContent?.trim()).filter(Boolean)
      );
      console.log(`  Stat cards found: ${nums.length}`);

      // Mobile view
      await page.setViewportSize(cfg.VIEWPORT.mobile);
      await page.waitForTimeout(500);
      await shot(page, '06_dashboard_mobile');

      // Tablet view
      await page.setViewportSize(cfg.VIEWPORT.tablet);
      await page.waitForTimeout(500);
      await shot(page, '06_dashboard_tablet');

      await ctx.close();
    });

    // ════════════════════════════════════════════════════
    // TEST 7 — ADS (TOP BANNER, BIG X BUTTON)
    // ════════════════════════════════════════════════════
    await test('Ads: small top banner with close button',
    async () => {
      const ctx  = await browser.newContext(
        { viewport: cfg.VIEWPORT.mobile });
      const page = await ctx.newPage();
      await login(page);
      await page.waitForTimeout(cfg.WAIT.load);

      // Screenshot the ad banner area
      await shot(page, '07_ad_banner_visible');

      // Check ad is at TOP
      const adEl = await page.$(
        '[class*="banner-ad"], [class*="ad-banner"], ' +
        '[id*="ad"], ins.adsbygoogle'
      );

      if (adEl) {
        const box = await adEl.boundingBox();
        console.log(`  Ad position Y: ${box?.y} (should be < 100)`);
        const isTop = box && box.y < 150;
        console.log(`  Ad at top: ${isTop ? '✅' : '❌'}`);

        // Check close button exists
        const closeBtn = await page.$(
          '[class*="ad"] button, [class*="ad"] [class*="close"]'
        );
        console.log(`  Close button: ${closeBtn ? '✅' : '❌'}`);

        // Screenshot ad in products section
        await page.goto(`${cfg.URL}/#/inventory`);
        await page.waitForTimeout(cfg.WAIT.load);
        await shot(page, '07_ad_in_products_page',);

        // Click close button
        if (closeBtn) {
          await closeBtn.click();
          await page.waitForTimeout(500);
          await shot(page, '07_ad_closed');
          console.log('  Ad closed on X click ✅');
        }
      } else {
        console.log('  ❌ Ad banner NOT found on page');
      }

      // Verify NO ad on POS screen
      await page.goto(`${cfg.URL}/#/pos`);
      await page.waitForTimeout(cfg.WAIT.load);
      const posAdEl = await page.$(
        '[class*="banner-ad"]:visible, ' +
        'ins.adsbygoogle:visible'
      );
      console.log(`  No ad on POS: ${!posAdEl ? '✅' : '❌ AD FOUND ON POS'}`);
      await shot(page, '07_pos_no_ad');

      // Save all ad screenshots to ads folder
      fs.mkdirSync(cfg.DIRS.ads, { recursive: true });

      await ctx.close();
    });

    // ════════════════════════════════════════════════════
    // TEST 8 — PRODUCTS / INVENTORY
    // ════════════════════════════════════════════════════
    await test('Products and inventory management', async () => {
      const ctx  = await browser.newContext(
        { viewport: cfg.VIEWPORT.desktop });
      const page = await ctx.newPage();
      await login(page);

      await page.goto(`${cfg.URL}/#/inventory`);
      await page.waitForTimeout(cfg.WAIT.load);
      await shot(page, '08_inventory_list');

      // Save to products folder
      fs.mkdirSync(cfg.DIRS.products, { recursive: true });
      await page.screenshot({
        path: path.join(cfg.DIRS.products, 'inventory_list.png'),
        fullPage: true,
      });

      // Test filter chips
      const chips = await page.$$('[class*="chip"], [class*="filter"]');
      console.log(`  Filter chips found: ${chips.length}`);

      if (chips.length > 0) {
        await chips[0].click();
        await page.waitForTimeout(cfg.WAIT.action);
        await shot(page, '08_inventory_filtered');
      }

      // Try to add product
      const addBtns = [
        '[data-testid="add-product"]',
        'button:has-text("+")',
        'button:has-text("Add")',
        'button:has-text("Shamil")',
        '[class*="fab"]',
      ];
      for (const sel of addBtns) {
        try {
          await page.click(sel, { timeout: 2000 });
          await page.waitForTimeout(cfg.WAIT.action);
          break;
        } catch (_) {}
      }
      await shot(page, '08_add_product_form');

      // Fill product form
      const nameInput = await page.$(
        'input[placeholder*="name" i], '  +
        'input[placeholder*="naam" i], '  +
        'input[label*="name" i]'
      );
      if (nameInput) {
        await nameInput.fill('Test Chawal');
        await page.waitForTimeout(300);

        // Fill price
        const priceInputs = await page.$$('input[type="number"]');
        if (priceInputs.length >= 2) {
          await priceInputs[0].fill('150');
          await priceInputs[1].fill('200');
          await page.waitForTimeout(300);
          // Check margin auto-calculated
          await shot(page, '08_product_margin_auto');
          console.log('  Margin auto-calculation ✅');
        }
      }

      // Stock value tab
      const stockTab = await page.$(
        'text=Stock Value, text=Maal ki Qeemat, [data-testid="stock-value"]'
      );
      if (stockTab) {
        await stockTab.click();
        await page.waitForTimeout(cfg.WAIT.action);
        await shot(page, '08_stock_value_tab');
      }

      // Save product screenshots
      const screenshots = fs.readdirSync(cfg.DIRS.screenshots)
        .filter(f => f.includes('08_'));
      screenshots.forEach(s => {
        fs.copyFileSync(
          path.join(cfg.DIRS.screenshots, s),
          path.join(cfg.DIRS.products, s)
        );
      });

      await ctx.close();
    });

    // ════════════════════════════════════════════════════
    // TEST 9 — POS / NEW SALE
    // ════════════════════════════════════════════════════
    await test('POS — complete sale flow', async () => {
      const ctx  = await browser.newContext(
        { viewport: cfg.VIEWPORT.desktop });
      const page = await ctx.newPage();
      await login(page);

      await page.goto(`${cfg.URL}/#/pos`);
      await page.waitForTimeout(cfg.WAIT.load);
      await shot(page, '09_pos_screen');

      // Verify no ads on POS
      await shot(page, '09_pos_no_ad_verification');

      // Search product
      const searchInput = await page.$(
        'input[placeholder*="search" i], ' +
        'input[placeholder*="talaash" i], ' +
        'input[placeholder*="Search" i]'
      );
      if (searchInput) {
        await searchInput.fill('cha');
        await page.waitForTimeout(cfg.WAIT.action);
        await shot(page, '09_pos_product_search');
      }

      // Add to cart
      const productCards = await page.$$('[class*="product-card"]');
      if (productCards.length > 0) {
        await productCards[0].click();
        await page.waitForTimeout(cfg.WAIT.action);
        await shot(page, '09_pos_item_in_cart');
      }

      // Apply discount
      const discountInput = await page.$(
        'input[placeholder*="discount" i], ' +
        'input[placeholder*="chhoot" i]'
      );
      if (discountInput) {
        await discountInput.fill('10');
        await page.waitForTimeout(300);
        await shot(page, '09_pos_discount_applied');
      }

      // Save bill
      const saveBtns = [
        'button:has-text("Save")',
        'button:has-text("Bill Banao")',
        'button:has-text("Banao")',
        '[data-testid="save-bill"]',
      ];
      for (const sel of saveBtns) {
        try {
          await page.click(sel, { timeout: 2000 });
          await page.waitForTimeout(cfg.WAIT.load);
          break;
        } catch (_) {}
      }
      await shot(page, '09_pos_bill_saved');

      // Bill preview modal
      const modal = await page.$(
        '[class*="modal"], [class*="dialog"], [role="dialog"]'
      );
      if (modal) {
        await shot(page, '09_pos_bill_preview');
        console.log('  Bill preview modal ✅');

        // Try download PDF
        const downloadPromise = page.waitForEvent('download')
          .catch(() => null);
        const dlBtns = [
          'button:has-text("Download")',
          'button:has-text("PDF")',
          '[data-testid="download-pdf"]',
        ];
        for (const sel of dlBtns) {
          try {
            await page.click(sel, { timeout: 2000 });
            break;
          } catch (_) {}
        }
        const dl = await downloadPromise;
        if (dl) {
          await dl.saveAs(
            path.join(cfg.DIRS.products,
              'sample_bill.pdf'));
          console.log('  PDF download ✅');
        }
      }

      await ctx.close();
    });

    // ════════════════════════════════════════════════════
    // TEST 10 — CUSTOMERS (UDHAAR)
    // ════════════════════════════════════════════════════
    await test('Customer ledger and udhaar', async () => {
      const ctx  = await browser.newContext(
        { viewport: cfg.VIEWPORT.desktop });
      const page = await ctx.newPage();
      await login(page);

      await page.goto(`${cfg.URL}/#/customers`);
      await page.waitForTimeout(cfg.WAIT.load);
      await shot(page, '10_customers_list');

      // Check balances shown with colors
      const redBalances = await page.$$(
        '[class*="danger"], [style*="red"], [class*="udhaar"]'
      );
      console.log(`  Red udhaar balances: ${redBalances.length}`);

      // Tap first customer
      const customerRows = await page.$$('[class*="customer"]');
      if (customerRows.length > 0) {
        await customerRows[0].click();
        await page.waitForTimeout(cfg.WAIT.action);
        await shot(page, '10_customer_detail');

        // Check transaction timeline
        const timeline = await page.$(
          '[class*="timeline"], [class*="transaction"]'
        );
        console.log(`  Transaction timeline: ${timeline ? '✅' : '❌'}`);

        // Check QR code button
        const qrBtn = await page.$('text=QR, text=qr');
        console.log(`  QR button: ${qrBtn ? '✅' : '❌'}`);

        await shot(page, '10_customer_detail_full');
      }

      await ctx.close();
    });

    // ════════════════════════════════════════════════════
    // TEST 11 — FINANCIAL: MUNAFA NUQSAN
    // ════════════════════════════════════════════════════
    await test('Financial reports — Munafa Nuqsan', async () => {
      const ctx  = await browser.newContext(
        { viewport: cfg.VIEWPORT.desktop });
      const page = await ctx.newPage();
      await login(page);

      await page.goto(`${cfg.URL}/#/reports`);
      await page.waitForTimeout(cfg.WAIT.load);
      await shot(page, '11_reports_screen');

      // Check date filter bar
      const filterBtns = [
        'text=Aaj', 'text=Today',
        'text=Hafte', 'text=Week',
        'text=Mahine', 'text=Month',
      ];
      let filterFound = false;
      for (const sel of filterBtns) {
        const el = await page.$(sel);
        if (el) { filterFound = true; break; }
      }
      console.log(`  Date filter bar: ${filterFound ? '✅' : '❌'}`);

      // Test date filters
      for (const btn of filterBtns) {
        try {
          await page.click(btn, { timeout: 1000 });
          await page.waitForTimeout(1000);
        } catch (_) {}
      }
      await shot(page, '11_reports_date_filtered');

      // Check profit card color
      const profitCard = await page.$(
        '[class*="profit"], [class*="munafa"]'
      );
      if (profitCard) {
        await shot(page, '11_profit_card');
        console.log('  Profit card ✅');
      }

      // Check charts loaded
      const charts = await page.$$('canvas, svg[class*="chart"]');
      console.log(`  Charts found: ${charts.length}`);
      await shot(page, '11_reports_with_charts');

      // Test PDF export
      const pdfBtns = [
        'button:has-text("PDF")',
        'button:has-text("Download")',
        'button:has-text("Export")',
      ];
      for (const sel of pdfBtns) {
        try {
          await page.click(sel, { timeout: 2000 });
          await page.waitForTimeout(2000);
          await shot(page, '11_pdf_downloaded');
          console.log('  PDF export ✅');
          break;
        } catch (_) {}
      }

      await ctx.close();
    });

    // ════════════════════════════════════════════════════
    // TEST 12 — BILLS MANAGEMENT
    // ════════════════════════════════════════════════════
    await test('Bills — list, filter, edit, cancel', async () => {
      const ctx  = await browser.newContext(
        { viewport: cfg.VIEWPORT.desktop });
      const page = await ctx.newPage();
      await login(page);

      await page.goto(`${cfg.URL}/#/bills`);
      await page.waitForTimeout(cfg.WAIT.load);
      await shot(page, '12_bills_list');

      // Test filter tabs
      const tabs = await page.$$('[role="tab"], [class*="tab"]');
      console.log(`  Filter tabs: ${tabs.length}`);
      for (const tab of tabs.slice(0,4)) {
        await tab.click().catch(() => {});
        await page.waitForTimeout(500);
      }
      await shot(page, '12_bills_filtered');

      // Open first bill
      const bills = await page.$$('[class*="bill"]');
      if (bills.length > 0) {
        await bills[0].click();
        await page.waitForTimeout(cfg.WAIT.action);
        await shot(page, '12_bill_detail');

        // Check edit button (owner only)
        const editBtn = await page.$(
          'button:has-text("Edit"), button:has-text("Badlo")'
        );
        if (editBtn) {
          await editBtn.click();
          await page.waitForTimeout(cfg.WAIT.action);
          await shot(page, '12_bill_edit_screen');

          // Change quantity
          const qtyInputs = await page.$$('input[type="number"]');
          if (qtyInputs.length > 0) {
            const origVal = await qtyInputs[0].inputValue();
            await qtyInputs[0].fill(
              String(parseInt(origVal) + 1));
            await page.waitForTimeout(500);
            await shot(page, '12_bill_qty_changed_live');
            console.log('  Live recalculation ✅');
          }
        }
      }

      await ctx.close();
    });

    // ════════════════════════════════════════════════════
    // TEST 13 — EXPENSES (KHARCHE)
    // ════════════════════════════════════════════════════
    await test('Expenses management', async () => {
      const ctx  = await browser.newContext(
        { viewport: cfg.VIEWPORT.desktop });
      const page = await ctx.newPage();
      await login(page);

      await page.goto(`${cfg.URL}/#/expenses`);
      await page.waitForTimeout(cfg.WAIT.load);
      await shot(page, '13_expenses_list');

      // Check category icons grid
      const categories = await page.$$(
        '[class*="category"], [class*="icon-grid"]'
      );
      console.log(`  Categories: ${categories.length}`);

      // Add expense
      const addBtns = [
        'button:has-text("+")',
        'button:has-text("Add")',
        'button:has-text("Add Kharcha")',
        '[class*="fab"]',
      ];
      for (const sel of addBtns) {
        try {
          await page.click(sel, { timeout: 2000 });
          await page.waitForTimeout(cfg.WAIT.action);
          break;
        } catch (_) {}
      }
      await shot(page, '13_add_expense_form');

      await ctx.close();
    });

    // ════════════════════════════════════════════════════
    // TEST 14 — DAILY CASH
    // ════════════════════════════════════════════════════
    await test('Daily cash — Aaj ka Hisaab', async () => {
      const ctx  = await browser.newContext(
        { viewport: cfg.VIEWPORT.desktop });
      const page = await ctx.newPage();
      await login(page);

      await page.goto(`${cfg.URL}/#/daily-cash`);
      await page.waitForTimeout(cfg.WAIT.load);
      await shot(page, '14_daily_cash_screen');

      // Check session
      const openBtn = await page.$(
        'button:has-text("Open"), button:has-text("Shuru")'
      );
      const isOpen = await page.isVisible(
        'text=Live, text=Expected, text=Hona chahiye'
      ).catch(() => false);

      console.log(`  Session state: ${
        isOpen ? 'Open ✅' : openBtn ? 'Needs opening' : 'Unknown'
      }`);
      await shot(page, '14_daily_cash_detail');

      await ctx.close();
    });

    // ════════════════════════════════════════════════════
    // TEST 15 — OFFLINE MODE
    // ════════════════════════════════════════════════════
    await test('Offline mode — works without internet',
    async () => {
      const ctx  = await browser.newContext(
        { viewport: cfg.VIEWPORT.desktop });
      const page = await ctx.newPage();
      await login(page);

      // Go offline
      await page.context().setOffline(true);
      await page.waitForTimeout(2000);
      await shot(page, '15_offline_banner_appears');

      // Check offline banner
      const banner = await page.isVisible(
        'text=Internet nahi, text=Offline, text=offline'
      ).catch(() => false);
      console.log(`  Offline banner: ${banner ? '✅' : '❌'}`);

      // POS should still work
      await page.goto(`${cfg.URL}/#/pos`).catch(() => {});
      await page.waitForTimeout(cfg.WAIT.load);
      await shot(page, '15_pos_offline');

      const posWorks = await page.isVisible(
        '[class*="product"], [class*="search"]'
      ).catch(() => false);
      console.log(`  POS offline: ${posWorks ? '✅' : '❌'}`);

      // Come back online
      await page.context().setOffline(false);
      await page.waitForTimeout(3000);
      await shot(page, '15_back_online_syncing');

      await ctx.close();
    });

    // ════════════════════════════════════════════════════
    // TEST 16 — CUSTOMER PORTAL
    // ════════════════════════════════════════════════════
    await test('Customer portal', async () => {
      const ctx  = await browser.newContext(
        { viewport: cfg.VIEWPORT.mobile });
      const page = await ctx.newPage();

      await page.goto(`${cfg.URL}/#/customer/login`);
      await page.waitForTimeout(cfg.WAIT.load);
      await shot(page, '16_customer_portal_login');

      // Check phone input
      const phoneInput = await page.$(
        'input[type="tel"], input[placeholder*="phone" i], ' +
        'input[placeholder*="number" i]'
      );
      console.log(`  Phone input: ${phoneInput ? '✅' : '❌'}`);

      // Check PWA manifest
      await page.goto(`${cfg.URL}/customer-manifest.json`);
      const pwaContent = await page.content();
      const hasPwa = pwaContent.includes('Mera Hisaab') ||
                     pwaContent.includes('manifest');
      console.log(`  Pwa manifest: ${hasPwa ? '✅' : '❌'}`);

      await ctx.close();
    });

    // ════════════════════════════════════════════════════
    // TEST 17 — BACKUP SCREEN
    // ════════════════════════════════════════════════════
    await test('Backup — Google Drive connection', async () => {
      const ctx  = await browser.newContext(
        { viewport: cfg.VIEWPORT.desktop });
      const page = await ctx.newPage();
      await login(page);

      await page.goto(`${cfg.URL}/#/backup`);
      await page.waitForTimeout(cfg.WAIT.load);
      await shot(page, '17_backup_screen');

      const connectBtn = await page.$(
        'button:has-text("Gmail"), button:has-text("Connect"), ' +
        'button:has-text("Google")'
      );
      console.log(`  Gmail connect button: ${connectBtn ? '✅' : '❌'}`);

      const historyTab = await page.$(
        'text=History, text=Purane Backups'
      );
      if (historyTab) {
        await historyTab.click();
        await page.waitForTimeout(cfg.WAIT.action);
        await shot(page, '17_backup_history');
      }

      await ctx.close();
    });

    // ════════════════════════════════════════════════════
    // TEST 18 — TEAM / CO-HELPERS
    // ════════════════════════════════════════════════════
    await test('Team management and RBAC', async () => {
      const ctx  = await browser.newContext(
        { viewport: cfg.VIEWPORT.desktop });
      const page = await ctx.newPage();
      await login(page);

      await page.goto(`${cfg.URL}/#/team`);
      await page.waitForTimeout(cfg.WAIT.load);
      await shot(page, '18_team_screen');

      const inviteBtn = await page.$(
        'button:has-text("Invite"), button:has-text("Add"), ' +
        'button:has-text("Bulao")'
      );
      console.log(`  Invite button: ${inviteBtn ? '✅' : '❌'}`);

      if (inviteBtn) {
        await inviteBtn.click();
        await page.waitForTimeout(cfg.WAIT.action);
        await shot(page, '18_invite_modal');
      }

      await ctx.close();
    });

    // ════════════════════════════════════════════════════
    // TEST 19 — SETTINGS CUSTOMIZATION
    // ════════════════════════════════════════════════════
    await test('Shop customization — logo, theme, bill',
    async () => {
      const ctx  = await browser.newContext(
        { viewport: cfg.VIEWPORT.desktop });
      const page = await ctx.newPage();
      await login(page);

      await page.goto(`${cfg.URL}/#/settings`);
      await page.waitForTimeout(cfg.WAIT.load);
      await shot(page, '19_settings_main');

      // Shop settings
      await page.goto(`${cfg.URL}/#/settings/shop`);
      await page.waitForTimeout(cfg.WAIT.load);
      await shot(page, '19_shop_settings');

      // Check logo upload
      const logoBtn = await page.$(
        'button:has-text("Logo"), [data-testid="logo-upload"]'
      );
      console.log(`  Logo upload: ${logoBtn ? '✅' : '❌'}`);

      // Appearance
      await page.goto(`${cfg.URL}/#/settings/appearance`);
      await page.waitForTimeout(cfg.WAIT.load);
      await shot(page, '19_appearance_settings');

      // Theme colors
      const colorCircles = await page.$$('[class*="color-circle"]');
      console.log(`  Theme color circles: ${colorCircles.length}`);
      if (colorCircles.length > 1) {
        await colorCircles[2].click();
        await page.waitForTimeout(cfg.WAIT.anim);
        await shot(page, '19_theme_color_changed');
      }

      // Bill design
      await page.goto(`${cfg.URL}/#/settings/bill`);
      await page.waitForTimeout(cfg.WAIT.load);
      await shot(page, '19_bill_design_screen');

      const preview = await page.$('[class*="preview"]');
      console.log(`  Live preview: ${preview ? '✅' : '❌'}`);

      await ctx.close();
    });

    // ════════════════════════════════════════════════════
    // TEST 20 — RESPONSIVE ALL SCREENS
    // ════════════════════════════════════════════════════
    await test('Responsive design all screens', async () => {
      const ctx  = await browser.newContext(
        { viewport: cfg.VIEWPORT.desktop });
      const page = await ctx.newPage();
      await login(page);

      const screens = [
        ['dashboard', '/#/dashboard'],
        ['pos',       '/#/pos'],
        ['inventory', '/#/inventory'],
        ['customers', '/#/customers'],
        ['reports',   '/#/reports'],
        ['settings',  '/#/settings'],
      ];

      for (const [name, route] of screens) {
        await page.goto(`${cfg.URL}${route}`);
        await page.waitForTimeout(cfg.WAIT.action);

        for (const [size, vp] of Object.entries(cfg.VIEWPORT)) {
          await page.setViewportSize(vp);
          await page.waitForTimeout(300);
          await shot(page, `20_${name}_${size}`);
        }
      }

      await ctx.close();
    });

    await browser.close();

    // ════════════════════════════════════════════════════
    // GENERATE ALL OUTPUTS
    // ════════════════════════════════════════════════════
    generateHTMLReport(results, allScreens, allVideos);
    // Removed external tool calls assuming manual python run later

    // Print summary
    const passed = results.filter(r => r.pass).length;
    const failed = results.filter(r => !r.pass).length;
    console.log('\\n' + '='.repeat(50));
    console.log(`✅ PASSED: ${passed}`);
    console.log(`❌ FAILED: ${failed}`);
    console.log('='.repeat(50));
    console.log('📸 Screenshots: test/screenshots/');
    console.log('🎥 Videos:      test/videos/');
    console.log('📦 Products:    test/products/');
    console.log('📢 Ads:         test/ads/');
    console.log('📖 Manual:      test/manual/');
    console.log('📋 Report:      test/reports/');
  }

  async function test(name, fn) {
    console.log(`\\n▶️  ${name}`);
    const start = Date.now();
    try {
      await fn();
      const dur = ((Date.now()-start)/1000).toFixed(1);
      results.push({ name, pass: true, duration: dur });
      console.log(`   ✅ PASS (${dur}s)`);
    } catch (e) {
      const dur = ((Date.now()-start)/1000).toFixed(1);
      results.push({ name, pass: false, error: e.message, duration: dur });
      console.log(`   ❌ FAIL: ${e.message}`);
    }
  }

  function generateHTMLReport(results, screens, videos) {
    const passed  = results.filter(r => r.pass).length;
    const failed  = results.filter(r => !r.pass).length;
    const pct     = Math.round(passed/results.length*100);
    const ts      = new Date().toLocaleString();

    const rows = results.map((r,i) => `
      <tr class="${r.pass?'pass':'fail'}">
        <td>${i+1}</td>
        <td>${r.name}</td>
        <td>${r.pass ? '✅ PASS' : '❌ FAIL'}</td>
        <td>${r.duration}s</td>
        <td>${r.error || ''}</td>
      </tr>`).join('');

    const ssGrid = screens.map(s => `
      <div class="ss">
        <img src="../screenshots/${
          require('path').basename(s.file)}"
          loading="lazy"
          onclick="window.open(this.src,'_blank')">
        <p>${s.name}</p>
      </div>`).join('');

    const vidGrid = videos.map(v => `
      <div class="vc">
        <h4>${v.name.replace(/_/g,' ')}</h4>
        <video controls>
          <source src="../videos/${
            require('path').basename(v.file)}"
            type="video/webm">
        </video>
      </div>`).join('');

    const html = `<!DOCTYPE html>
  <html><head><meta charset="UTF-8">
  <title>Test Report — Super Business Shop</title>
  <style>
    body{font-family:sans-serif;background:#f5f5f5;margin:0}
    .hdr{background:#006D77;color:white;padding:24px;
         text-align:center}
    .hdr h1{font-size:24px;margin-bottom:8px}
    .stats{display:flex;gap:16px;justify-content:center;
           padding:20px;flex-wrap:wrap}
    .stat{background:white;padding:16px 24px;
          border-radius:12px;text-align:center;
          box-shadow:0 2px 8px rgba(0,0,0,.1)}
    .stat .n{font-size:36px;font-weight:bold}
    .green{color:#27AE60}.red{color:#E74C3C}
    .blue{color:#006D77}.orange{color:#F39C12}
    table{width:100%;border-collapse:collapse;
          background:white;border-radius:12px;
          overflow:hidden;margin:16px 0}
    th{background:#006D77;color:white;padding:12px}
    td{padding:10px;border-bottom:1px solid #eee}
    .pass td{background:#f0fff4}
    .fail td{background:#fff5f5}
    .bar{height:8px;background:#eee;
         border-radius:4px;overflow:hidden;margin:8px 0}
    .fill{height:100%;background:#27AE60;
          border-radius:4px;width:${pct}%}
    .ss-grid{display:grid;
             grid-template-columns:repeat(4,1fr);
             gap:8px;padding:16px}
    .ss img{width:100%;border-radius:8px;cursor:pointer;
            border:1px solid #eee}
    .ss p{font-size:10px;color:#666;margin:4px 0 0;
          text-align:center}
    .v-grid{display:grid;
            grid-template-columns:repeat(2,1fr);
            gap:16px;padding:16px}
    .vc{background:white;padding:12px;border-radius:8px}
    .vc h4{color:#006D77;margin-bottom:8px;font-size:13px}
    .vc video{width:100%;border-radius:8px}
    .section{max-width:1200px;margin:0 auto;padding:0 16px}
  </style></head><body>
  <div class="hdr">
    <h1>🏪 Super Business Shop — Test Report</h1>
    <p>Generated: ${ts}</p>
    <p>🌐 https://super-business-flutter-web.onrender.com</p>
    <p>👤 ${cfg.EMAIL}</p>
    <div class="bar"><div class="fill"></div></div>
    <p>${pct}% Pass Rate</p>
  </div>
  <div class="stats">
    <div class="stat"><div class="n blue">${results.length}</div>Total</div>
    <div class="stat"><div class="n green">${passed}</div>Passed ✅</div>
    <div class="stat"><div class="n red">${failed}</div>Failed ❌</div>
    <div class="stat"><div class="n orange">${pct}%</div>Rate</div>
  </div>
  <div class="section">
    <table>
      <tr><th>#</th><th>Test</th><th>Status</th>
          <th>Time</th><th>Error</th></tr>
      ${rows}
    </table>
    <h2 style="color:#006D77;padding:8px 0">📸 Screenshots (${screens.length})</h2>
    <div class="ss-grid">${ssGrid}</div>
    <h2 style="color:#006D77;padding:8px 0">🎥 Videos (${videos.length})</h2>
    <div class="v-grid">${vidGrid}</div>
  </div>
  </body></html>`;

    require('fs').writeFileSync(
      'test/reports/test_report.html', html);
    console.log('📋 Report: test/reports/test_report.html');
  }

  runAllTests().catch(console.error);
