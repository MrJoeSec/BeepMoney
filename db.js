// IndexedDB Persistence Layer for BeepMoney
const DB_NAME = 'BeepMoneyDB';
const DB_VERSION = 1;

let dbInstance = null;

export async function initDB() {
  if (dbInstance) return dbInstance;

  // Request storage persistence from iOS Safari
  if (navigator.storage && navigator.storage.persist) {
    try {
      const isPersisted = await navigator.storage.persist();
      console.log('Storage persisted:', isPersisted);
    } catch (e) {
      console.warn('Storage persistence request failed:', e);
    }
  }

  return new Promise((resolve, reject) => {
    const request = indexedDB.open(DB_NAME, DB_VERSION);

    request.onupgradeneeded = (event) => {
      const db = event.target.result;

      if (!db.objectStoreNames.contains('transactions')) {
        const txStore = db.createObjectStore('transactions', { keyPath: 'id' });
        txStore.createIndex('date', 'date', { unique: false });
        txStore.createIndex('type', 'type', { unique: false });
        txStore.createIndex('category', 'category', { unique: false });
      }

      if (!db.objectStoreNames.contains('wealth')) {
        db.createObjectStore('wealth', { keyPath: 'id' });
      }

      if (!db.objectStoreNames.contains('budgets')) {
        db.createObjectStore('budgets', { keyPath: 'categoryName' });
      }

      if (!db.objectStoreNames.contains('recurring')) {
        db.createObjectStore('recurring', { keyPath: 'id' });
      }

      if (!db.objectStoreNames.contains('settings')) {
        db.createObjectStore('settings', { keyPath: 'key' });
      }

      if (!db.objectStoreNames.contains('custom_categories')) {
        db.createObjectStore('custom_categories', { keyPath: 'name' });
      }
    };

    request.onsuccess = (event) => {
      dbInstance = event.target.result;
      resolve(dbInstance);
    };

    request.onerror = (event) => {
      reject(event.target.error);
    };
  });
}

// Generic transaction helper
async function getStore(storeName, mode = 'readonly') {
  const db = await initDB();
  const tx = db.transaction(storeName, mode);
  return tx.objectStore(storeName);
}

// Transactions
export async function getAllTransactions() {
  const store = await getStore('transactions', 'readonly');
  return new Promise((resolve, reject) => {
    const request = store.getAll();
    request.onsuccess = () => {
      const items = request.result || [];
      // Sort newest first
      items.sort((a, b) => new Date(b.date) - new Date(a.date));
      resolve(items);
    };
    request.onerror = () => reject(request.error);
  });
}

export async function addTransaction(txItem) {
  const store = await getStore('transactions', 'readwrite');
  if (!txItem.id) txItem.id = 'tx_' + Date.now() + '_' + Math.random().toString(36).substr(2, 6);
  if (!txItem.createdAt) txItem.createdAt = new Date().toISOString();
  
  return new Promise((resolve, reject) => {
    const request = store.add(txItem);
    request.onsuccess = () => {
      recordUsage(txItem.category, txItem.subcategory);
      resolve(txItem);
    };
    request.onerror = () => reject(request.error);
  });
}

export async function updateTransaction(txItem) {
  const store = await getStore('transactions', 'readwrite');
  return new Promise((resolve, reject) => {
    const request = store.put(txItem);
    request.onsuccess = () => resolve(txItem);
    request.onerror = () => reject(request.error);
  });
}

export async function deleteTransaction(id) {
  const store = await getStore('transactions', 'readwrite');
  return new Promise((resolve, reject) => {
    const request = store.delete(id);
    request.onsuccess = () => resolve();
    request.onerror = () => reject(request.error);
  });
}

// Settings
export async function getSetting(key, defaultValue = null) {
  const store = await getStore('settings', 'readonly');
  return new Promise((resolve) => {
    const request = store.get(key);
    request.onsuccess = () => {
      resolve(request.result ? request.result.value : defaultValue);
    };
    request.onerror = () => resolve(defaultValue);
  });
}

export async function setSetting(key, value) {
  const store = await getStore('settings', 'readwrite');
  return new Promise((resolve, reject) => {
    const request = store.put({ key, value });
    request.onsuccess = () => resolve();
    request.onerror = () => reject(request.error);
  });
}

// Wealth Items
export async function getAllWealth() {
  const store = await getStore('wealth', 'readonly');
  return new Promise((resolve, reject) => {
    const req = store.getAll();
    req.onsuccess = () => resolve(req.result || []);
    req.onerror = () => reject(req.error);
  });
}

