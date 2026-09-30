# BeepMoney ⚡️
### Fast, Private, Free Forever Personal Spending & Wealth Tracker for iPhone

**BeepMoney** is built around one core mandate:
**Make tracking money extremely fast and make your financial situation easy to understand.**

- **Permanent & 100% Free Forever**: Hosted directly on your GitHub Pages with zero subscription fees, no developer accounts, and no 7-day expiration limits.
- **100% Private & On-Device**: Zero cloud tracking, zero accounts, and zero servers. All records remain encrypted inside your iPhone's local `IndexedDB` chip.
- **Lightning Quick Add**: Log any expense in 5 seconds flat with the custom tactile keypad and dynamic subcategories.
- **Dynamic Factual Analytics**: Daily burn rate, projected month-end balance, savings rate, and month-over-month category trends.
- **Offline First**: Built with an offline Service Worker—works flawlessly even in Airplane mode without cellular or Wi-Fi.

---

## 📱 Live App on iPhone

Open the permanent link in **iOS Safari**:
👉 **[https://mrjoesec.github.io/BeepMoney/](https://mrjoesec.github.io/BeepMoney/)**

Then tap: **Share (`􀈂`) → Add to Home Screen (`➕`) → Add**.

---

## Architecture & File Structure

```
BeepMoney/
├── index.html               # Main iOS single-page application
├── style.css                # Apple iOS Human Interface design system (Dark & Light modes)
├── app.js                   # High-performance application controller & UI orchestrator
├── db.js                    # IndexedDB persistence layer + CSV/JSON backup engine
├── analytics.js             # Factual financial analytics & insight engine
├── manifest.json            # PWA standalone manifest configuration
├── sw.js                    # Offline Service Worker cache engine
├── icons/                   # High-resolution Apple touch icons & vector logo
│   ├── beepmoney-logo.svg   # Vector master logo
│   ├── apple-touch-icon.png # 180x180 iOS Home Screen icon
│   ├── icon-192.png         # 192x192 PWA icon
│   └── icon-512.png         # 512x512 PWA splash icon
└── README.md
```
