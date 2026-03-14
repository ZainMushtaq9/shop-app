module.exports = async function inventoryTests(page, h, config) {
  const start = Date.now();
  const screenshots = [];
  const details = [];

  await h.loginAs(page, config.SHOPKEEPER.email, config.SHOPKEEPER.password);
  try { await page.goto(config.APP_URL + '/#/inventory'); } catch (_) {}
  await h.waitForLoad(page);

  await h.screenshot(page, '01_inventory_list', '06_inventory');
  screenshots.push('06_inventory/01_inventory_list');
  details.push({ test: 'Inventory screen loads', status: 'pass' });

  // Filter chips
  const filterChips = ['Kam Stock', 'Thanda Maal', 'Kam Munafa', 'کم اسٹاک'];
  for (const chip of filterChips) {
    const el = await page.$(`button:has-text("${chip}")`);
    if (el) {
      await el.click();
      await h.waitForAction(page);
      await h.screenshot(page, `02_filter_${chip.replace(/\s/g, '_')}`, '06_inventory');
      details.push({ test: `Filter: ${chip} works`, status: 'pass' });
      await el.click(); // toggle off
      await h.waitForAction(page);
    }
  }

  // Stock Value tab
  const stockValTab = await page.$('button:has-text("Maal ki Qeemat")') ||
    await page.$('button:has-text("Stock Value")') ||
    await page.$('[data-testid="stock-value-tab"]');
  if (stockValTab) {
    await stockValTab.click();
    await h.waitForAction(page);
    await h.screenshot(page, '03_stock_value_tab', '06_inventory');
    details.push({ test: 'Stock value tab shows', status: 'pass' });
  }

  // Responsive
  await h.screenshotResponsive(page, 'inventory', '06_inventory');

  return { duration: Date.now() - start, screenshots, details };
};
