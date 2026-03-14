  const { chromium } = require('playwright');
  const cfg = require('./test_config');

  async function verifyProd() {
    console.log('🔍 Verifying production...');
    const browser = await chromium.launch({ headless: true });
    const page    = await browser.newPage();
    const checks  = [];

    // 1. Site loads
    const res = await page.goto(cfg.URL,
      { waitUntil: 'networkidle', timeout: 30000 });
    checks.push({ name: 'Site loads (200)',
      pass: res.status() === 200 });

    await page.waitForTimeout(5000);

    // 2. Login works
    try {
      await page.fill('input[type="email"]', cfg.EMAIL);
      await page.fill('input[type="password"]', cfg.PASSWORD);
      await page.keyboard.press('Enter');
      await page.waitForTimeout(5000);
      const loggedIn = !page.url().includes('login');
      checks.push({ name: 'Login works', pass: loggedIn });
    } catch (e) {
      checks.push({ name: 'Login works', pass: false,
        error: e.message });
    }

    // 3. Routes work (no 404)
    const routes = [
      '/#/dashboard', '/#/pos', '/#/inventory',
      '/#/customers', '/#/reports', '/#/settings',
      '/#/customer/login',
    ];
    for (const r of routes) {
      try {
        await page.goto(`${cfg.URL}${r}`,
          { timeout: 10000 });
        await page.waitForTimeout(2000);
        const title = await page.title();
        checks.push({
          name: `Route ${r}`,
          pass: !title.includes('404') &&
                !title.includes('Not Found'),
        });
      } catch (e) {
        checks.push({ name: `Route ${r}`,
          pass: false, error: e.message });
      }
    }

    // 4. Favicon
    await page.goto(cfg.URL);
    await page.waitForTimeout(3000);
    const favicon = await page.$('link#favicon');
    checks.push({ name: 'Favicon element exists',
      pass: !!favicon });

    // 5. No default blue
    const html = await page.content();
    checks.push({
      name: 'No default Material blue',
      pass: !html.includes('rgb(33, 150, 243)') &&
            !html.includes('#2196F3'),
    });

    // 6. Customer portal accessible
    await page.goto(`${cfg.URL}/#/customer/login`);
    await page.waitForTimeout(3000);
    const portalEl = await page.$('input[type="tel"]');
    checks.push({ name: 'Customer portal accessible',
      pass: !!portalEl });

    await browser.close();

    // Print results
    console.log('\\n📊 Production Verification:');
    console.log('='.repeat(40));
    let passed = 0;
    for (const c of checks) {
      console.log(`${c.pass ? '✅' : '❌'} ${c.name}`);
      if (!c.pass && c.error) {
        console.log(`   Error: ${c.error}`);
      }
      if (c.pass) passed++;
    }
    console.log('='.repeat(40));
    console.log(`${passed}/${checks.length} checks passed`);

    if (passed === checks.length) {
      console.log('🎉 PRODUCTION VERIFIED — All good!');
    } else {
      console.log('⚠️  Some checks failed — review needed');
    }
  }

  verifyProd().catch(console.error);
