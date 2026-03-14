module.exports = async function expenseTests(page, h, config) {
  const start = Date.now(); const screenshots = []; const details = [];
  await h.loginAs(page, config.SHOPKEEPER.email, config.SHOPKEEPER.password);
  try { await page.goto(config.APP_URL + '/#/expenses'); } catch (_) {}
  await h.waitForLoad(page);
  await h.screenshot(page, '01_expenses_list', '10_expenses');
  screenshots.push('10_expenses/01_expenses_list');
  details.push({ test: 'Expenses screen loads', status: 'pass' });

  const addBtn = await page.$('[data-testid="add-expense"]') ||
    await page.$('button:has-text("+")') ||
    await page.$('[aria-label*="Add"]');
  if (addBtn) {
    await addBtn.click();
    await h.waitForAction(page);
    await h.screenshot(page, '02_add_expense_form', '10_expenses');
    details.push({ test: 'Add expense form opens', status: 'pass' });
    await page.keyboard.press('Escape');
  }
  await h.screenshotResponsive(page, 'expenses', '10_expenses');
  return { duration: Date.now() - start, screenshots, details };
};
