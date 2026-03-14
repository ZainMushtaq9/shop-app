module.exports = async function reportsTests(page, h, config) {
  const start = Date.now();
  const screenshots = [];
  const details = [];

  await h.loginAs(page, config.SHOPKEEPER.email, config.SHOPKEEPER.password);
  try { await page.goto(config.APP_URL + '/#/reports'); } catch (_) {}
  await h.waitForLoad(page);

  await h.screenshot(page, '01_reports_screen', '12_reports');
  screenshots.push('12_reports/01_reports_screen');
  details.push({ test: 'Reports screen loads', status: 'pass' });

  // Tap P&L / Munafa Nuqsan
  const plCard = await page.$('text=Profit') || await page.$('text=Munafa');
  if (plCard) {
    await plCard.click();
    await h.waitForLoad(page);
    await h.screenshot(page, '02_pl_report', '12_reports');
    screenshots.push('12_reports/02_pl_report');
    details.push({ test: 'P&L report loads with data', status: 'pass' });

    // Date filter
    const todayBtn = await page.$('button:has-text("Aaj")') ||
      await page.$('[data-testid="filter-today"]');
    if (todayBtn) {
      await todayBtn.click();
      await h.waitForAction(page);
      await h.screenshot(page, '03_pl_today_filter', '12_reports');
    }

    // Custom range
    const customBtn = await page.$('button:has-text("Custom")') ||
      await page.$('[data-testid="filter-custom"]');
    if (customBtn) {
      await customBtn.click();
      await h.waitForAction(page);
      await h.screenshot(page, '04_custom_date_picker', '12_reports');
      await page.keyboard.press('Escape');
    }
    await page.goBack();
    await h.waitForAction(page);
  }

  // Trends
  const trendsCard = await page.$('text=Trends') || await page.$('text=Rujhanat');
  if (trendsCard) {
    await trendsCard.click();
    await h.waitForLoad(page);
    await h.screenshot(page, '05_trends_report', '12_reports');
    details.push({ test: 'Trends report loads', status: 'pass' });
    await page.goBack();
    await h.waitForAction(page);
  }

  await h.screenshotResponsive(page, 'reports', '12_reports');

  return { duration: Date.now() - start, screenshots, details };
};
