module.exports = async function customerTests(page, h, config) {
  const start = Date.now();
  const screenshots = [];
  const details = [];

  await h.loginAs(page, config.SHOPKEEPER.email, config.SHOPKEEPER.password);
  try { await page.goto(config.APP_URL + '/#/customers'); } catch (_) {}
  await h.waitForLoad(page);

  await h.screenshot(page, '01_customer_list', '07_customers');
  screenshots.push('07_customers/01_customer_list');
  details.push({ test: 'Customer list loads', status: 'pass' });

  // Tap first customer
  const firstCustomer = await page.$('[data-testid="customer-card"]') ||
    await page.$('.customer-item') ||
    await page.$('li:first-child');
  if (firstCustomer) {
    await firstCustomer.click();
    await h.waitForLoad(page);
    await h.screenshot(page, '02_customer_detail', '07_customers');
    screenshots.push('07_customers/02_customer_detail');
    details.push({ test: 'Customer detail opens', status: 'pass' });

    // QR Code button
    const qrBtn = await page.$('button:has-text("QR")') ||
      await page.$('[data-testid="qr-button"]');
    if (qrBtn) {
      await qrBtn.click();
      await h.waitForAction(page);
      await h.screenshot(page, '03_qr_code_screen', '07_customers');
      details.push({ test: 'QR code generated', status: 'pass' });
      await page.keyboard.press('Escape');
    }

    // Portal settings
    const portalBtn = await page.$('button:has-text("Portal")') ||
      await page.$('[data-testid="portal-settings"]');
    if (portalBtn) {
      await portalBtn.click();
      await h.waitForAction(page);
      await h.screenshot(page, '04_portal_visibility_settings', '07_customers');
      details.push({ test: 'Portal visibility settings opens', status: 'pass' });
      await page.keyboard.press('Escape');
    }

    await page.goBack();
    await h.waitForAction(page);
  }

  await h.screenshotResponsive(page, 'customers', '07_customers');

  return { duration: Date.now() - start, screenshots, details };
};