export async function saveWealthItem(item) {
  const store = await getStore('wealth', 'readwrite');
  if (!item.id) item.id = 'w_' + Date.now();
  item.updatedAt = new Date().toISOString();
  return new Promise((resolve, reject) => {
    const req = store.put(item);
    req.onsuccess = () => resolve(item);
    req.onerror = () => reject(req.error);
  });
}

export async function deleteWealthItem(id) {
  const store = await getStore('wealth', 'readwrite');
  return new Promise((resolve, reject) => {
    const req = store.delete(id);
    req.onsuccess = () => resolve();
    req.onerror = () => reject(req.error);
  });
}

// Budgets
export async function getAllBudgets() {
  const store = await getStore('budgets', 'readonly');
  return new Promise((resolve, reject) => {
    const req = store.getAll();
    req.onsuccess = () => resolve(req.result || []);
    req.onerror = () => reject(req.error);
  });
}

export async function saveBudget(categoryName, monthlyLimit) {
  const store = await getStore('budgets', 'readwrite');
  return new Promise((resolve, reject) => {
    const req = store.put({ categoryName, monthlyLimit: parseFloat(monthlyLimit) });
    req.onsuccess = () => resolve();
    req.onerror = () => reject(req.error);
  });
}

export async function deleteBudget(categoryName) {
  const store = await getStore('budgets', 'readwrite');
  return new Promise((resolve, reject) => {
    const req = store.delete(categoryName);
    req.onsuccess = () => resolve();
    req.onerror = () => reject(req.error);
  });
}

// Recurring
export async function getAllRecurring() {
  const store = await getStore('recurring', 'readonly');
  return new Promise((resolve, reject) => {
    const req = store.getAll();
    req.onsuccess = () => resolve(req.result || []);
    req.onerror = () => reject(req.error);
  });
}

export async function saveRecurringItem(item) {
  const store = await getStore('recurring', 'readwrite');
  if (!item.id) item.id = 'rec_' + Date.now();
  return new Promise((resolve, reject) => {
    const req = store.put(item);
    req.onsuccess = () => resolve(item);
    req.onerror = () => reject(req.error);
  });
}

export async function deleteRecurringItem(id) {
  const store = await getStore('recurring', 'readwrite');
  return new Promise((resolve, reject) => {
    const req = store.delete(id);
    req.onsuccess = () => resolve();
    req.onerror = () => reject(req.error);
  });
}

// Custom Categories
export async function getAllCustomCategories() {
  const store = await getStore('custom_categories', 'readonly');
  return new Promise((resolve, reject) => {
    const req = store.getAll();
    req.onsuccess = () => resolve(req.result || []);
    req.onerror = () => reject(req.error);
  });
}

export async function saveCustomCategory(cat) {
  const store = await getStore('custom_categories', 'readwrite');
  return new Promise((resolve, reject) => {
    const req = store.put(cat);
    req.onsuccess = () => resolve(cat);
    req.onerror = () => reject(req.error);
  });
}

export async function deleteCustomCategory(name) {
  const store = await getStore('custom_categories', 'readwrite');
  return new Promise((resolve, reject) => {
    const req = store.delete(name);
    req.onsuccess = () => resolve();
    req.onerror = () => reject(req.error);
  });
}

export async function getCustomSubcategories() {
  const data = await getSetting('custom_subcategories');
  return data ? JSON.parse(data) : {};
}

export async function saveCustomSubcategory(categoryName, subcategoryName) {
  const map = await getCustomSubcategories();
  if (!map[categoryName]) map[categoryName] = [];
  if (!map[categoryName].includes(subcategoryName)) {
    map[categoryName].push(subcategoryName);
  }
  await setSetting('custom_subcategories', JSON.stringify(map));
  return map;
}

export async function deleteCustomSubcategory(categoryName, subcategoryName) {
  const map = await getCustomSubcategories();
  if (map[categoryName]) {
    map[categoryName] = map[categoryName].filter(s => s !== subcategoryName);
    await setSetting('custom_subcategories', JSON.stringify(map));
  }
  return map;
}

// Smart Frequency Counters (LocalStorage for fast synchronous lookups)
export function recordUsage(category, subcategory) {
  try {
    const catKey = 'thebag_freq_cat';
    const subKey = 'thebag_freq_sub';
    const lastSubKey = 'thebag_last_sub';

    const catMap = JSON.parse(localStorage.getItem(catKey) || '{}');
    catMap[category] = (catMap[category] || 0) + 1;
    localStorage.setItem(catKey, JSON.stringify(catMap));

    const fullSub = `${category}:${subcategory}`;
    const subMap = JSON.parse(localStorage.getItem(subKey) || '{}');
    subMap[fullSub] = (subMap[fullSub] || 0) + 1;
    localStorage.setItem(subKey, JSON.stringify(subMap));

    const lastMap = JSON.parse(localStorage.getItem(lastSubKey) || '{}');
    lastMap[category] = subcategory;
    localStorage.setItem(lastSubKey, JSON.stringify(lastMap));
  } catch (e) {
    console.warn(e);
  }
}

