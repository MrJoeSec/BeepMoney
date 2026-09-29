# TheBag — Free Forever Setup & Installation Guide for iPhone 16e

This setup guarantees that **TheBag** is **100% free forever**, **never expires**, and **keeps your financial data permanently and privately on your iPhone**.

Because this runs as a high-performance **iOS Progressive Web App (PWA)** directly through iOS Safari, it is completely immune to Apple's 7-day Xcode certificate revocations and requires **no developer fees, no Mac, and no App Store approvals**.

---

## 1. Quick Start: Install on Your iPhone in 60 Seconds

### Step A: Start the App Locally (or Host It for Free)
You can run TheBag locally from your computer on your home Wi-Fi, or put it on free permanent private hosting (such as GitHub Pages or Cloudflare Pages).

#### Option 1: Run Locally on Your Home Wi-Fi (Zero Setup)
1. Open a terminal in the `TheBag` folder:
   ```bash
   python3 -m http.server 8080
   ```
2. Find your computer's local IP address (e.g. `192.168.1.50`).
3. On your iPhone, open **Safari** and go to:
   `http://192.168.1.50:8080`

#### Option 2: 1-Click Free Permanent Hosting (GitHub Pages / Cloudflare Pages)
- Push this folder to a free private GitHub repository and enable **GitHub Pages** (Settings > Pages > Deploy from branch `main`).
- Or drag-and-drop this folder into **Cloudflare Pages** or **Netlify** (100% free forever with automatic HTTPS).
- You will receive a permanent personal URL like `https://my-thebag.pages.dev`.

---

### Step B: Add to Home Screen (Instant Standalone App)
1. Open your URL in **Safari** on your iPhone 16e.
2. Tap the **Share** button (the square with an arrow pointing up at the bottom of Safari).
3. Scroll down and tap **"Add to Home Screen"**.
4. Confirm the name **TheBag** and tap **Add**.

**Result**:
- A sleek, custom **TheBag** icon appears directly on your iPhone home screen.
- When tapped, it launches **full-screen without any browser address bar, navigation buttons, or Safari borders**.
- It looks, feels, and behaves exactly like a native iOS application.

---

## 2. Why Your Data is 100% Permanent & Never Disappears

1. **Persistent Browser Storage (`IndexedDB`)**:
   - The app automatically calls `navigator.storage.persist()`, instructing iOS Safari to protect the database from automated cache purging.
   - Your transactions, account balances, budgets, and settings are saved directly in hardware storage on your phone.

2. **100% Offline via Service Worker**:
   - The included `sw.js` caches the application shell.
   - You can turn on **Airplane Mode** or travel with zero cellular service, and TheBag will still launch and record transactions instantly.

3. **1-Click Native Files App Backups**:
   - In **Settings**, tap **"Export Backup (JSON)"** or **"Export Transactions (CSV)"**.
   - iOS will prompt you to save the file directly to your iPhone's **Files app** or **iCloud Drive**.
   - You can restore your data at any time using the **"Restore from Backup"** button.

---

## 3. How to Use TheBag Day-to-Day

1. **First-Time Setup (< 60 Seconds)**:
   - When you first open the app, enter your monthly income, frequency, and currency symbol (defaults to `$`).
   - Optionally enter starting balance and savings goal.
   - Tap **"Start Tracking"**.

2. **5-to-10 Second Quick Add (Default Screen)**:
   - Tap the category (e.g., *Groceries*).
   - Tap the subcategory (e.g., *Supermarket*).
   - Punch the amount on the numeric keypad (or tap `+$10`, `+$20`, `+$50`).
   - Tap **ADD EXPENSE**.
   - A haptic tap confirms the entry with a green **"Added ✓"** banner, and resets the screen in 1 second.

3. **Dynamic Financial Analysis**:
   - Switch to the **Analysis** tab to see your dynamic burn rate, remaining spendable balance, savings rate, and factual insights based on your real spending.
   - Tap any category to drill down into subcategory breakdowns.

4. **Wealth / Net Worth**:
   - Switch to the **Wealth** tab to log your bank accounts, savings, credit cards, or loans.
   - The app calculates your real-time **Net Worth** (`Assets - Liabilities`).

5. **Passcode Security**:
   - Enable **App Passcode Lock** in Settings to lock the app whenever you close it.
