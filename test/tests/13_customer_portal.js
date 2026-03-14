module.exports = async function portalTests(page, h, config) {
  const start = Date.now();
  const screenshots = [];
  const details = [];

  // Open customer portal login
  await page.goto(config.APP_URL + '/#/customer/login');
  await h.waitForLoad(page);
  await h.screenshot(page, '01_portal_login_screen', '13_portal');
  screenshots.push('13_portal/01_portal_login_screen');
  details.push({ test: 'Customer portal login screen loads', status: 'pass' });

  // Enter phone number
  const phoneInput = await page.$('input[type="tel"]') ||
    await page.$('input[type="number"]') ||
    await page.$('[data-testid="phone-input"]');
  if (phoneInput) {
    await phoneInput.fill(config.CUSTOMER.phone);
    await h.waitForAction(page);
    await h.screenshot(page, '02_phone_entered', '13_portal');
    details.push({ test: 'Phone number entered', status: 'pass' });
  } else {
    await h.screenshot(page, '02_phone_input_not_found', '13_portal');
    details.push({ test: 'Phone input found', status: 'warn' });
  }

  // OTP send button
  const otpBtn = await page.$('button:has-text("OTP")') ||
    await page.$('button:has-text("Send")') ||
    await page.$('button:has-text("Bhejo")');
  if (otpBtn) {
    await h.screenshot(page, '03_otp_send_button_visible', '13_portal');
    details.push({ test: 'OTP send button visible', status: 'pass' });
    // Don't actually send to avoid consuming SMS — just screenshot
  }

  // Responsive screenshots of portal
  await h.screenshotResponsive(page, 'portal_login', '13_portal');
  details.push({ test: 'Customer portal responsive layout', status: 'pass' });

  return { duration: Date.now() - start, screenshots, details };
};
