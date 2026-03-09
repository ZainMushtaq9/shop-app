# Super Business Shop App

A complete daily shop management system for small Pakistani shopkeepers (Android + iOS + Web PWA). Urdu-first interface, offline-capable, with Google Sheets sync, buyer/supplier ledgers, POS billing, and full inventory tracking.

## Deployment with Render

To deploy to Render, create a Static Site and use the following Build Command:

```bash
git clone https://github.com/flutter/flutter.git -b stable && export PATH="$PATH:`pwd`/flutter/bin" && flutter build web --release
```

Set Publish Directory to `build/web`.
