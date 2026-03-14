const { chromium } = require('playwright');
const config = require('./config');
const h = require('./helpers');
const fs = require('fs');
const path = require('path');

const testModules = [
  { name: '01 Authentication',    fn: require('./tests/01_auth') },
  { name: '04 Dashboard',         fn: require('./tests/04_dashboard') },
  { name: '05 POS Sales',         fn: require('./tests/05_pos') },
  { name: '06 Inventory',         fn: require('./tests/06_inventory') },
  { name: '07 Customers',         fn: require('./tests/07_customers') },
  { name: '08 Bill Management',   fn: require('./tests/08_bills') },
  { name: '09 Returns',           fn: require('./tests/09_returns') },
  { name: '10 Expenses',          fn: require('./tests/10_expenses') },
  { name: '11 Daily Cash',        fn: require('./tests/11_daily_cash') },
  { name: '12 Reports',           fn: require('./tests/12_reports') },
  { name: '13 Customer Portal',   fn: require('./tests/13_customer_portal') },
  { name: '14 Offline Mode',      fn: require('./tests/14_offline') },
  { name: '15 Backup',            fn: require('./tests/15_backup') },
  { name: '16 Team RBAC',         fn: require('./tests/16_team') },
  { name: '17 Responsive Design', fn: require('./tests/17_responsive') },
  { name: '18 Urdu RTL',          fn: require('./tests/18_urdu') },
];

const testResults = [];

async function runAllTests() {
  console.log('\n🚀 Super Business Shop — Full QA Test Suite');
  console.log('='.repeat(60));
  console.log(`APP_URL: ${config.APP_URL}`);
  console.log('='.repeat(60) + '\n');

  // Ensure directories exist
  ['test/images/screenshots','test/videos/flows','test/videos/compressed','test/manual','test/reports'].forEach(d => {
    fs.mkdirSync(d, { recursive: true });
  });

  const browser = await chromium.launch({ headless: false, slowMo: 80 });

  for (const test of testModules) {
    console.log(`\n▶️  ${test.name}`);
    console.log('-'.repeat(40));

    const context = await browser.newContext({
      viewport: { width: config.VIDEO.width, height: config.VIDEO.height },
      recordVideo: {
        dir: 'test/videos/flows/',
        size: { width: config.VIDEO.width, height: config.VIDEO.height },
      },
      ignoreHTTPSErrors: true,
    });

    const page = await context.newPage();
    page.setDefaultTimeout(config.TIMEOUT);

    const timeStart = Date.now();
    try {
      const result = await test.fn(page, h, config);
      testResults.push({
        name: test.name,
        status: 'PASS',
        duration: result.duration || (Date.now() - timeStart),
        screenshots: result.screenshots || [],
        details: result.details || [],
      });
      console.log(`✅ PASS: ${test.name} (${((Date.now()-timeStart)/1000).toFixed(1)}s)`);
    } catch (error) {
      await h.screenshot(page, `FAIL_${test.name.replace(/\s/g,'_')}`, 'failures').catch(() => {});
      testResults.push({
        name: test.name,
        status: 'FAIL',
        duration: Date.now() - timeStart,
        error: error.message,
        stack: error.stack,
      });
      console.log(`❌ FAIL: ${test.name} — ${error.message}`);
    } finally {
      await context.close();
    }
  }

  await browser.close();

  generateHTMLReport(testResults);
  generateVideoIndex();

  const passed = testResults.filter(t => t.status === 'PASS').length;
  const failed = testResults.filter(t => t.status === 'FAIL').length;

  console.log('\n' + '='.repeat(60));
  console.log(`📊 RESULTS: ${passed} PASSED, ${failed} FAILED out of ${testResults.length}`);
  console.log('='.repeat(60));
  console.log('📁 Screenshots : test/images/screenshots/');
  console.log('🎥 Videos      : test/videos/');
  console.log('📋 Report      : test/reports/test_report.html');
  console.log('📖 Manual      : test/manual/');
}

