const { chromium } = require('playwright');
const fs   = require('fs');
const path = require('path');

const URL   = 'https://super-business-shop-yous.onrender.com';
const EMAIL = 'mushtaqzain180@gmail.com';
const PASS  = '112233';

const DIRS = {
  shots:   'test/screenshots',
  videos:  'test/videos',
  reports: 'test/reports',
};

Object.values(DIRS).forEach(d =>
  fs.mkdirSync(d, { recursive: true }));

let num     = 1;
let results = [];
let issues  = [];

// ── HELPERS ───────────────────────────────────────────

async function shot(page, name) {
  const n  = String(num++).padStart(3,'0');
  const f  = `${n}_${name.replace(/[^a-z0-9]/gi,'_')}.png`;
  const fp = path.join(DIRS.shots, f);
  await page.screenshot({ path: fp, fullPage: true });
  console.log(`  📸 ${f}`);
  return fp;
}

async function wait(page, ms = 3000) {
  await page.waitForTimeout(ms);
}

async function tryClick(page, selectors) {
  for (const s of selectors) {
    try {
      await page.click(s, { timeout: 2000 });
      return true;
    } catch (_) {}
  }
  return false;
}

async function tryFill(page, selectors, value) {
  for (const s of selectors) {
    try {
      await page.fill(s, value, { timeout: 2000 });
      return true;
    } catch (_) {}
  }
  return false;
}

async function login(page) {
  await page.goto(URL, { waitUntil: 'networkidle',
    timeout: 30000 });
  await wait(page, 4000);

  await tryFill(page, [
    'input[type="email"]',
    'input[placeholder*="mail" i]',
    'input[placeholder*="ای میل" i]',
  ], EMAIL);

  await tryFill(page, [
    'input[type="password"]',
    'input[placeholder*="pass" i]',
    'input[placeholder*="پاس" i]',
  ], PASS);

  await tryClick(page, [
    'button[type="submit"]',
    'button:has-text("Login")',
    'button:has-text("لاگ ان")',
    'button:has-text("Sign In")',
  ]);

  await wait(page, 5000);
}

async function runTest(name, fn) {
  console.log(`\n▶  ${name}`);
  const t = Date.now();
  try {
    await fn();
    const d = ((Date.now()-t)/1000).toFixed(1);
    results.push({ name, pass: true, duration: d });
    console.log(`   ✅ PASS (${d}s)`);
  } catch (e) {
    const d = ((Date.now()-t)/1000).toFixed(1);
    results.push({ name, pass: false,
      error: e.message, duration: d });
    issues.push({ name, error: e.message });
    console.log(`   ❌ FAIL: ${e.message}`);
  }
}

// ── FIX HELPER ────────────────────────────────────────

function logFix(issue, fixFile, fixCode) {
  const f = path.join(DIRS.reports,
    `fix_${issue.replace(/[^a-z0-9]/gi,'_')}.txt`);
  fs.writeFileSync(f,
    `ISSUE: ${issue}\n\nFIX FILE:\n${fixFile}\n\nFIX CODE:\n${fixCode}`);
  console.log(`  🔧 Fix saved: ${f}`);
}

// ══════════════════════════════════════════════════════
// MAIN
// ══════════════════════════════════════════════════════

