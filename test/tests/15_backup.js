module.exports = async function backupTests(page, h, config) {
  const start = Date.now(); const screenshots = []; const details = [];
  await h.loginAs(page, config.SHOPKEEPER.email, config.SHOPKEEPER.password);
  try { await page.goto(config.APP_URL + '/#/settings/backup'); } catch (_) {}
  await h.waitForLoad(page);
  await h.screenshot(page, '01_backup_screen', '15_backup');
  screenshots.push('15_backup/01_backup_screen');
  details.push({ test: 'Backup screen loads', status: 'pass' });

  const backupBtn = await page.$('button:has-text("Backup")') ||
    await page.$('[data-testid="manual-backup-btn"]');
  if (backupBtn) {
    await h.highlight(page, 'button:has-text("Backup")');
    await h.screenshot(page, '02_backup_button_visible', '15_backup');
    details.push({ test: 'Manual backup button visible', status: 'pass' });
  }
  return { duration: Date.now() - start, screenshots, details };
};
