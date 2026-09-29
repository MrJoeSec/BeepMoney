# TheBag 💰
### Fast, Private, Free Forever Personal Wealth & Spending Tracker for iPhone

TheBag is built around one core mandate:
**Make tracking money extremely fast and make your financial situation easy to understand.**

- **100% Free Forever**: No subscriptions, no developer fees, and no 7-day certificate expirations.
- **100% Private & Local**: Zero cloud databases, zero telemetry, and zero accounts. All financial records are stored directly on your iPhone in persistent `IndexedDB` storage.
- **Instant Quick Add**: Log any expense in 5–10 seconds using the ergonomic calculator keypad and quick-additive buttons.
- **Dynamic Factual Analysis**: Automatic calculation of burn rate, remaining monthly balance, savings rate, and factual month-over-month shifts.
- **Full Wealth Tracking**: Track assets, liabilities, and real-time net worth.
- **Offline First**: Works completely offline via built-in Service Worker.

---

## Architecture & File Structure

```
TheBag/
├── index.html               # Main iOS single-page application
├── style.css                # Apple iOS Human Interface design system (Dark & Light modes)
├── app.js                   # High-performance application controller & UI orchestrator
├── db.js                    # IndexedDB persistence layer + CSV/JSON backup engine
├── analytics.js             # Factual financial analytics & insight engine
├── manifest.json            # PWA standalone manifest configuration
├── sw.js                    # Offline Service Worker cache engine
├── icons/                   # High-resolution Apple touch icons
│   ├── apple-touch-icon.png # 180x180 iOS Home Screen icon
│   ├── icon-192.png         # 192x192 PWA icon
│   └── icon-512.png         # 512x512 PWA splash icon
├── INSTALLATION_GUIDE.md    # Step-by-step iPhone 16e setup instructions
└── TheBag/                  # Native Swift/SwiftData codebase (Optional reference)
    ├── Models/
    ├── Services/
    └── Views/
```

---

## Quick Launch

To test or use the app immediately on your computer or local network:

```bash
# In the project directory:
python3 -m http.server 8080
```

Then open `http://localhost:8080` in your browser. On your iPhone, open `http://<your-ip>:8080` in Safari and tap **Share > Add to Home Screen**.

For detailed setup on your iPhone 16e, see [INSTALLATION_GUIDE.md](file:///home/ackerman/Desktop/TheBag/INSTALLATION_GUIDE.md).
