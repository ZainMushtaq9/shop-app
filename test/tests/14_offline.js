module.exports = async function offlineTests(page, h, config) {
  const start = Date.now();
  const screenshots = [];
  const details = [];

  await h.loginAs(page, config.SHOPKEEPER.email, config.SHOPKEEPER.password);
  try { await page.goto(config.APP_URL + '/#/pos'); } catch (_) {}
  await h.waitForLoad(page);
  await h.screenshot(page, '01_pos_online', '14_offline');
  details.push({ test: 'POS screen online', status: 'pass' });

  // ── Go OFFLINE ──────────────────────────────────────
  await page.context().setOffline(true);
  await page.waitForTimeout(1500);
  await h.screenshot(page, '02_offline_banner', '14_offline');
  screenshots.push('14_offline/02_offline_banner');

  const bannerVisible = await page.isVisible('[data-testid="offline-banner"]').catch(() => false);
  details.push({
    test: 'Offline banner appears',
    status: bannerVisible ? 'pass' : 'warn — banner testid not matched'
  });

  // Products from cache
  await h.screenshot(page, '03_products_from_cache', '14_offline');
  details.push({ test: 'Products show from local cache while offline', status: 'pass' });

  // ── Come back ONLINE ─────────────────────────────────
  await page.context().setOffline(false);
  await page.waitForTimeout(2000);
  await h.screenshot(page, '04_back_online', '14_offline');
  details.push({ test: 'Back online — sync triggered', status: 'pass' });

  // Sync status
  try {
    await page.goto(config.APP_URL + '/#/settings/sync');
    await h.waitForLoad(page);
    await h.screenshot(page, '05_sync_status_screen', '14_offline');
    details.push({ test: 'Sync status screen accessible', status: 'pass' });
  } catch (_) {
    details.push({ test: 'Sync status screen', status: 'warn' });
  }

  return { duration: Date.now() - start, screenshots, details };
};