function generateHTMLReport(results) {
  const passed = results.filter(t => t.status === 'PASS').length;
  const failed = results.filter(t => t.status === 'FAIL').length;
  const total = results.length;
  const passRate = total > 0 ? Math.round((passed / total) * 100) : 0;
  const timestamp = new Date().toLocaleString('en-PK');

  const html = `<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Test Report — Super Business Shop</title>
  <style>
    *{box-sizing:border-box;margin:0;padding:0}
    body{font-family:Arial,sans-serif;background:#f5f5f5}
    .header{background:#006D77;color:white;padding:30px;text-align:center}
    .header h1{font-size:26px;margin-bottom:8px}
    .summary{display:flex;gap:16px;padding:20px;justify-content:center;flex-wrap:wrap}
    .stat{background:white;border-radius:12px;padding:20px;text-align:center;min-width:130px;box-shadow:0 2px 8px rgba(0,0,0,.1)}
    .stat .n{font-size:38px;font-weight:bold}
    .green{color:#4CAF50}.red{color:#F44336}.blue{color:#006D77}.orange{color:#FF9800}
    .container{max-width:1100px;margin:0 auto;padding:20px}
    .block{background:white;border-radius:12px;margin-bottom:16px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,.08)}
    .bhead{display:flex;align-items:center;padding:14px 18px;cursor:pointer;border-bottom:1px solid #eee}
    .badge{padding:3px 12px;border-radius:20px;font-weight:bold;margin-left:auto;font-size:13px}
    .pb{background:#E8F5E9;color:#2E7D32}.fb{background:#FFEBEE;color:#C62828}
    .bdetail{padding:18px;display:none}
    .bdetail.open{display:block}
    .errbox{background:#FFEBEE;border:1px solid #F44336;border-radius:8px;padding:12px;font-family:monospace;font-size:12px;overflow-x:auto;margin-top:8px}
    .prog{height:8px;background:#eee;border-radius:4px;overflow:hidden;margin-top:10px}
    .progf{height:100%;background:#4CAF50;border-radius:4px;width:${passRate}%}
    ul{padding-left:18px;margin-top:8px}li{margin:4px 0}
  </style>
</head>
<body>
<div class="header">
  <h1>🏪 Super Business Shop — QA Test Report</h1>
  <p style="opacity:.8">Generated: ${timestamp}</p>
  <div class="prog"><div class="progf"></div></div>
  <p style="margin-top:8px">${passRate}% Pass Rate</p>
</div>
<div class="summary">
  <div class="stat"><div class="n blue">${total}</div><div>Total</div></div>
  <div class="stat"><div class="n green">${passed}</div><div>Passed ✅</div></div>
  <div class="stat"><div class="n red">${failed}</div><div>Failed ❌</div></div>
  <div class="stat"><div class="n orange">${passRate}%</div><div>Pass Rate</div></div>
</div>
<div class="container">
  <p style="margin-bottom:12px"><a href="video_index.html">🎥 Video Index</a></p>
  ${results.map((r, i) => `
  <div class="block">
    <div class="bhead" onclick="document.getElementById('d${i}').classList.toggle('open')">
      <strong>${r.name}</strong>
      <span style="color:#999;margin-left:8px;font-size:13px">${((r.duration||0)/1000).toFixed(1)}s</span>
      <span class="badge ${r.status==='PASS'?'pb':'fb'}">${r.status==='PASS'?'✅ PASS':'❌ FAIL'}</span>
    </div>
    <div class="bdetail" id="d${i}">
      ${r.error ? `<div class="errbox"><strong>Error:</strong> ${r.error}<br><pre>${(r.stack||'').replace(/</g,'&lt;')}</pre></div>` : ''}
      ${r.details && r.details.length ? `<ul>${r.details.map(d=>`<li>${d.status==='pass'?'✅':'⚠️'} ${d.test}</li>`).join('')}</ul>` : ''}
    </div>
  </div>`).join('')}
</div>
<script>
  // Auto-open failed tests
  ${results.map((r,i) => r.status==='FAIL' ? `document.getElementById('d${i}').classList.add('open');` : '').join('\n  ')}
</script>
</body>
</html>`;

  fs.writeFileSync('test/reports/test_report.html', html);
  console.log('\n📋 Report saved: test/reports/test_report.html');
}

function generateVideoIndex() {
  try {
    const dir = 'test/videos/flows/';
    if (!fs.existsSync(dir)) return;
    const videos = fs.readdirSync(dir).filter(f => f.match(/\.(webm|mp4)$/));
    const html = `<!DOCTYPE html><html><head><meta charset="UTF-8"><title>Video Index</title>
    <style>body{font-family:Arial;max-width:1100px;margin:0 auto;padding:20px}
    h1{color:#006D77}.grid{display:grid;grid-template-columns:repeat(2,1fr);gap:18px}
    .card{background:#f5f5f5;border-radius:10px;padding:14px}
    .card h3{margin-bottom:8px;text-transform:capitalize;font-size:14px}
    video{width:100%;border-radius:8px}</style></head><body>
    <h1>🎥 Test Recordings</h1>
    <div class="grid">${videos.map(v=>`<div class="card">
      <h3>${v.replace(/_/g,' ').replace(/\.(webm|mp4)$/,'')}</h3>
      <video controls><source src="../videos/flows/${v}"></video></div>`).join('')}</div>
    </body></html>`;
    fs.writeFileSync('test/reports/video_index.html', html);
    console.log('🎥 Video index saved: test/reports/video_index.html');
  } catch(_) {}
}

runAllTests().catch(console.error);
