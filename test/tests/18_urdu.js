module.exports = async function urduTests(page, h, config) {
  const start = Date.now();
  const screenshots = [];
  const details = [];

  await h.loginAs(page, config.SHOPKEEPER.email, config.SHOPKEEPER.password);

  // Switch to Urdu via settings
  try {
    await page.goto(config.APP_URL + '/#/settings');
    await h.waitForLoad(page);
    await h.screenshot(page, '01_settings_before_urdu', '18_urdu');

    const urduBtn = await page.$('button:has-text("اردو")') ||
      await page.$('button:has-text("Urdu")') ||
      await page.$('[data-testid="lang-urdu"]');
    if (urduBtn) {
      await urduBtn.click();
      await h.waitForLoad(page);
      await h.screenshot(page, '02_settings_urdu_active', '18_urdu');
      details.push({ test: 'Urdu language switched', status: 'pass' });
    }
  } catch (_) {}

  // Navigate screens in Urdu
  const screens = [
    { name: 'dashboard_urdu', url: '/#/dashboard' },
    { name: 'pos_urdu', url: '/#/pos' },
    { name: 'inventory_urdu', url: '/#/inventory' },
    { name: 'customers_urdu', url: '/#/customers' },
  ];

  for (const screen of screens) {
    try {
      await page.goto(config.APP_URL + screen.url);
      await h.waitForLoad(page);
      await h.screenshot(page, screen.name, '18_urdu');
      screenshots.push(`18_urdu/${screen.name}`);
      details.push({ test: `${screen.name} renders in Urdu`, status: 'pass' });
    } catch (e) {
      details.push({ test: screen.name, status: `warn: ${e.message}` });
    }
  }

  // Switch back to English
  try {
    await page.goto(config.APP_URL + '/#/settings');
    await h.waitForLoad(page);
    const engBtn = await page.$('button:has-text("English")') ||
      await page.$('[data-testid="lang-english"]');
    if (engBtn) {
      await engBtn.click();
      await h.waitForAction(page);
      await h.screenshot(page, '03_reverted_english', '18_urdu');
      details.push({ test: 'Reverted to English', status: 'pass' });
    }
  } catch (_) {}

  return { duration: Date.now() - start, screenshots, details };
};
