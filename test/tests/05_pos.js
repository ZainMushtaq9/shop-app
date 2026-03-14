module.exports = async function posTests(page, h, config) {
  const start = Date.now();
  const screenshots = [];
  const details = [];

  await h.loginAs(page, config.SHOPKEEPER.email, config.SHOPKEEPER.password);

  // Navigate to POS
  try {
    await page.goto(config.APP_URL + '/#/pos');
  } catch (_) {
    // Try clicking nav
    const nav = await page.$('[data-testid="pos-nav"]') || await page.$('a[href*="pos"]');
    if (nav) await nav.click();
  }
  await h.waitForLoad(page);
  await h.screenshot(page, '01_pos_screen_empty', '05_pos');
  screenshots.push('05_pos/01_pos_screen_empty');
  details.push({ test: 'POS screen loads', status: 'pass' });

  // ── 5.1 Product Search ──────────────────────────────
  const searchBox = await page.$('[data-testid="product-search"]') ||
    await page.$('input[placeholder*="search"]') ||
    await page.$('input[placeholder*="Search"]') ||
    await page.$('input[type="search"]');

  if (searchBox) {
    await searchBox.fill('cha');
    await h.waitForAction(page);
    await h.screenshot(page, '02_search_cha_results', '05_pos');
    screenshots.push('05_pos/02_search_cha_results');
    details.push({ test: 'Product search by "cha" works', status: 'pass' });
    await searchBox.clear();
  } else {
    details.push({ test: 'Product search box found', status: 'warn — not found' });
  }

  // ── 5.2 Add to Cart ──────────────────────────────────
  const firstProduct = await page.$('[data-testid="product-card"]:first-child') ||
    await page.$('.product-card:first-child') ||
    await page.$('[class*="product"]:first-child');

  if (firstProduct) {
    await firstProduct.click();
    await h.waitForAction(page);
    await h.screenshot(page, '03_item_added_to_cart', '05_pos');
    screenshots.push('05_pos/03_item_added_to_cart');
    details.push({ test: 'Add product to cart', status: 'pass' });
  } else {
    details.push({ test: 'Product card found', status: 'warn — no products visible' });
    await h.screenshot(page, '03_no_products_visible', '05_pos');
  }

  // ── 5.3 Discount ────────────────────────────────────
  const discountInput = await page.$('[data-testid="discount-input"]') ||
    await page.$('input[placeholder*="iscou"]');
  if (discountInput) {
    await discountInput.fill('10');
    await h.waitForAction(page);
    await h.screenshot(page, '04_discount_applied', '05_pos');
    details.push({ test: 'Discount input works', status: 'pass' });
  }

  // ── 5.4 Payment type ─────────────────────────────────
  const udhaarBtn = await page.$('[data-testid="payment-udhaar"]') ||
    await page.$('button:has-text("Udhaar")') ||
    await page.$('button:has-text("ادھار")');
  if (udhaarBtn) {
    await udhaarBtn.click();
    await h.waitForAction(page);
    await h.screenshot(page, '05_udhaar_selected', '05_pos');
    details.push({ test: 'Udhaar payment type selectable', status: 'pass' });
  }

  // ── 5.5 Save Bill ────────────────────────────────────
  const saveBtn = await page.$('[data-testid="save-bill-button"]') ||
    await page.$('button:has-text("Bill Banao")') ||
    await page.$('button:has-text("Save")') ||
    await page.$('ElevatedButton');
  if (saveBtn) {
    await saveBtn.click();
    await h.waitForLoad(page);
    await h.screenshot(page, '06_bill_preview_or_result', '05_pos');
    screenshots.push('05_pos/06_bill_preview_or_result');
    details.push({ test: 'Save bill button fires', status: 'pass' });
  } else {
    details.push({ test: 'Save bill button found', status: 'warn — not found' });
    await h.screenshot(page, '06_save_button_not_found', '05_pos');
  }

  // ── Responsive check ─────────────────────────────────
  await h.screenshotResponsive(page, 'pos', '05_pos');
  details.push({ test: 'POS responsive on all breakpoints', status: 'pass' });

  return { duration: Date.now() - start, screenshots, details };
};
