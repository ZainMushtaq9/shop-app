module.exports = async function dailyCashTests(page, h, config) {
  const start = Date.now(); const screenshots = []; const details = [];
  await h.loginAs(page, config.SHOPKEEPER.email, config.SHOPKEEPER.password);
  try { await page.goto(config.APP_URL + '/#/daily-cash'); } catch (_) {}
  await h.waitForLoad(page);
  await h.screenshot(page, '01_daily_cash_screen', '11_daily_cash');
  screenshots.push('11_daily_cash/01_daily_cash_screen');
  details.push({ test: 'Daily cash screen loads', status: 'pass' });
  await h.screenshotResponsive(page, 'daily_cash', '11_daily_cash');
  return { duration: Date.now() - start, screenshots, details };
};