export function getCategoryFrequencies() {
  try {
    return JSON.parse(localStorage.getItem('thebag_freq_cat') || '{}');
  } catch (e) {
    return {};
  }
}

export function getSubcategoryFrequencies() {
  try {
    return JSON.parse(localStorage.getItem('thebag_freq_sub') || '{}');
  } catch (e) {
    return {};
  }
}

export function getLastUsedSubcategory(category) {
  try {
    const lastMap = JSON.parse(localStorage.getItem('thebag_last_sub') || '{}');
    return lastMap[category] || null;
  } catch (e) {
    return null;
  }
}

// Backup Export & Import
export async function exportAllDataJSON() {
  const transactions = await getAllTransactions();
  const wealth = await getAllWealth();
  const budgets = await getAllBudgets();
  const recurring = await getAllRecurring();
  const customCategories = await getAllCustomCategories();

  const settingsKeys = ['hasCompletedOnboarding', 'monthlyIncome', 'incomeFrequency', 'currencyCode', 'savingsGoal', 'startingBalance', 'appLockEnabled'];
  const settingsObj = {};
  for (const k of settingsKeys) {
    settingsObj[k] = await getSetting(k);
  }

  const payload = {
    app: 'BeepMoney',
    version: '1.0.0',
    exportedAt: new Date().toISOString(),
    settings: settingsObj,
    transactions,
    wealth,
    budgets,
    recurring,
    customCategories
  };

  return JSON.stringify(payload, null, 2);
}

export async function importAllDataJSON(jsonString) {
  const data = JSON.parse(jsonString);
  if (!data || (data.app !== 'BeepMoney' && data.app !== 'TheBag')) {
    throw new Error('Invalid backup file. Must be a valid BeepMoney JSON backup.');
  }

  // Restore settings
  if (data.settings) {
    for (const [k, v] of Object.entries(data.settings)) {
      if (v !== undefined && v !== null) {
        await setSetting(k, v);
      }
    }
  }

  // Restore transactions
  if (Array.isArray(data.transactions)) {
    const store = await getStore('transactions', 'readwrite');
    for (const tx of data.transactions) {
      store.put(tx);
    }
  }

  // Restore wealth
  if (Array.isArray(data.wealth)) {
    const store = await getStore('wealth', 'readwrite');
    for (const w of data.wealth) {
      store.put(w);
    }
  }

  // Restore budgets
  if (Array.isArray(data.budgets)) {
    const store = await getStore('budgets', 'readwrite');
    for (const b of data.budgets) {
      store.put(b);
    }
  }

  // Restore recurring
  if (Array.isArray(data.recurring)) {
    const store = await getStore('recurring', 'readwrite');
    for (const r of data.recurring) {
      store.put(r);
    }
  }

  // Restore custom categories
  if (Array.isArray(data.customCategories)) {
    const store = await getStore('custom_categories', 'readwrite');
    for (const c of data.customCategories) {
      store.put(c);
    }
  }

  return true;
}

export async function exportTransactionsCSV() {
  const transactions = await getAllTransactions();
  let csv = 'Date,Type,Category,Subcategory,Amount,Merchant,Notes,IsRecurring\n';

  for (const tx of transactions) {
    const d = tx.date || '';
    const type = tx.type || 'Expense';
    const cat = `"${(tx.category || '').replace(/"/g, '""')}"`;
    const sub = `"${(tx.subcategory || '').replace(/"/g, '""')}"`;
    const amt = parseFloat(tx.amount || 0).toFixed(2);
    const merch = `"${(tx.merchant || '').replace(/"/g, '""')}"`;
    const notes = `"${(tx.notes || '').replace(/"/g, '""')}"`;
    const rec = tx.isRecurring ? 'true' : 'false';

    csv += `${d},${type},${cat},${sub},${amt},${merch},${notes},${rec}\n`;
  }
  return csv;
}

export async function clearAllLocalData() {
  const db = await initDB();
  const storeNames = ['transactions', 'wealth', 'budgets', 'recurring', 'settings', 'custom_categories'];
  for (const name of storeNames) {
    const tx = db.transaction(name, 'readwrite');
    tx.objectStore(name).clear();
  }
  localStorage.clear();
  return true;
}
