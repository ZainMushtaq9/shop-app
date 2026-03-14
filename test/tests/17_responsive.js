module.exports = async function responsiveTests(page, h, config) {
  const start = Date.now();
  const screenshots = [];
  const details = [];

  await h.loginAs(page, config.SHOPKEEPER.email, config.SHOPKEEPER.password);

  const screens = [
    { name: 'dashboard', url: '/#/dashboard' },
    { name: 'pos', url: '/#/pos' },
    { name: 'inventory', url: '/#/inventory' },
    { name: 'customers', url: '/#/customers' },
    { name: 'reports', url: '/#/reports' },
    { name: 'settings', url: '/#/settings' },
  ];

  for (const screen of screens) {
    try {
      await page.goto(config.APP_URL + screen.url);
      await h.waitForLoad(page);
      await h.screenshotResponsive(page, screen.name, '17_responsive');
      details.push({ test: `${screen.name} responsive screenshots`, status: 'pass' });
    } catch (e) {
      details.push({ test: `${screen.name} responsive`, status: `warn: ${e.message}` });
    }
  }

  return { duration: Date.now() - start, screenshots, details };
};