async function main() {
  console.log('🚀 HisaabKaro Test Suite');
  console.log(`🌐 ${URL}`);
  console.log('='.repeat(50));

  // ── RECORD VIDEO ────────────────────────────────────
  const browser = await chromium.launch({
    headless: false,
    slowMo: 100,
  });

  // ════════════════════════════════════════════════════
  // TEST 1 — SITE LOADS
  // ════════════════════════════════════════════════════
  await runTest('Site loads correctly', async () => {
    const ctx = await browser.newContext({
      viewport: { width: 1440, height: 900 },
      recordVideo: { dir: DIRS.videos,
        size: { width: 1440, height: 900 } },
    });
    const page = await ctx.newPage();

    const res = await page.goto(URL,
      { waitUntil: 'networkidle', timeout: 30000 });

    if (res.status() !== 200) {
      throw new Error(`Status ${res.status()}`);
    }
    await wait(page, 3000);
    await shot(page, '01_site_loads');

    // Check no blank white screen
    const bodyBg = await page.evaluate(() =>
      window.getComputedStyle(document.body).backgroundColor
    );
    console.log(`  Body BG: ${bodyBg}`);

    // Check title
    const title = await page.title();
    console.log(`  Title: ${title}`);
    if (!title) {
      issues.push({ name: 'No page title',
        fix: 'Set title in web/index.html' });
    }

    // Check loading screen
    const loading = await page.$('#loading');
    if (loading) {
      await shot(page, '01_loading_screen');
      // Check logo not broken
      const logoText = await page.evaluate(() => {
        const img = document.querySelector('#loading img');
        return img ? img.alt : 'no img found';
      });
      if (logoText === 'Logo') {
        issues.push({
          name: 'Broken logo image',
          error: 'img showing alt text "Logo" — file missing',
          fix: `
FIX in web/index.html:
Replace <img src="icons/favicon.png" alt="Logo"> with:

<svg width="80" height="80" viewBox="0 0 80 80"
     xmlns="http://www.w3.org/2000/svg">
  <circle cx="40" cy="40" r="38"
    fill="rgba(255,255,255,0.15)"
    stroke="rgba(255,255,255,0.3)" stroke-width="1.5"/>
  <rect x="18" y="35" width="44" height="28"
    rx="3" fill="white" opacity="0.95"/>
  <path d="M12 36 L40 18 L68 36 Z"
    fill="white" opacity="0.95"/>
  <rect x="33" y="47" width="14" height="16"
    rx="2" fill="#006D77"/>
  <circle cx="44" cy="55" r="1.5" fill="white"/>
  <rect x="20" y="42" width="10" height="8"
    rx="1.5" fill="#006D77" opacity="0.7"/>
  <rect x="50" y="42" width="10" height="8"
    rx="1.5" fill="#006D77" opacity="0.7"/>
</svg>
          `
        });
        logFix('broken_logo',
          'web/index.html',
          'Replace img tag with SVG logo above');
      }
    }

    await wait(page, 4000);
    await shot(page, '01_after_load');
    await ctx.close();
  });

  // ════════════════════════════════════════════════════
  // TEST 2 — LOGIN SCREEN
  // ════════════════════════════════════════════════════
  await runTest('Login screen design', async () => {
    const ctx = await browser.newContext({
      viewport: { width: 1440, height: 900 },
      recordVideo: { dir: DIRS.videos,
        size: { width: 1440, height: 900 } },
    });
    const page = await ctx.newPage();

    await page.goto(URL,
      { waitUntil: 'networkidle', timeout: 30000 });
    await wait(page, 4000);
    await shot(page, '02_login_screen');

    // Check background color
    const pageBg = await page.evaluate(() => {
      const el = document.querySelector(
        '.login-page, [class*="login"], body');
      return window.getComputedStyle(el).backgroundColor;
    });
    console.log(`  Login BG: ${pageBg}`);

    // Check if dark (should be light)
    const isDark = pageBg.includes('13,') ||
                   pageBg.includes('26,') ||
                   pageBg.includes('0, 0, 0');
    if (isDark) {
      issues.push({
        name: 'Login screen dark background',
        error: `Background is dark: ${pageBg}`,
        fix: `
FIX in lib/app.dart or wherever MaterialApp is:
  themeMode: ThemeMode.light,  // was ThemeMode.dark

FIX in AppThemeNotifier.build():
  return AppThemeState(
    primaryColor: Color(0xFF006D77),
    themeMode: ThemeMode.light,  // DEFAULT LIGHT
    language: 'ur',
  );
        `
      });
      logFix('dark_login_background',
        'lib/app.dart + lib/core/providers/app_theme_notifier.dart',
        'Set ThemeMode.light as default');
    }

    // Check button color
    const btnColor = await page.evaluate(() => {
      const btn = document.querySelector('button');
      if (!btn) return 'no button found';
      return window.getComputedStyle(btn).backgroundColor;
    });
    console.log(`  Button color: ${btnColor}`);

    // Check if amber/gold (should be teal)
    const isAmber = btnColor.includes('232, 168') ||
                    btnColor.includes('245, 197');
    if (isAmber) {
      issues.push({
        name: 'Button is amber/gold not teal',
        error: `Button color: ${btnColor}`,
        fix: `
FIX in lib/core/theme/app_colors.dart:
  static const Color primary = Color(0xFF006D77);
  // NOT Color(0xFFE8A838)

FIX in lib/core/theme/app_theme.dart:
  colorScheme: ColorScheme.light(
    primary: Color(0xFF006D77),  // FORCE TEAL
        `
      });
      logFix('amber_button_color',
        'lib/core/theme/app_colors.dart',
        'Change primary to Color(0xFF006D77)');
    }

    // Screenshot mobile login
    await page.setViewportSize(
      { width: 375, height: 812 });
    await wait(page, 500);
    await shot(page, '02_login_mobile');
    await page.setViewportSize(
      { width: 1440, height: 900 });

    await ctx.close();
  });

  // ════════════════════════════════════════════════════
  // TEST 3 — LOGIN WORKS
  // ════════════════════════════════════════════════════
  await runTest('Login with credentials', async () => {
    const ctx = await browser.newContext({
      viewport: { width: 1440, height: 900 },
      recordVideo: { dir: DIRS.videos,
        size: { width: 1440, height: 900 } },
    });
    const page = await ctx.newPage();

    await login(page);
    await shot(page, '03_after_login');

    const url = page.url();
    console.log(`  URL after login: ${url}`);

    const loggedIn = url.includes('dashboard') ||
                     !url.includes('login');
    if (!loggedIn) {
      throw new Error(
        `Login failed — still on ${url}`);
    }

    // Check dashboard visible
    await wait(page, 2000);
    await shot(page, '03_dashboard_loaded');
    await ctx.close();
  });

  // ════════════════════════════════════════════════════
  // TEST 4 — DASHBOARD DATA
  // ════════════════════════════════════════════════════
  await runTest('Dashboard shows real data', async () => {
    const ctx = await browser.newContext({
      viewport: { width: 1440, height: 900 },
      recordVideo: { dir: DIRS.videos,
        size: { width: 1440, height: 900 } },
    });
    const page = await ctx.newPage();

    await login(page);
    await wait(page, 3000);
    await shot(page, '04_dashboard_full');

    // Check for loading spinners stuck
    const spinners = await page.$$(
      '[class*="spinner"], [class*="loading"]');
    if (spinners.length > 2) {
      issues.push({
        name: 'Too many loading spinners on dashboard',
        error: `${spinners.length} spinners found`,
        fix: 'Check Supabase queries completing correctly'
      });
    }

    // Check no "coming soon" text
    const bodyText = await page.evaluate(() =>
      document.body.innerText.toLowerCase()
    );
    if (bodyText.includes('coming soon')) {
      issues.push({
        name: 'Coming soon text found',
        error: 'Found "coming soon" text on screen',
        fix: 'Remove all coming soon placeholders'
      });
    }

    // Mobile dashboard
    await page.setViewportSize(
      { width: 375, height: 812 });
    await wait(page, 1000);
    await shot(page, '04_dashboard_mobile');

    // Tablet dashboard
    await page.setViewportSize(
      { width: 768, height: 1024 });
    await wait(page, 1000);
    await shot(page, '04_dashboard_tablet');

    await ctx.close();
  });

  // ════════════════════════════════════════════════════
  // TEST 5 — POS SCREEN
  // ════════════════════════════════════════════════════
  await runTest('POS screen — no ads, works correctly',
  async () => {
    const ctx = await browser.newContext({
      viewport: { width: 1440, height: 900 },
      recordVideo: { dir: DIRS.videos,
        size: { width: 1440, height: 900 } },
    });
    const page = await ctx.newPage();

    await login(page);

    await tryClick(page, [
      '[href*="pos"]',
      'a:has-text("Bikri")',
      'a:has-text("POS")',
      '[data-testid="pos-nav"]',
    ]);
    await wait(page, 3000);
    await shot(page, '05_pos_screen');

    // CRITICAL: Check NO ads on POS
    const adOnPos = await page.$(
      '.banner-ad, [class*="ad-banner"], ' +
      'ins.adsbygoogle'
    );
    if (adOnPos) {
      issues.push({
        name: 'AD FOUND ON POS SCREEN — CRITICAL',
        error: 'Ads must NEVER show on POS screen',
        fix: `
FIX in lib/core/widgets/app_banner_ad.dart:
  // List of screens where ads are NOT allowed
  const noAdScreens = [
    '/pos', '/bills/edit', '/customers/',
    '/returns', '/expenses/add',
  ];

  // In AppBannerAd.build():
  final currentRoute = GoRouterState.of(context).location;
  final isNoAdScreen = noAdScreens.any(
    (s) => currentRoute.contains(s));
  if (isNoAdScreen) return SizedBox.shrink();
        `
      });
      logFix('ad_on_pos',
        'lib/core/widgets/app_banner_ad.dart',
        'Add route check to hide ads on POS');
    } else {
      console.log('  ✅ No ads on POS — correct!');
    }

    // Check product search
    const search = await page.$(
      'input[placeholder*="search" i], ' +
      'input[placeholder*="talaash" i]'
    );
    if (!search) {
      issues.push({
        name: 'POS search bar missing',
        error: 'Cannot find search input on POS',
        fix: 'Add search input to POS screen'
      });
    }

    await page.setViewportSize(
      { width: 375, height: 812 });
    await wait(page, 500);
    await shot(page, '05_pos_mobile');

    await ctx.close();
  });

  // ════════════════════════════════════════════════════
  // TEST 6 — INVENTORY
  // ════════════════════════════════════════════════════
  await runTest('Inventory screen', async () => {
    const ctx = await browser.newContext({
      viewport: { width: 1440, height: 900 },
      recordVideo: { dir: DIRS.videos,
        size: { width: 1440, height: 900 } },
    });
    const page = await ctx.newPage();

    await login(page);
    await tryClick(page, [
      '[href*="inventory"]',
      'a:has-text("Maal")',
      'a:has-text("Inventory")',
    ]);
    await wait(page, 3000);
    await shot(page, '06_inventory');

    // Check filter chips exist
    const chips = await page.$$(
      '[class*="chip"], [class*="filter-btn"]'
    );
    console.log(`  Filter chips: ${chips.length}`);
    if (chips.length < 3) {
      issues.push({
        name: 'Inventory filter chips missing',
        error: `Only ${chips.length} chips found, need 4`,
        fix: 'Add filter chips: Tamam, Kam Stock, Thanda Maal, Kam Munafa'
      });
    }

    // Click each chip
    for (let i = 0; i < Math.min(chips.length, 4); i++) {
      await chips[i].click().catch(() => {});
      await wait(page, 800);
    }
    await shot(page, '06_inventory_filtered');

    await ctx.close();
  });

  // ════════════════════════════════════════════════════
  // TEST 7 — CUSTOMERS
  // ════════════════════════════════════════════════════
  await runTest('Customer ledger', async () => {
    const ctx = await browser.newContext({
      viewport: { width: 1440, height: 900 },
      recordVideo: { dir: DIRS.videos,
        size: { width: 1440, height: 900 } },
    });
    const page = await ctx.newPage();

    await login(page);
    await tryClick(page, [
      '[href*="customer"]',
      'a:has-text("Grahak")',
      'a:has-text("Customer")',
    ]);
    await wait(page, 3000);
    await shot(page, '07_customers');

    // Check balance colors
    const red = await page.$$(
      '[class*="danger"], [class*="red"], [style*="red"]'
    );
    console.log(`  Red balances: ${red.length}`);

    await ctx.close();
  });

  // ════════════════════════════════════════════════════
  // TEST 8 — REPORTS + DATE FILTER
  // ════════════════════════════════════════════════════
  await runTest('Reports with date filter', async () => {
    const ctx = await browser.newContext({
      viewport: { width: 1440, height: 900 },
      recordVideo: { dir: DIRS.videos,
        size: { width: 1440, height: 900 } },
    });
    const page = await ctx.newPage();

    await login(page);
    await tryClick(page, [
      '[href*="report"]',
      'a:has-text("Riport")',
      'a:has-text("Report")',
    ]);
    await wait(page, 3000);
    await shot(page, '08_reports');

    // Check date filter bar
    const filterBtns = await page.$$(
      'button:has-text("Aaj"), button:has-text("Today"), ' +
      'button:has-text("Hafte"), button:has-text("Week")'
    );
    console.log(`  Date filter buttons: ${filterBtns.length}`);

    if (filterBtns.length === 0) {
      issues.push({
        name: 'Date filter bar missing on reports',
        error: 'No date filter buttons found',
        fix: 'Add DateFilterBar widget to reports screen top'
      });
      logFix('missing_date_filter',
        'lib/features/reports/presentation/reports_screen.dart',
        'Add DateFilterBar widget at top of screen');
    }

    // Test each filter
    for (const btn of filterBtns) {
      await btn.click().catch(() => {});
      await wait(page, 1000);
    }
    await shot(page, '08_reports_filtered');

    // Check ad on reports (allowed — top only)
    const ad = await page.$(
      '.banner-ad, [class*="ad-banner"]'
    );
    if (ad) {
      const box = await ad.boundingBox();
      const isTop = box && box.y < 150;
      console.log(
        `  Ad on reports: Y=${box?.y} ` +
        `${isTop ? '✅ top' : '❌ NOT at top'}`
      );
      if (!isTop) {
        issues.push({
          name: 'Ad not at top of reports',
          error: `Ad Y position: ${box?.y} (should be < 150)`,
          fix: 'Move ad banner to very top of reports screen'
        });
      }

      // Check close button on ad
      const closeBtn = await page.$(
        '[class*="ad"] [class*="close"], ' +
        '[class*="ad"] button'
      );
      if (!closeBtn) {
        issues.push({
          name: 'Ad close button missing',
          error: 'No close button on banner ad',
          fix: `
FIX in lib/core/widgets/app_banner_ad.dart:
Add close button (44x44px minimum):

Positioned(
  top: 0, right: 0,
  child: GestureDetector(
    onTap: () => setState(() => _closed = true),
    child: Container(
      width: 44, height: 44,
      color: Colors.black54,
      child: Icon(Icons.close,
        color: Colors.white, size: 22),
    ),
  ),
),
          `
        });
      }
    }

    await ctx.close();
  });

  // ════════════════════════════════════════════════════
  // TEST 9 — SETTINGS + CUSTOMIZATION
  // ════════════════════════════════════════════════════
  await runTest('Settings and customization', async () => {
    const ctx = await browser.newContext({
      viewport: { width: 1440, height: 900 },
      recordVideo: { dir: DIRS.videos,
        size: { width: 1440, height: 900 } },
    });
    const page = await ctx.newPage();

    await login(page);
    await tryClick(page, [
      '[href*="setting"]',
      'a:has-text("Settings")',
      'a:has-text("Tنظیمات")',
    ]);
    await wait(page, 3000);
    await shot(page, '09_settings');

    // Test dark mode toggle
    await tryClick(page, [
      'text=Dark', 'text=Andhera',
      '[data-testid="dark-mode"]',
    ]);
    await wait(page, 2000);
    await shot(page, '09_dark_mode');

    // Check dark mode applied
    const isDark = await page.evaluate(() => {
      const bg = window.getComputedStyle(
        document.body).backgroundColor;
      return bg.includes('13,') || bg.includes('26,');
    });
    console.log(`  Dark mode: ${isDark ? '✅' : '❌'}`);

    // Revert to light
    await tryClick(page, [
      'text=Light', 'text=Roshan',
    ]);
    await wait(page, 1000);

    // Test language toggle
    await tryClick(page, [
      'text=EN', 'button:has-text("EN")',
    ]);
    await wait(page, 2000);
    await shot(page, '09_english_mode');

    await tryClick(page, [
      'text=اردو', 'button:has-text("اردو")',
    ]);
    await wait(page, 2000);
    await shot(page, '09_urdu_mode');

    // Check RTL
    const isRtl = await page.evaluate(() =>
      document.body.dir === 'rtl' ||
      document.documentElement.dir === 'rtl'
    );
    console.log(`  Urdu RTL: ${isRtl ? '✅' : '❌'}`);
    if (!isRtl) {
      issues.push({
        name: 'Urdu RTL not working',
        error: 'dir attribute not set to rtl',
        fix: `
FIX in lib/app.dart builder:
  builder: (context, child) {
    return Directionality(
      textDirection: isUrdu
        ? TextDirection.rtl
        : TextDirection.ltr,
      child: child!,
    );
  },
        `
      });
    }

    await ctx.close();
  });

  // ════════════════════════════════════════════════════
  // TEST 10 — OFFLINE MODE
  // ════════════════════════════════════════════════════
  await runTest('Offline mode', async () => {
    const ctx = await browser.newContext({
      viewport: { width: 1440, height: 900 },
      recordVideo: { dir: DIRS.videos,
        size: { width: 1440, height: 900 } },
    });
    const page = await ctx.newPage();

    await login(page);

    // Go offline
    await ctx.setOffline(true);
    await wait(page, 2000);
    await shot(page, '10_offline_banner');

    const offBanner = await page.isVisible(
      'text=Internet nahi, text=offline, text=Offline'
    ).catch(() => false);
    console.log(
      `  Offline banner: ${offBanner ? '✅' : '❌'}`
    );
    if (!offBanner) {
      issues.push({
        name: 'Offline banner not showing',
        error: 'No offline indicator when internet off',
        fix: `
FIX: Add OfflineBanner widget to app root in lib/app.dart:

Stack(children: [
  child!,
  Positioned(
    top: 0, left: 0, right: 0,
    child: OfflineBanner(),
  ),
])
        `
      });
    }

    // Try POS offline
    await tryClick(page, [
      '[href*="pos"]', 'a:has-text("Bikri")',
    ]);
    await wait(page, 3000);
    await shot(page, '10_pos_offline');

    // Come back online
    await ctx.setOffline(false);
    await wait(page, 3000);
    await shot(page, '10_back_online');

    await ctx.close();
  });

  // ════════════════════════════════════════════════════
  // TEST 11 — CUSTOMER PORTAL
  // ════════════════════════════════════════════════════
  await runTest('Customer portal', async () => {
    const ctx = await browser.newContext({
      viewport: { width: 375, height: 812 },
      recordVideo: { dir: DIRS.videos,
        size: { width: 375, height: 812 } },
    });
    const page = await ctx.newPage();

    await page.goto(`${URL}/#/customer/login`,
      { waitUntil: 'networkidle', timeout: 15000 });
    await wait(page, 3000);
    await shot(page, '11_portal_login');

    const phoneInput = await page.$(
      'input[type="tel"], ' +
      'input[placeholder*="phone" i], ' +
      'input[placeholder*="number" i], ' +
      'input[placeholder*="0300" i]'
    );
    if (!phoneInput) {
      issues.push({
        name: 'Customer portal phone input missing',
        error: 'No phone input on portal login',
        fix: 'Check /customer/login route in GoRouter'
      });
    } else {
      console.log('  Portal phone input: ✅');
    }

    await ctx.close();
  });

  // ════════════════════════════════════════════════════
  // TEST 12 — ALL ROUTES WORK
  // ════════════════════════════════════════════════════
  await runTest('All routes accessible', async () => {
    const ctx = await browser.newContext({
      viewport: { width: 1440, height: 900 },
    });
    const page = await ctx.newPage();
    await login(page);

    const routes = [
      ['dashboard',        '/#/dashboard'],
      ['pos',              '/#/pos'],
      ['inventory',        '/#/inventory'],
      ['customers',        '/#/customers'],
      ['suppliers',        '/#/suppliers'],
      ['bills',            '/#/bills/all'],
      ['returns',          '/#/bills/returns'],
      ['expenses',         '/#/finance/expenses'],
      ['daily_cash',       '/#/finance/daily-cash'],
      ['reports',          '/#/reports'],
      ['team',             '/#/team'],
      ['settings',         '/#/settings'],
      ['backup',           '/#/settings/backup'],
      ['customer_portal',  '/#/customer/login'],
    ];

    for (const [name, route] of routes) {
      await page.goto(`${URL}${route}`,
        { timeout: 10000 }).catch(() => {});
      await wait(page, 2000);
      await shot(page, `12_route_${name}`);

      const is404 = await page.isVisible(
        'text=404, text=Not Found, text=Page not found'
      ).catch(() => false);

      if (is404) {
        issues.push({
          name: `Route ${route} shows 404`,
          error: `${route} not found`,
          fix: `Add route ${route} to GoRouter in app_router.dart`
        });
        console.log(`  ❌ ${route} → 404`);
      } else {
        console.log(`  ✅ ${route}`);
      }
    }

    await ctx.close();
  });

  // ════════════════════════════════════════════════════
  // TEST 13 — RESPONSIVE ALL SCREENS
  // ════════════════════════════════════════════════════
  await runTest('Responsive design', async () => {
    const ctx = await browser.newContext({
      viewport: { width: 1440, height: 900 },
    });
    const page = await ctx.newPage();
    await login(page);

    const screens = [
      ['dashboard', '/#/dashboard'],
      ['pos',       '/#/pos'],
      ['inventory', '/#/inventory'],
      ['reports',   '/#/reports'],
    ];

    for (const [name, route] of screens) {
      await page.goto(`${URL}${route}`);
      await wait(page, 2000);

      // Desktop
      await page.setViewportSize(
        { width: 1440, height: 900 });
      await wait(page, 500);
      await shot(page, `13_${name}_desktop`);

      // Tablet
      await page.setViewportSize(
        { width: 768, height: 1024 });
      await wait(page, 500);
      await shot(page, `13_${name}_tablet`);

      // Mobile
      await page.setViewportSize(
        { width: 375, height: 812 });
      await wait(page, 500);
      await shot(page, `13_${name}_mobile`);

      // Check overflow on mobile
      const hasOverflow = await page.evaluate(() => {
        return document.body.scrollWidth >
               window.innerWidth + 10;
      });
      if (hasOverflow) {
        issues.push({
          name: `Horizontal overflow on ${name} mobile`,
          error: 'Content wider than screen on mobile',
          fix: `Fix layout overflow in ${name}_screen.dart`
        });
        console.log(`  ❌ ${name} mobile overflow`);
      }
    }

    await ctx.close();
  });

  await browser.close();

  // ════════════════════════════════════════════════════
  // GENERATE REPORTS
  // ════════════════════════════════════════════════════
  generateReport();
  generateFixFile();

  console.log('\n' + '='.repeat(50));
  console.log(`✅ PASSED: ${
    results.filter(r=>r.pass).length}`);
  console.log(`❌ FAILED: ${
    results.filter(r=>!r.pass).length}`);
  console.log(`🔧 ISSUES: ${issues.length}`);
  console.log('='.repeat(50));
  console.log('📸 Screenshots: test/screenshots/');
  console.log('🎥 Videos:      test/videos/');
  console.log('📋 Report:      test/reports/');
}

