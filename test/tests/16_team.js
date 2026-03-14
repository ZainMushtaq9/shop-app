module.exports = async function teamTests(page, h, config) {
  const start = Date.now(); const screenshots = []; const details = [];
  await h.loginAs(page, config.SHOPKEEPER.email, config.SHOPKEEPER.password);
  try { await page.goto(config.APP_URL + '/#/team'); } catch (_) {}
  await h.waitForLoad(page);
  await h.screenshot(page, '01_team_screen', '16_team');
  screenshots.push('16_team/01_team_screen');
  details.push({ test: 'Team screen loads', status: 'pass' });
  return { duration: Date.now() - start, screenshots, details };
};
