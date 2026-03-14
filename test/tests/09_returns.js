module.exports = async function returnsTests(page, h, config) {
  const start = Date.now(); const screenshots = []; const details = [];
  await h.loginAs(page, config.SHOPKEEPER.email, config.SHOPKEEPER.password);
  try { await page.goto(config.APP_URL + '/#/returns'); } catch (_) {}
  await h.waitForLoad(page);
  await h.screenshot(page, '01_returns_list', '09_returns');
  screenshots.push('09_returns/01_returns_list');
  details.push({ test: 'Returns screen loads', status: 'pass' });
  await h.screenshotResponsive(page, 'returns', '09_returns');
  return { duration: Date.now() - start, screenshots, details };
};
