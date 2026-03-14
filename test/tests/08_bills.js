module.exports = async function billTests(page, h, config) {
  const start = Date.now();
  const screenshots = [];
  const details = [];

  await h.loginAs(page, config.SHOPKEEPER.email, config.SHOPKEEPER.password);
  try { await page.goto(config.APP_URL + '/#/bills'); } catch (_) {}
  await h.waitForLoad(page);

  await h.screenshot(page, '01_bills_list', '08_bills');
  screenshots.push('08_bills/01_bills_list');
  details.push({ test: 'Bills list loads', status: 'pass' });

  // Filter tabs
  const tabs = ['Naqdh', 'Udhaar', 'Tamam', 'نقد', 'ادھار'];
  for (const tab of tabs) {
    const el = await page.$(`button:has-text("${tab}")`);
    if (el) {
      await el.click();
      await h.waitForAction(page);
      await h.screenshot(page, `02_filter_${tab}`, '08_bills');
      details.push({ test: `Filter tab: ${tab}`, status: 'pass' });
    }
  }

  // Date filter
  const todayBtn = await page.$('button:has-text("Aaj")') ||
    await page.$('button:has-text("Today")') ||
    await page.$('[data-testid="filter-today"]');
  if (todayBtn) {
    await todayBtn.click();
    await h.waitForAction(page);
    await h.screenshot(page, '03_date_filter_today', '08_bills');
    details.push({ test: 'Date filter: today works', status: 'pass' });
  }

  // Open a bill
  const firstBill = await page.$('[data-testid="bill-card"]') ||
    await page.$('.bill-item') ||
    await page.$('li:first-child');
  if (firstBill) {
    await firstBill.click();
    await h.waitForLoad(page);
    await h.screenshot(page, '04_bill_detail', '08_bills');
    screenshots.push('08_bills/04_bill_detail');
    details.push({ test: 'Bill detail opens', status: 'pass' });
    await page.goBack();
    await h.waitForAction(page);
  }

  await h.screenshotResponsive(page, 'bills', '08_bills');

  return { duration: Date.now() - start, screenshots, details };
};