// ── GENERATE HTML REPORT ──────────────────────────────

function generateReport() {
  const passed = results.filter(r=>r.pass).length;
  const failed = results.filter(r=>!r.pass).length;
  const pct    = Math.round(passed/results.length*100);

  const shots = fs.readdirSync(DIRS.shots)
    .filter(f=>f.endsWith('.png'))
    .map(f=>`
      <div class="ss">
        <img src="../screenshots/${f}" loading="lazy"
          onclick="window.open(this.src,'_blank')">
        <p>${f.replace('.png','').replace(/_/g,' ')}</p>
      </div>`).join('');

  const vids = fs.readdirSync(DIRS.videos)
    .filter(f=>f.endsWith('.webm'))
    .map(f=>`
      <div class="vc">
        <video controls>
          <source src="../videos/${f}" type="video/webm">
        </video>
        <p>${f.replace('.webm','').replace(/_/g,' ')}</p>
      </div>`).join('');

  const issueRows = issues.map(i=>`
    <div class="issue">
      <h3>❌ ${i.name}</h3>
      <p><b>Error:</b> ${i.error||''}</p>
      <pre>${i.fix||''}</pre>
    </div>`).join('');

  const html = `<!DOCTYPE html>
<html><head><meta charset="UTF-8">
<title>HisaabKaro Test Report</title>
<style>
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:sans-serif;background:#f5f5f5}
.hdr{background:#006D77;color:white;
     padding:24px;text-align:center}
.hdr h1{font-size:22px;margin-bottom:8px}
.stats{display:flex;gap:12px;padding:16px;
       justify-content:center;flex-wrap:wrap}
.stat{background:white;padding:16px 20px;
      border-radius:12px;text-align:center;
      min-width:120px}
.stat .n{font-size:32px;font-weight:bold}
.g{color:#27AE60}.r{color:#E74C3C}
.b{color:#006D77}.o{color:#F39C12}
.bar{height:6px;background:#eee;
     border-radius:3px;overflow:hidden;margin:8px 0}
.fill{height:100%;background:#27AE60;
      width:${pct}%;border-radius:3px}
table{width:100%;border-collapse:collapse;
      background:white;border-radius:12px;
      overflow:hidden;margin:12px 0}
th{background:#006D77;color:white;padding:10px}
td{padding:8px 12px;border-bottom:1px solid #eee;
   font-size:13px}
.p td:nth-child(3){color:#27AE60;font-weight:bold}
.f td:nth-child(3){color:#E74C3C;font-weight:bold}
.f td:last-child{font-size:11px;color:#E74C3C}
.sec{max-width:1200px;margin:12px auto;padding:0 12px}
h2{color:#006D77;margin:16px 0 8px}
.ss-grid{display:grid;
         grid-template-columns:repeat(4,1fr);gap:8px}
.ss img{width:100%;border-radius:6px;cursor:pointer;
        border:1px solid #eee}
.ss p{font-size:10px;color:#666;
      margin:3px 0;text-align:center}
.v-grid{display:grid;
        grid-template-columns:repeat(2,1fr);gap:12px}
.vc video{width:100%;border-radius:8px}
.vc p{font-size:11px;color:#666;margin-top:4px}
.issue{background:white;border-left:4px solid #E74C3C;
       border-radius:8px;padding:16px;margin:8px 0}
.issue h3{color:#E74C3C;margin-bottom:8px}
.issue pre{background:#f9f9f9;padding:12px;
           border-radius:4px;font-size:11px;
           white-space:pre-wrap;margin-top:8px}
@media(max-width:600px){
  .ss-grid{grid-template-columns:repeat(2,1fr)}
  .v-grid{grid-template-columns:1fr}
}
</style></head><body>
<div class="hdr">
  <h1>🏪 HisaabKaro — Test Report</h1>
  <p>URL: https://super-business-flutter-web.onrender.com</p>
  <p>Login: mushtaqzain180@gmail.com</p>
  <p>Generated: ${new Date().toLocaleString()}</p>
  <div class="bar"><div class="fill"></div></div>
  <p>${pct}% Pass Rate</p>
</div>
<div class="stats">
  <div class="stat">
    <div class="n b">${results.length}</div>Total</div>
  <div class="stat">
    <div class="n g">${passed}</div>Passed</div>
  <div class="stat">
    <div class="n r">${failed}</div>Failed</div>
  <div class="stat">
    <div class="n o">${issues.length}</div>Issues</div>
</div>
<div class="sec">
<table>
  <tr><th>#</th><th>Test</th><th>Status</th>
      <th>Time</th><th>Error</th></tr>
  ${results.map((r,i)=>`
  <tr class="${r.pass?'p':'f'}">
    <td>${i+1}</td>
    <td>${r.name}</td>
    <td>${r.pass?'✅ PASS':'❌ FAIL'}</td>
    <td>${r.duration}s</td>
    <td>${r.error||''}</td>
  </tr>`).join('')}
</table>

${issues.length > 0 ? `
<h2>🔧 Issues Found (${issues.length})</h2>
${issueRows}` : '<h2 style="color:#27AE60">✅ No Issues Found!</h2>'}

<h2>📸 Screenshots (${
  fs.readdirSync(DIRS.shots).filter(
    f=>f.endsWith('.png')).length})</h2>
<div class="ss-grid">${shots}</div>

<h2>🎥 Videos</h2>
<div class="v-grid">${vids}</div>
</div></body></html>`;

  fs.writeFileSync(
    path.join(DIRS.reports, 'test_report.html'), html);
  console.log('\n📋 Report: test/reports/test_report.html');
}

// ── GENERATE FIX FILE ─────────────────────────────────

function generateFixFile() {
  if (issues.length === 0) {
    console.log('✅ No fixes needed!');
    return;
  }

  let fixes = `HISAABKARO — ISSUES AND FIXES
Generated: ${new Date().toLocaleString()}
Total Issues: ${issues.length}
${'='.repeat(50)}\n\n`;

  issues.forEach((issue, i) => {
    fixes += `ISSUE ${i+1}: ${issue.name}\n`;
    fixes += `Error: ${issue.error||'See details'}\n`;
    fixes += `Fix:\n${issue.fix||'See fix files in reports/'}\n`;
    fixes += `${'-'.repeat(40)}\n\n`;
  });

  fs.writeFileSync(
    path.join(DIRS.reports, 'ALL_FIXES.txt'), fixes);
  console.log('🔧 Fixes: test/reports/ALL_FIXES.txt');
}

main().catch(console.error);
