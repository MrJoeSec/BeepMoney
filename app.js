import {
  initDB,
  getAllTransactions,
  addTransaction,
  updateTransaction,
  deleteTransaction,
  getSetting,
  setSetting,
  getAllWealth,
  saveWealthItem,
  deleteWealthItem,
  getAllBudgets,
  saveBudget,
  deleteBudget,
  getAllRecurring,
  saveRecurringItem,
  deleteRecurringItem,
  getAllCustomCategories,
  saveCustomCategory,
  deleteCustomCategory,
  getCustomSubcategories,
  saveCustomSubcategory,
  deleteCustomSubcategory,
  getCategoryFrequencies,
  getSubcategoryFrequencies,
  getLastUsedSubcategory,
  exportAllDataJSON,
  importAllDataJSON,
  exportTransactionsCSV,
  clearAllLocalData
} from './db.js';

import {
  filterTransactionsByMonth,
  calculateTotalExpenses,
  calculateTotalIncome,
  calculateNetCashFlow,
  calculateSavingsRate,
  getCategoryBreakdown,
  getSubcategoryBreakdown,
  getDailyAverageSpend,
  generateDynamicInsights,
  getMonthlyTrends
} from './analytics.js';

// Base Categories & Subcategories customized for user's streamlined preferences
const BASE_EXPENSE_CATEGORIES = [
  {
    name: 'Travel',
    icon: '✈️',
    color: '#007aff',
    subcategories: ['Uber', 'Train', 'Subway', 'Bus', 'Airplane', 'Rental Car', 'Parking', 'Gas', 'Hotel', 'Other Travel']
  },
  {
    name: 'Groceries',
    icon: '🛒',
    color: '#34c759',
    subcategories: ['Supermarket', 'Online Grocery', 'Other']
  },
  {
    name: 'Eating Out',
    icon: '🍽️',
    color: '#ff9500',
    subcategories: ['Restaurant', 'Coffee', 'Activities', 'Other']
  },
  {
    name: 'Shopping',
    icon: '🛍️',
    color: '#ff2d55',
    subcategories: ['Clothes', 'Electronics', 'Accessories', 'Personal Care', 'Gifts', 'Other Shopping']
  },
  {
    name: 'Housing',
    icon: '🏠',
    color: '#5856d6',
    subcategories: ['Furniture', 'Kitchenware', 'Decorations', 'Other Housing']
  },
  {
    name: 'Bills',
    icon: '⚡',
    color: '#ff3b30',
    subcategories: ['Rent', 'Electricity', 'Subscriptions', 'Quran Class', 'Other Bills']
  },
  {
    name: 'Education',
    icon: '📚',
    color: '#00c7be',
    subcategories: ['Tuition', 'Certifications', 'Other Education']
  },
  {
    name: 'Health',
    icon: '💊',
    color: '#30b0c7',
    subcategories: ['Doctor', 'Dentist', 'Pharmacy', 'Medication', 'Fitness', 'Other Health']
  },
  {
    name: 'Personal',
    icon: '✂️',
    color: '#af52de',
    subcategories: ['Haircut', 'Clothing', 'Personal Care', 'Gifts', 'Miscellaneous']
  },
  {
    name: 'Financial',
    icon: '🏦',
    color: '#32ade6',
    subcategories: ['Investment', 'Credit Card Payment', 'Other Financial']
  },
  {
    name: 'Other',
    icon: '📦',
    color: '#8e8e93',
    subcategories: ['Miscellaneous']
  }
];

// Active array in memory that combines base + user's custom categories & subcategories
let STANDARD_EXPENSE_CATEGORIES = JSON.parse(JSON.stringify(BASE_EXPENSE_CATEGORIES));

const STANDARD_INCOME_CATEGORIES = [
  {
    name: 'Income',
    icon: '💰',
    color: '#34c759',
    subcategories: ['Salary', 'Freelance', 'Business', 'Side Job', 'Investment', 'Gift', 'Refund', 'Other Income']
  }
];

// Currency locked in USD
const CURRENCY_SYMBOLS = { USD: '$' };

// Global App State
const state = {
  currencyCode: 'USD',
  currencySymbol: '$',
  monthlyIncome: 5000,
  incomeFrequency: 'Monthly',
  savingsGoal: 1000,
  startingBalance: 0,
  appLockEnabled: false,
  isUnlocked: true,
  passcode: '1234',
  passcodeInput: '',
  
  // Quick Add State
  currentType: 'Expense',
  amountStr: '0',
  selectedCategory: 'Groceries',
  selectedSubcategory: 'Supermarket',
  merchant: '',
  notes: '',
  transactionDate: new Date(),
  isRecurring: false,
  
  // Analysis State
  analysisMonth: new Date().getMonth() + 1,
  analysisYear: new Date().getFullYear(),
  chartType: 'donut',
  
  // Transactions State
  txSearchQuery: '',
  txFilterType: 'All',
  
  // Cache
  allTransactions: [],
  allWealth: [],
  allBudgets: [],
  allRecurring: []
};

// Utility: Trigger light device haptic
function triggerHaptic(type = 'light') {
  if (navigator.vibrate) {
    if (type === 'success') navigator.vibrate([15, 40, 20]);
    else if (type === 'heavy') navigator.vibrate([30]);
    else navigator.vibrate(12);
  }
}

// Currency formatter
function formatCurrency(amt, showSign = false) {
  const symbol = state.currencySymbol;
  const num = parseFloat(amt) || 0;
  const absFormatted = Math.abs(num).toLocaleString('en-US', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  });
  if (showSign) {
    if (num > 0) return `+${symbol}${absFormatted}`;
    if (num < 0) return `-${symbol}${absFormatted}`;
  }
  return num < 0 ? `-${symbol}${absFormatted}` : `${symbol}${absFormatted}`;
}

function formatWholeCurrency(amt) {
  const symbol = state.currencySymbol;
  const num = Math.round(parseFloat(amt) || 0);
  return `${symbol}${num.toLocaleString('en-US')}`;
}

// Service Worker Registration for 100% Offline Support
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('./sw.js').then((reg) => {
      console.log('TheBag Service Worker active:', reg.scope);
    }).catch(err => {
      console.log('Service Worker registration skipped:', err);
    });
  });
}

// Initialize Application
document.addEventListener('DOMContentLoaded', async () => {
  await initDB();
  await loadAllCategoriesAndSubcategories();
  await loadSettings();
  setupNavigation();
  setupQuickAdd();
  setupTransactionsScreen();
  setupAnalysisScreen();
  setupSettingsScreen();
  setupLockScreen();
  setupBudgetsModal();
  setupRecurringModal();
  setupCustomCategoriesModal();

  const onboarded = await getSetting('hasCompletedOnboarding');
  if (!onboarded) {
    showOnboarding();
  } else {
    if (state.appLockEnabled) {
      showLockScreen();
    }
  }

  await refreshAllData();
});

// Load and combine base categories + user custom categories & subcategories
async function loadAllCategoriesAndSubcategories() {
  STANDARD_EXPENSE_CATEGORIES = JSON.parse(JSON.stringify(BASE_EXPENSE_CATEGORIES));

  // Merge custom categories from DB
  const customCats = await getAllCustomCategories();
  customCats.forEach(cc => {
    if (!STANDARD_EXPENSE_CATEGORIES.some(c => c.name.toLowerCase() === cc.name.toLowerCase())) {
      STANDARD_EXPENSE_CATEGORIES.push({
        name: cc.name,
        icon: cc.icon || '🏷️',
        color: cc.color || '#af52de',
        subcategories: Array.isArray(cc.subcategories) ? cc.subcategories : ['General'],
        isCustom: true
      });
    }
  });

  // Merge custom subcategories added to any category
  const customSubMap = await getCustomSubcategories();
  STANDARD_EXPENSE_CATEGORIES.forEach(cat => {
    const extraSubs = customSubMap[cat.name] || [];
    extraSubs.forEach(sub => {
      if (!cat.subcategories.includes(sub)) {
        cat.subcategories.push(sub);
      }
    });
  });
}

// Load Settings from DB (Locked in USD)
async function loadSettings() {
  state.currencyCode = 'USD';
  state.currencySymbol = '$';
  state.monthlyIncome = parseFloat(await getSetting('monthlyIncome')) || 5000;
  state.incomeFrequency = (await getSetting('incomeFrequency')) || 'Monthly';
  state.savingsGoal = parseFloat(await getSetting('savingsGoal')) || 1000;
  state.startingBalance = parseFloat(await getSetting('startingBalance')) || 0;
  state.appLockEnabled = (await getSetting('appLockEnabled')) || false;
  state.passcode = (await getSetting('passcode')) || '1234';

  updateCurrencyDisplays();
}

function updateCurrencyDisplays() {
  const curSymbolEl = document.getElementById('quickadd-currency-symbol');
  if (curSymbolEl) curSymbolEl.textContent = state.currencySymbol;
  
  const onboardSymEl = document.getElementById('onboard-symbol');
  if (onboardSymEl) onboardSymEl.textContent = state.currencySymbol;
  
  const setPrefixEl = document.getElementById('settings-symbol-prefix');
  if (setPrefixEl) setPrefixEl.textContent = state.currencySymbol;
}

// Tab Navigation
function setupNavigation() {
  const tabButtons = document.querySelectorAll('.tab-btn');
  const screens = document.querySelectorAll('.screen');

  tabButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      triggerHaptic('light');
      const targetId = btn.getAttribute('data-target');

      tabButtons.forEach(b => b.classList.remove('active'));
      screens.forEach(s => s.classList.remove('active'));

      btn.classList.add('active');
      const targetScreen = document.getElementById(targetId);
      if (targetScreen) targetScreen.classList.add('active');

      if (targetId === 'screen-transactions') renderTransactionsList();
      if (targetId === 'screen-analysis') renderAnalysisDashboard();
    });
  });
}

// ---------------------------------------------------------------------------
// QUICK ADD SCREEN
// ---------------------------------------------------------------------------
function setupQuickAdd() {
  // Update header date
  const now = new Date();
  const dateStr = now.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' });
  const dateHeader = document.getElementById('quickadd-date');
  if (dateHeader) dateHeader.textContent = `Today, ${dateStr}`;

  // Type segmented control (Expense / Income)
  const typeBtns = document.querySelectorAll('.type-btn');
  typeBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      triggerHaptic('light');
      typeBtns.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      state.currentType = btn.getAttribute('data-type');
      
      const label = document.getElementById('category-section-label');
      const addBtnText = document.getElementById('add-btn-text');
      if (state.currentType === 'Expense') {
        if (label) label.textContent = 'What did you spend on?';
        if (addBtnText) addBtnText.textContent = 'ADD EXPENSE';
      } else {
        if (label) label.textContent = 'Income Source';
        if (addBtnText) addBtnText.textContent = 'ADD INCOME';
      }
      renderCategoryChips();
    });
  });

  // Numeric Keypad
  const numKeys = document.querySelectorAll('.num-key[data-val]');
  numKeys.forEach(k => {
    k.addEventListener('click', () => {
      triggerHaptic('light');
      const val = k.getAttribute('data-val');
      handleKeypadInput(val);
    });
  });

  const backspaceKey = document.getElementById('key-backspace');
  if (backspaceKey) {
    backspaceKey.addEventListener('click', () => {
      triggerHaptic('light');
      handleKeypadBackspace();
    });
  }

  const clearKey = document.getElementById('key-clear');
  if (clearKey) {
    clearKey.addEventListener('click', () => {
      triggerHaptic('light');
      state.amountStr = '0';
      updateAmountDisplay();
    });
  }

  // Quick additive chips (+$5, +$10, +$20, +$50)
  const quickAmtBtns = document.querySelectorAll('.quick-amt-btn[data-add]');
  quickAmtBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      triggerHaptic('light');
      const addVal = parseFloat(btn.getAttribute('data-add')) || 0;
      const current = parseFloat(state.amountStr) || 0;
      const sum = current + addVal;
      state.amountStr = (sum % 1 === 0) ? String(sum) : sum.toFixed(2);
      updateAmountDisplay();
    });
  });

  // More Details Sheet
  const btnDetails = document.getElementById('btn-open-details');
  const modalDetails = document.getElementById('modal-details');
  const btnCloseDetails = document.getElementById('btn-close-details');
  if (btnDetails && modalDetails) {
    btnDetails.addEventListener('click', () => {
      modalDetails.classList.remove('hidden');
      const dateInput = document.getElementById('details-date');
      if (dateInput) {
        const localISO = new Date(now.getTime() - now.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
        dateInput.value = localISO;
      }
    });
  }
  if (btnCloseDetails && modalDetails) {
    btnCloseDetails.addEventListener('click', () => {
      const merchantInput = document.getElementById('details-merchant');
      const notesInput = document.getElementById('details-notes');
      const dateInput = document.getElementById('details-date');
      const recurringInput = document.getElementById('details-recurring');

      if (merchantInput) state.merchant = merchantInput.value;
      if (notesInput) state.notes = notesInput.value;
      if (dateInput && dateInput.value) state.transactionDate = new Date(dateInput.value);
      if (recurringInput) state.isRecurring = recurringInput.checked;

      modalDetails.classList.add('hidden');
    });
  }

  // Add Transaction Button
  const btnAdd = document.getElementById('btn-commit-transaction');
  if (btnAdd) {
    btnAdd.addEventListener('click', async () => {
      await commitQuickAddTransaction();
    });
  }

  renderCategoryChips();

  // Enable desktop horizontal mouse wheel scroll & click-and-drag
  enableHorizontalScroll(document.getElementById('category-chips-container'));
  enableHorizontalScroll(document.getElementById('subcategory-chips-container'));
}

function enableHorizontalScroll(container) {
  if (!container || container._hasHScroll) return;
  container._hasHScroll = true;

  // Convert standard mouse wheel to horizontal scroll
  container.addEventListener('wheel', (e) => {
    if (e.deltaY !== 0) {
      e.preventDefault();
      container.scrollLeft += e.deltaY;
    }
  }, { passive: false });

  // Click & drag to scroll
  let isDown = false;
  let startX = 0;
  let scrollLeft = 0;

  container.addEventListener('mousedown', (e) => {
    isDown = true;
    startX = e.pageX - container.offsetLeft;
    scrollLeft = container.scrollLeft;
    container.style.cursor = 'grabbing';
  });

  window.addEventListener('mouseup', () => {
    isDown = false;
    if (container) container.style.cursor = 'grab';
  });

  container.addEventListener('mousemove', (e) => {
    if (!isDown) return;
    e.preventDefault();
    const x = e.pageX - container.offsetLeft;
    const walk = (x - startX) * 1.5;
    container.scrollLeft = scrollLeft - walk;
  });

  container.style.cursor = 'grab';
}

function handleKeypadInput(val) {
  if (val === '.') {
    if (!state.amountStr.includes('.')) {
      state.amountStr += '.';
    }
  } else {
    if (state.amountStr === '0') {
      state.amountStr = val;
    } else {
      // Limit to 2 decimal places
      if (state.amountStr.includes('.')) {
        const parts = state.amountStr.split('.');
        if (parts[1].length >= 2) return;
      }
      if (state.amountStr.length < 9) {
        state.amountStr += val;
      }
    }
  }
  updateAmountDisplay();
}

function handleKeypadBackspace() {
  if (state.amountStr.length > 1) {
    state.amountStr = state.amountStr.slice(0, -1);
  } else {
    state.amountStr = '0';
  }
  updateAmountDisplay();
}

function updateAmountDisplay() {
  const el = document.getElementById('quickadd-amount');
  const btn = document.getElementById('btn-commit-transaction');
  if (el) el.textContent = state.amountStr;

  const amt = parseFloat(state.amountStr);
  if (btn) {
    btn.disabled = !(amt > 0);
  }
}

// Render Category Chips sorted by local frequency
function renderCategoryChips() {
  const container = document.getElementById('category-chips-container');
  if (!container) return;

  container.innerHTML = '';
  const categoriesList = state.currentType === 'Expense' ? STANDARD_EXPENSE_CATEGORIES : STANDARD_INCOME_CATEGORIES;
  const freqs = getCategoryFrequencies();

  // Sort by frequency
  const sorted = [...categoriesList].sort((a, b) => (freqs[b.name] || 0) - (freqs[a.name] || 0));

  if (!sorted.some(c => c.name.toLowerCase() === state.selectedCategory.toLowerCase())) {
    state.selectedCategory = sorted[0].name;
  }

  sorted.forEach(cat => {
    const chip = document.createElement('button');
    chip.type = 'button';
    chip.className = `cat-chip ${cat.name.toLowerCase() === state.selectedCategory.toLowerCase() ? 'active' : ''}`;
    chip.innerHTML = `<span>${cat.icon}</span><span>${cat.name}</span>`;
    chip.addEventListener('click', () => {
      triggerHaptic('light');
      state.selectedCategory = cat.name;
      const lastSub = getLastUsedSubcategory(cat.name);
      state.selectedSubcategory = lastSub || cat.subcategories[0] || cat.name;
      renderCategoryChips();
    });
    container.appendChild(chip);
  });

  renderSubcategoryChips();
}

// Render Subcategory Chips
function renderSubcategoryChips() {
  const container = document.getElementById('subcategory-chips-container');
  if (!container) return;

  container.innerHTML = '';
  const categoriesList = state.currentType === 'Expense' ? STANDARD_EXPENSE_CATEGORIES : STANDARD_INCOME_CATEGORIES;
  const found = categoriesList.find(c => c.name.toLowerCase() === state.selectedCategory.toLowerCase());
  const subs = found ? found.subcategories : [];

  if (!subs.includes(state.selectedSubcategory) && subs.length > 0) {
    state.selectedSubcategory = subs[0];
  }

  subs.forEach(sub => {
    const chip = document.createElement('button');
    chip.type = 'button';
    chip.className = `sub-chip ${sub.toLowerCase() === state.selectedSubcategory.toLowerCase() ? 'active' : ''}`;
    chip.textContent = sub;
    chip.addEventListener('click', () => {
      triggerHaptic('light');
      state.selectedSubcategory = sub;
      renderSubcategoryChips();
    });
    container.appendChild(chip);
  });
}

// Commit Transaction to DB
async function commitQuickAddTransaction() {
  const amt = parseFloat(state.amountStr);
  if (!amt || amt <= 0) return;

  triggerHaptic('success');

  const newTx = {
    amount: amt,
    type: state.currentType,
    category: state.selectedCategory,
    subcategory: state.selectedSubcategory,
    date: state.transactionDate.toISOString(),
    merchant: state.merchant,
    notes: state.notes,
    isRecurring: state.isRecurring
  };

  await addTransaction(newTx);
  await refreshAllData();

  // Show "Added ✓" banner
  showToast(`${state.selectedSubcategory} ${formatCurrency(amt)} Added ✓`);

  // Instant reset for the next rapid entry
  state.amountStr = '0';
  state.merchant = '';
  state.notes = '';
  state.transactionDate = new Date();
  state.isRecurring = false;
  updateAmountDisplay();
  renderCategoryChips();
}

function showToast(msg) {
  const toast = document.getElementById('quickadd-toast');
  const msgEl = document.getElementById('toast-message');
  if (toast && msgEl) {
    msgEl.textContent = msg;
    toast.classList.remove('hidden');
    setTimeout(() => {
      toast.classList.add('hidden');
    }, 1500);
  }
}

// ---------------------------------------------------------------------------
// TRANSACTIONS SCREEN
// ---------------------------------------------------------------------------
function setupTransactionsScreen() {
  const searchInput = document.getElementById('tx-search-input');
  if (searchInput) {
    searchInput.addEventListener('input', (e) => {
      state.txSearchQuery = e.target.value.toLowerCase().trim();
      renderTransactionsList();
    });
  }

  const filterPills = document.querySelectorAll('.filter-pill');
  filterPills.forEach(p => {
    p.addEventListener('click', () => {
      triggerHaptic('light');
      filterPills.forEach(b => b.classList.remove('active'));
      p.classList.add('active');
      state.txFilterType = p.getAttribute('data-filter');
      renderTransactionsList();
    });
  });

  // Setup Edit Transaction Modal
  const btnCloseEdit = document.getElementById('btn-close-edit-tx');
  const modalEdit = document.getElementById('modal-edit-tx');
  const formEdit = document.getElementById('form-edit-tx');
  const btnDelete = document.getElementById('btn-delete-tx');

  if (btnCloseEdit && modalEdit) {
    btnCloseEdit.addEventListener('click', () => modalEdit.classList.add('hidden'));
  }

  if (formEdit) {
    formEdit.addEventListener('submit', async (e) => {
      e.preventDefault();
      const id = document.getElementById('edit-tx-id').value;
      const tx = state.allTransactions.find(t => t.id === id);
      if (!tx) return;

      tx.type = document.getElementById('edit-tx-type').value;
      tx.amount = parseFloat(document.getElementById('edit-tx-amount').value) || 0;
      tx.category = document.getElementById('edit-tx-category').value;
      tx.subcategory = document.getElementById('edit-tx-subcategory').value;
      tx.merchant = document.getElementById('edit-tx-merchant').value;
      tx.notes = document.getElementById('edit-tx-notes').value;
      const dateVal = document.getElementById('edit-tx-date').value;
      if (dateVal) tx.date = new Date(dateVal).toISOString();

      await updateTransaction(tx);
      await refreshAllData();
      modalEdit.classList.add('hidden');
      renderTransactionsList();
    });
  }

  if (btnDelete) {
    btnDelete.addEventListener('click', async () => {
      if (confirm('Are you sure you want to delete this transaction?')) {
        const id = document.getElementById('edit-tx-id').value;
        await deleteTransaction(id);
        await refreshAllData();
        modalEdit.classList.add('hidden');
        renderTransactionsList();
      }
    });
  }
}

function renderTransactionsList() {
  const container = document.getElementById('tx-list-container');
  if (!container) return;

  container.innerHTML = '';

  let list = state.allTransactions.filter(tx => {
    if (state.txFilterType === 'Expense' && (tx.type || '').toLowerCase() !== 'expense') return false;
    if (state.txFilterType === 'Income' && (tx.type || '').toLowerCase() !== 'income') return false;
    
    if (state.txSearchQuery) {
      const q = state.txSearchQuery;
      const cat = (tx.category || '').toLowerCase();
      const sub = (tx.subcategory || '').toLowerCase();
      const merch = (tx.merchant || '').toLowerCase();
      const notes = (tx.notes || '').toLowerCase();
      const amt = String(tx.amount || '');
      return cat.includes(q) || sub.includes(q) || merch.includes(q) || notes.includes(q) || amt.includes(q);
    }
    return true;
  });

  if (list.length === 0) {
    container.innerHTML = `
      <div style="text-align:center; padding: 40px 16px; color: var(--text-secondary);">
        <div style="font-size:36px; margin-bottom:8px;">📥</div>
        <div style="font-size:16px; font-weight:600;">No transactions found</div>
        <div style="font-size:13px; margin-top:4px;">Use Quick Add to record an expense or income.</div>
      </div>
    `;
    return;
  }

  // Group by date
  const groups = {};
  const todayStr = new Date().toDateString();
  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);
  const yesterdayStr = yesterday.toDateString();

  list.forEach(tx => {
    const d = new Date(tx.date);
    let label;
    if (d.toDateString() === todayStr) label = 'Today';
    else if (d.toDateString() === yesterdayStr) label = 'Yesterday';
    else label = d.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric', year: 'numeric' });

    if (!groups[label]) groups[label] = [];
    groups[label].push(tx);
  });

  for (const [dateLabel, items] of Object.entries(groups)) {
    const groupBlock = document.createElement('div');
    groupBlock.innerHTML = `<div class="tx-date-group-title">${dateLabel}</div>`;

    const itemsWrapper = document.createElement('div');
    itemsWrapper.style.display = 'flex';
    itemsWrapper.style.flexDirection = 'column';
    itemsWrapper.style.gap = '8px';

    items.forEach(tx => {
      const isExpense = (tx.type || '').toLowerCase() === 'expense';
      const catDef = STANDARD_EXPENSE_CATEGORIES.find(c => c.name.toLowerCase() === (tx.category || '').toLowerCase());
      const icon = catDef ? catDef.icon : (isExpense ? '🏷️' : '💰');
      
      const card = document.createElement('div');
      card.className = 'tx-card';
      card.innerHTML = `
        <div class="tx-icon-box">${icon}</div>
        <div class="tx-info">
          <div class="tx-title">${tx.merchant || tx.subcategory || tx.category}</div>
          <div class="tx-sub">${tx.category}${tx.notes ? ' • ' + tx.notes : ''}</div>
        </div>
        <div class="tx-amount ${isExpense ? 'expense' : 'income'}">
          ${isExpense ? '-' : '+'}${formatCurrency(tx.amount)}
        </div>
      `;

      card.addEventListener('click', () => {
        openEditTxModal(tx);
      });

      itemsWrapper.appendChild(card);
    });

    groupBlock.appendChild(itemsWrapper);
    container.appendChild(groupBlock);
  }
}

function openEditTxModal(tx) {
  const modal = document.getElementById('modal-edit-tx');
  if (!modal) return;

  document.getElementById('edit-tx-id').value = tx.id;
  document.getElementById('edit-tx-type').value = tx.type || 'Expense';
  document.getElementById('edit-tx-amount').value = tx.amount;

  const catSelect = document.getElementById('edit-tx-category');
  catSelect.innerHTML = '';
  const list = (tx.type || '').toLowerCase() === 'expense' ? STANDARD_EXPENSE_CATEGORIES : STANDARD_INCOME_CATEGORIES;
  list.forEach(c => {
    const opt = document.createElement('option');
    opt.value = c.name;
    opt.textContent = c.name;
    if (c.name.toLowerCase() === (tx.category || '').toLowerCase()) opt.selected = true;
    catSelect.appendChild(opt);
  });

  document.getElementById('edit-tx-subcategory').value = tx.subcategory || '';
  document.getElementById('edit-tx-merchant').value = tx.merchant || '';
  document.getElementById('edit-tx-notes').value = tx.notes || '';
  
  if (tx.date) {
    const d = new Date(tx.date);
    const localISO = new Date(d.getTime() - d.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
    document.getElementById('edit-tx-date').value = localISO;
  }

  modal.classList.remove('hidden');
}

// ---------------------------------------------------------------------------
// ANALYSIS DASHBOARD SCREEN
// ---------------------------------------------------------------------------
function setupAnalysisScreen() {
  const btnPrev = document.getElementById('btn-prev-month');
  const btnNext = document.getElementById('btn-next-month');

  if (btnPrev) {
    btnPrev.addEventListener('click', () => {
      triggerHaptic('light');
      if (state.analysisMonth === 1) {
        state.analysisMonth = 12;
        state.analysisYear -= 1;
      } else {
        state.analysisMonth -= 1;
      }
      renderAnalysisDashboard();
    });
  }

  if (btnNext) {
    btnNext.addEventListener('click', () => {
      triggerHaptic('light');
      if (state.analysisMonth === 12) {
        state.analysisMonth = 1;
        state.analysisYear += 1;
      } else {
        state.analysisMonth += 1;
      }
      renderAnalysisDashboard();
    });
  }

  // Chart type toggle
  const chartBtns = document.querySelectorAll('.chart-toggle-btn');
  chartBtns.forEach(b => {
    b.addEventListener('click', () => {
      chartBtns.forEach(x => x.classList.remove('active'));
      b.classList.add('active');
      state.chartType = b.getAttribute('data-chart');
      renderAnalysisDashboard();
    });
  });

  // Quick Action Buttons
  const btnTrends = document.getElementById('btn-open-trends');
  const modalTrends = document.getElementById('modal-trends');
  const btnCloseTrends = document.getElementById('btn-close-trends');
  if (btnTrends && modalTrends) {
    btnTrends.addEventListener('click', () => {
      modalTrends.classList.remove('hidden');
      renderTrendsModal();
    });
  }
  if (btnCloseTrends && modalTrends) {
    btnCloseTrends.addEventListener('click', () => modalTrends.classList.add('hidden'));
  }

  const btnSummary = document.getElementById('btn-open-summary');
  const modalSummary = document.getElementById('modal-summary');
  const btnCloseSummary = document.getElementById('btn-close-summary');
  if (btnSummary && modalSummary) {
    btnSummary.addEventListener('click', () => {
      modalSummary.classList.remove('hidden');
      renderSummaryModal();
    });
  }
  if (btnCloseSummary && modalSummary) {
    btnCloseSummary.addEventListener('click', () => modalSummary.classList.add('hidden'));
  }

  const btnCloseDrilldown = document.getElementById('btn-close-drilldown');
  const modalDrilldown = document.getElementById('modal-category-drilldown');
  if (btnCloseDrilldown && modalDrilldown) {
    btnCloseDrilldown.addEventListener('click', () => modalDrilldown.classList.add('hidden'));
  }
}

function renderAnalysisDashboard() {
  const d = new Date(state.analysisYear, state.analysisMonth - 1, 1);
  const monthName = d.toLocaleDateString('en-US', { month: 'long', year: 'numeric' });
  const label = document.getElementById('analysis-month-label');
  if (label) label.textContent = monthName;

  const monthItems = filterTransactionsByMonth(state.allTransactions, state.analysisMonth, state.analysisYear);
  const spent = calculateTotalExpenses(monthItems);
  const income = calculateTotalIncome(monthItems, state.monthlyIncome);
  const remaining = income - spent;
  const savingsRate = calculateSavingsRate(income, spent);

  // Top cards
  const elIncome = document.getElementById('stat-income');
  const elSpent = document.getElementById('stat-spent');
  const elRemaining = document.getElementById('stat-remaining');
  const elRemSub = document.getElementById('stat-remaining-sub');
  const elRate = document.getElementById('stat-savings-rate');
  const elRateSub = document.getElementById('stat-savings-sub');

  if (elIncome) elIncome.textContent = formatWholeCurrency(income);
  if (elSpent) elSpent.textContent = formatWholeCurrency(spent);
  if (elRemaining) {
    elRemaining.textContent = formatWholeCurrency(remaining);
    elRemaining.className = `stat-value ${remaining >= 0 ? 'text-green' : 'text-red'}`;
  }
  if (elRemSub) elRemSub.textContent = remaining >= 0 ? 'Under Income' : 'Over Income';
  if (elRate) elRate.textContent = `${Math.round(savingsRate)}%`;
  if (elRateSub) elRateSub.textContent = savingsRate >= 20 ? 'On Track' : (savingsRate >= 0 ? 'Moderate' : 'Negative');

  // Dynamic Financial Analysis Insights
  const insightsContainer = document.getElementById('dynamic-insights-list');
  if (insightsContainer) {
    const insights = generateDynamicInsights(
      state.allTransactions,
      state.analysisMonth,
      state.analysisYear,
      state.monthlyIncome,
      formatCurrency
    );

    insightsContainer.innerHTML = insights.map(i => `
      <div class="insight-bubble">
        <span class="insight-icon">${i.icon}</span>
        <div class="insight-content">
          <h4>${i.title}</h4>
          <p>${i.message}</p>
        </div>
      </div>
    `).join('');
  }

  // Category Breakdown & Chart
  const breakdown = getCategoryBreakdown(monthItems);
  renderCategoryChart(breakdown);
  renderCategoryBreakdownList(breakdown, monthItems);
}

function renderCategoryChart(breakdown) {
  const canvas = document.getElementById('category-chart-canvas');
  if (!canvas) return;
  const ctx = canvas.getContext('2d');
  ctx.clearRect(0, 0, canvas.width, canvas.height);

  if (breakdown.length === 0) {
    ctx.fillStyle = '#8e8e93';
    ctx.font = '14px -apple-system, sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('No expenses recorded for this month', canvas.width / 2, canvas.height / 2);
    return;
  }

  const colors = ['#007aff', '#34c759', '#ff9500', '#ff2d55', '#5856d6', '#ff3b30', '#00c7be', '#af52de', '#32ade6', '#8e8e93'];

  if (state.chartType === 'donut') {
    const centerX = canvas.width / 2;
    const centerY = canvas.height / 2;
    const radius = 80;
    const innerRadius = 50;

    let startAngle = -Math.PI / 2;
    const total = breakdown.reduce((sum, b) => sum + b.amount, 0);

    breakdown.forEach((item, index) => {
      const sliceAngle = (item.amount / total) * 2 * Math.PI;
      ctx.beginPath();
      ctx.arc(centerX, centerY, radius, startAngle, startAngle + sliceAngle);
      ctx.arc(centerX, centerY, innerRadius, startAngle + sliceAngle, startAngle, true);
      ctx.closePath();
      ctx.fillStyle = colors[index % colors.length];
      ctx.fill();
      startAngle += sliceAngle;
    });

    // Center total
    ctx.fillStyle = getComputedStyle(document.body).color;
    ctx.font = 'bold 16px -apple-system, sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText(formatWholeCurrency(total), centerX, centerY + 6);
  } else {
    // Horizontal Bar Chart
    const barHeight = 16;
    const gap = 10;
    const maxAmt = breakdown[0].amount || 1;
    let y = 16;

    breakdown.slice(0, 5).forEach((item, index) => {
      const w = ((item.amount / maxAmt) * (canvas.width - 130));
      ctx.fillStyle = colors[index % colors.length];
      ctx.beginPath();
      ctx.roundRect(110, y, Math.max(8, w), barHeight, 4);
      ctx.fill();

      // Label
      ctx.fillStyle = '#8e8e93';
      ctx.font = '12px -apple-system, sans-serif';
      ctx.textAlign = 'right';
      ctx.fillText(item.category.slice(0, 12), 100, y + 12);

      // Amount
      ctx.textAlign = 'left';
      ctx.fillText(formatWholeCurrency(item.amount), 118 + w, y + 12);

      y += barHeight + gap;
    });
  }
}

function renderCategoryBreakdownList(breakdown, monthItems) {
  const container = document.getElementById('category-breakdown-list');
  if (!container) return;
  container.innerHTML = '';

  const colors = ['#007aff', '#34c759', '#ff9500', '#ff2d55', '#5856d6', '#ff3b30', '#00c7be', '#af52de', '#32ade6', '#8e8e93'];

  breakdown.forEach((cat, index) => {
    const row = document.createElement('div');
    row.className = 'cat-breakdown-row';
    row.innerHTML = `
      <div class="cat-breakdown-left">
        <span class="cat-bullet" style="background-color: ${colors[index % colors.length]};"></span>
        <span class="cat-name-label">${cat.category}</span>
      </div>
      <div class="cat-breakdown-right">
        <div class="cat-amount-label">${formatCurrency(cat.amount)}</div>
        <div class="cat-pct-label">${cat.percentage.toFixed(1)}% • ${cat.count} tx</div>
      </div>
    `;

    row.addEventListener('click', () => {
      openCategoryDrilldown(cat.category, monthItems);
    });

    container.appendChild(row);
  });
}

// Category Drilldown Sheet
function openCategoryDrilldown(categoryName, monthItems) {
  const modal = document.getElementById('modal-category-drilldown');
  if (!modal) return;

  const catDef = STANDARD_EXPENSE_CATEGORIES.find(c => c.name.toLowerCase() === categoryName.toLowerCase());
  const icon = catDef ? catDef.icon : '🏷️';
  
  const txs = monthItems.filter(t => (t.category || '').toLowerCase() === categoryName.toLowerCase());
  const total = txs.reduce((s, t) => s + parseFloat(t.amount || 0), 0);
  const totalMonth = calculateTotalExpenses(monthItems);
  const pct = totalMonth > 0 ? (total / totalMonth) * 100 : 0;

  document.getElementById('drilldown-icon').textContent = icon;
  document.getElementById('drilldown-cat-name').textContent = categoryName;
  document.getElementById('drilldown-total').textContent = formatCurrency(total);
  document.getElementById('drilldown-tx-count').textContent = `${txs.length} transactions`;
  document.getElementById('drilldown-pct').textContent = `${pct.toFixed(1)}% of spending`;

  // Subcategories
  const subContainer = document.getElementById('drilldown-subcategories-list');
  const subs = getSubcategoryBreakdown(monthItems, categoryName);
  subContainer.innerHTML = subs.map(s => `
    <div style="display:flex; justify-content:space-between; padding:6px 0; border-bottom:0.5px solid var(--border-color);">
      <span>${s.subcategory} (${s.count})</span>
      <strong>${formatCurrency(s.amount)}</strong>
    </div>
  `).join('');

  // Transactions list
  const txContainer = document.getElementById('drilldown-tx-list');
  txContainer.innerHTML = txs.map(t => `
    <div style="display:flex; justify-content:space-between; padding:8px 0; border-bottom:0.5px solid var(--border-color);">
      <div>
        <div style="font-weight:600;">${t.merchant || t.subcategory || t.category}</div>
        <div style="font-size:12px; color:var(--text-secondary);">${new Date(t.date).toLocaleDateString()}</div>
      </div>
      <div style="font-weight:700;">${formatCurrency(t.amount)}</div>
    </div>
  `).join('');

  modal.classList.remove('hidden');
}

// Trends Modal
function renderTrendsModal() {
  const trends = getMonthlyTrends(state.allTransactions, 6, state.monthlyIncome);
  const canvas = document.getElementById('trends-chart-canvas');
  if (canvas) {
    const ctx = canvas.getContext('2d');
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    const maxSpend = Math.max(...trends.map(t => Math.max(t.spent, t.income)), 100);
    const stepX = (canvas.width - 40) / (trends.length - 1 || 1);
    
    // Draw line for spending
    ctx.beginPath();
    ctx.strokeStyle = '#007aff';
    ctx.lineWidth = 3;
    trends.forEach((t, i) => {
      const x = 20 + i * stepX;
      const y = canvas.height - 30 - (t.spent / maxSpend) * (canvas.height - 60);
      if (i === 0) ctx.moveTo(x, y);
      else ctx.lineTo(x, y);
    });
    ctx.stroke();

    // Draw points & labels
    trends.forEach((t, i) => {
      const x = 20 + i * stepX;
      const y = canvas.height - 30 - (t.spent / maxSpend) * (canvas.height - 60);
      ctx.fillStyle = '#007aff';
      ctx.beginPath();
      ctx.arc(x, y, 4, 0, 2 * Math.PI);
      ctx.fill();

      ctx.fillStyle = '#8e8e93';
      ctx.font = '11px -apple-system, sans-serif';
      ctx.textAlign = 'center';
      ctx.fillText(t.monthLabel, x, canvas.height - 10);
    });
  }

  const listContainer = document.getElementById('trends-month-list');
  if (listContainer) {
    listContainer.innerHTML = trends.map(t => `
      <div style="display:flex; justify-content:space-between; padding:8px 0; border-bottom:0.5px solid var(--border-color);">
        <span>${t.monthLabel}</span>
        <span>${formatCurrency(t.spent)} spent</span>
      </div>
    `).join('');
  }

  const dailyAvg = getDailyAverageSpend(calculateTotalExpenses(state.allTransactions), state.analysisMonth, state.analysisYear);
  const dailyAvgEl = document.getElementById('trends-daily-avg');
  if (dailyAvgEl) dailyAvgEl.textContent = formatCurrency(dailyAvg);

  const nonZero = trends.filter(t => t.spent > 0);
  const avgMonthly = nonZero.length > 0 ? nonZero.reduce((s, t) => s + t.spent, 0) / nonZero.length : 0;
  const monthlyAvgEl = document.getElementById('trends-monthly-avg');
  if (monthlyAvgEl) monthlyAvgEl.textContent = formatCurrency(avgMonthly);
}

// Summary Modal
function renderSummaryModal() {
  const d = new Date(state.analysisYear, state.analysisMonth - 1, 1);
  const monthName = d.toLocaleDateString('en-US', { month: 'long', year: 'numeric' });
  document.getElementById('summary-month-heading').textContent = monthName;

  const monthItems = filterTransactionsByMonth(state.allTransactions, state.analysisMonth, state.analysisYear);
  const spent = calculateTotalExpenses(monthItems);
  const income = calculateTotalIncome(monthItems, state.monthlyIncome);
  const net = income - spent;
  const rate = calculateSavingsRate(income, spent);

  document.getElementById('sum-income').textContent = formatCurrency(income);
  document.getElementById('sum-spent').textContent = formatCurrency(spent);
  document.getElementById('sum-net').textContent = formatCurrency(net, true);
  document.getElementById('sum-rate').textContent = `${Math.round(rate)}%`;

  const topCats = getCategoryBreakdown(monthItems).slice(0, 3);
  const topList = document.getElementById('sum-top-categories');
  topList.innerHTML = topCats.map((c, i) => `
    <li style="margin-left: 20px; padding: 3px 0;">${c.category} — ${formatCurrency(c.amount)} (${Math.round(c.percentage)}%)</li>
  `).join('') || '<p style="color:var(--text-secondary);">No expenses recorded.</p>';

  // Copy Summary text
  const btnCopy = document.getElementById('btn-copy-summary');
  if (btnCopy) {
    btnCopy.onclick = () => {
      const summaryText = `
# ${monthName} Financial Summary (TheBag)
Income: ${formatCurrency(income)}
Total Spending: ${formatCurrency(spent)}
Net Cash Flow: ${formatCurrency(net, true)}
Savings Rate: ${Math.round(rate)}%
Top Categories:
${topCats.map((c, i) => `${i + 1}. ${c.category} — ${formatCurrency(c.amount)}`).join('\n')}
      `.trim();
      navigator.clipboard.writeText(summaryText);
      alert('Summary copied to clipboard!');
    };
  }
}

// ---------------------------------------------------------------------------
// SETTINGS SCREEN & BACKUP
// ---------------------------------------------------------------------------
function setupSettingsScreen() {
  const inputIncome = document.getElementById('settings-income');
  const selectFreq = document.getElementById('settings-frequency');
  const toggleLock = document.getElementById('settings-toggle-lock');

  if (inputIncome) {
    inputIncome.value = state.monthlyIncome;
    inputIncome.addEventListener('change', async (e) => {
      state.monthlyIncome = parseFloat(e.target.value) || 5000;
      await setSetting('monthlyIncome', state.monthlyIncome);
    });
  }

  if (selectFreq) {
    selectFreq.value = state.incomeFrequency;
    selectFreq.addEventListener('change', async (e) => {
      state.incomeFrequency = e.target.value;
      await setSetting('incomeFrequency', state.incomeFrequency);
    });
  }

  if (toggleLock) {
    toggleLock.checked = state.appLockEnabled;
    toggleLock.addEventListener('change', async (e) => {
      state.appLockEnabled = e.target.checked;
      await setSetting('appLockEnabled', state.appLockEnabled);
      if (state.appLockEnabled) {
        alert('App Passcode Lock is enabled. Default passcode is 1234.');
      }
    });
  }

  // Backup Export JSON
  const btnExportJSON = document.getElementById('btn-export-json');
  if (btnExportJSON) {
    btnExportJSON.addEventListener('click', async () => {
      const json = await exportAllDataJSON();
      downloadFile(json, `TheBag_Backup_${new Date().toISOString().slice(0, 10)}.json`, 'application/json');
    });
  }

  // Backup Export CSV
  const btnExportCSV = document.getElementById('btn-export-csv');
  if (btnExportCSV) {
    btnExportCSV.addEventListener('click', async () => {
      const csv = await exportTransactionsCSV();
      downloadFile(csv, `TheBag_Transactions_${new Date().toISOString().slice(0, 10)}.csv`, 'text/csv');
    });
  }

  // File Import
  const fileInput = document.getElementById('file-import-input');
  if (fileInput) {
    fileInput.addEventListener('change', (e) => {
      const file = e.target.files[0];
      if (!file) return;
      const reader = new FileReader();
      reader.onload = async (event) => {
        try {
          const content = event.target.result;
          if (file.name.endsWith('.json')) {
            await importAllDataJSON(content);
            alert('Backup successfully restored!');
          }
          await refreshAllData();
          renderTransactionsList();
          renderAnalysisDashboard();
          renderWealthScreen();
        } catch (err) {
          alert('Failed to import backup: ' + err.message);
        }
      };
      reader.readAsText(file);
    });
  }

  // Clear All Data
  const btnClear = document.getElementById('btn-clear-data');
  if (btnClear) {
    btnClear.addEventListener('click', async () => {
      if (confirm('CAUTION: This will permanently delete all transactions and wealth data stored on this device. Proceed?')) {
        await clearAllLocalData();
        await refreshAllData();
        location.reload();
      }
    });
  }
}

function downloadFile(content, fileName, mimeType) {
  const blob = new Blob([content], { type: mimeType });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = fileName;
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  URL.revokeObjectURL(url);
}

// ---------------------------------------------------------------------------
// ONBOARDING & PASSCODE LOCK
// ---------------------------------------------------------------------------
function showOnboarding() {
  const modal = document.getElementById('modal-onboarding');
  if (!modal) return;
  modal.classList.remove('hidden');

  const form = document.getElementById('form-onboarding');
  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    triggerHaptic('success');

    const inc = parseFloat(document.getElementById('onboard-income').value) || 5000;
    const freq = document.getElementById('onboard-frequency').value;
    const curr = 'USD';
    const goal = parseFloat(document.getElementById('onboard-savings-goal').value) || 1000;

    await setSetting('monthlyIncome', inc);
    await setSetting('incomeFrequency', freq);
    await setSetting('currencyCode', 'USD');
    await setSetting('savingsGoal', goal);
    await setSetting('hasCompletedOnboarding', true);

    state.monthlyIncome = inc;
    state.incomeFrequency = freq;
    state.currencyCode = 'USD';
    state.currencySymbol = '$';

    updateCurrencyDisplays();
    await refreshAllData();
    modal.classList.add('hidden');
  });
}

function showLockScreen() {
  const modal = document.getElementById('modal-lockscreen');
  if (!modal) return;
  modal.classList.remove('hidden');
  state.isUnlocked = false;
  state.passcodeInput = '';
  updatePasscodeDots();
}

function setupLockScreen() {
  const keys = document.querySelectorAll('.lock-key[data-digit]');
  keys.forEach(k => {
    k.addEventListener('click', () => {
      triggerHaptic('light');
      if (state.passcodeInput.length < 4) {
        state.passcodeInput += k.getAttribute('data-digit');
        updatePasscodeDots();
        if (state.passcodeInput.length === 4) {
          checkPasscode();
        }
      }
    });
  });

  const btnBk = document.getElementById('lock-backspace');
  if (btnBk) {
    btnBk.addEventListener('click', () => {
      triggerHaptic('light');
      if (state.passcodeInput.length > 0) {
        state.passcodeInput = state.passcodeInput.slice(0, -1);
        updatePasscodeDots();
      }
    });
  }
}

function updatePasscodeDots() {
  for (let i = 0; i < 4; i++) {
    const dot = document.getElementById(`dot-${i}`);
    if (dot) {
      if (i < state.passcodeInput.length) dot.classList.add('filled');
      else dot.classList.remove('filled');
    }
  }
}

function checkPasscode() {
  if (state.passcodeInput === state.passcode) {
    triggerHaptic('success');
    state.isUnlocked = true;
    document.getElementById('modal-lockscreen').classList.add('hidden');
  } else {
    triggerHaptic('heavy');
    state.passcodeInput = '';
    updatePasscodeDots();
    alert('Incorrect passcode. Please try again.');
  }
}

// Global data refresh
async function refreshAllData() {
  state.allTransactions = await getAllTransactions();
  state.allWealth = await getAllWealth();
  state.allBudgets = await getAllBudgets();
  state.allRecurring = await getAllRecurring();
}

// ---------------------------------------------------------------------------
// BUDGETS MODAL
// ---------------------------------------------------------------------------
function setupBudgetsModal() {
  const btnOpen = document.getElementById('btn-open-budgets-modal');
  const modal = document.getElementById('modal-budgets');
  const btnClose = document.getElementById('btn-close-budgets');

  if (btnOpen && modal) {
    btnOpen.addEventListener('click', () => {
      modal.classList.remove('hidden');
      renderBudgetsList();
    });
  }

  if (btnClose && modal) {
    btnClose.addEventListener('click', () => {
      modal.classList.add('hidden');
    });
  }
}

function renderBudgetsList() {
  const container = document.getElementById('budgets-editor-list');
  if (!container) return;

  container.innerHTML = '';
  const monthItems = filterTransactionsByMonth(state.allTransactions, state.analysisMonth, state.analysisYear);
  const expenses = getCategoryBreakdown(monthItems);

  STANDARD_EXPENSE_CATEGORIES.forEach(cat => {
    const budgetObj = state.allBudgets.find(b => b.categoryName.toLowerCase() === cat.name.toLowerCase());
    const limit = budgetObj ? parseFloat(budgetObj.monthlyLimit) : 0;
    const spentObj = expenses.find(e => e.category.toLowerCase() === cat.name.toLowerCase());
    const spent = spentObj ? spentObj.amount : 0;
    const pct = limit > 0 ? (spent / limit) * 100 : 0;

    let barColor = 'var(--accent-green)';
    if (pct >= 100) barColor = 'var(--accent-red)';
    else if (pct >= 75) barColor = 'var(--accent-orange)';

    const card = document.createElement('div');
    card.className = 'section-card';
    card.style.marginBottom = '10px';
    card.innerHTML = `
      <div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:8px;">
        <div style="display:flex; align-items:center; gap:8px;">
          <span style="font-size:20px;">${cat.icon}</span>
          <strong style="font-size:15px;">${cat.name}</strong>
        </div>
        <div style="display:flex; align-items:center; gap:6px;">
          <span style="font-size:13px; color:var(--text-secondary);">${state.currencySymbol}</span>
          <input type="number" class="budget-input" data-cat="${cat.name}" value="${limit > 0 ? limit : ''}" placeholder="No limit" style="width:90px; height:32px; border-radius:8px; border:1px solid var(--border-color); background:var(--bg-primary); text-align:right; padding:0 8px; font-weight:600; color:var(--text-primary);">
        </div>
      </div>
      <div style="background:var(--bg-tertiary); height:8px; border-radius:4px; overflow:hidden; margin:8px 0;">
        <div style="background:${barColor}; width:${Math.min(100, pct)}%; height:100%; transition:width 0.3s ease;"></div>
      </div>
      <div style="display:flex; justify-content:space-between; font-size:12px; color:var(--text-secondary);">
        <span>Spent: ${formatCurrency(spent)}</span>
        <span>${limit > 0 ? (pct >= 100 ? `<strong style="color:var(--accent-red);">${formatCurrency(spent - limit)} over</strong>` : `${formatCurrency(limit - spent)} remaining`) : 'No budget set'}</span>
      </div>
    `;

    const input = card.querySelector('.budget-input');
    input.addEventListener('change', async (e) => {
      const val = parseFloat(e.target.value);
      if (val > 0) {
        await saveBudget(cat.name, val);
      } else {
        await deleteBudget(cat.name);
      }
      await refreshAllData();
      renderBudgetsList();
    });

    container.appendChild(card);
  });
}

// ---------------------------------------------------------------------------
// RECURRING EXPENSES MODAL
// ---------------------------------------------------------------------------
function setupRecurringModal() {
  const btnOpen = document.getElementById('btn-open-recurring-modal');
  const modal = document.getElementById('modal-recurring');
  const btnClose = document.getElementById('btn-close-recurring');

  const btnAdd = document.getElementById('btn-add-recurring-item');
  const modalEdit = document.getElementById('modal-edit-recurring');
  const btnCloseEdit = document.getElementById('btn-close-edit-recurring');
  const formRec = document.getElementById('form-recurring');
  const btnDelete = document.getElementById('btn-delete-recurring');

  if (btnOpen && modal) {
    btnOpen.addEventListener('click', () => {
      modal.classList.remove('hidden');
      renderRecurringList();
    });
  }

  if (btnClose && modal) {
    btnClose.addEventListener('click', () => modal.classList.add('hidden'));
  }

  if (btnAdd && modalEdit) {
    btnAdd.addEventListener('click', () => {
      document.getElementById('recurring-modal-title').textContent = 'Add Recurring Bill';
      document.getElementById('rec-id').value = '';
      document.getElementById('rec-name').value = '';
      document.getElementById('rec-amount').value = '';
      document.getElementById('rec-due-day').value = '1';
      document.getElementById('btn-delete-recurring').classList.add('hidden');
      populateRecurringCategories();
      modalEdit.classList.remove('hidden');
    });
  }

  if (btnCloseEdit && modalEdit) {
    btnCloseEdit.addEventListener('click', () => modalEdit.classList.add('hidden'));
  }

  function populateRecurringCategories() {
    const sel = document.getElementById('rec-category');
    sel.innerHTML = '';
    STANDARD_EXPENSE_CATEGORIES.forEach(c => {
      const opt = document.createElement('option');
      opt.value = c.name;
      opt.textContent = c.name;
      sel.appendChild(opt);
    });
  }

  if (formRec) {
    formRec.addEventListener('submit', async (e) => {
      e.preventDefault();
      const id = document.getElementById('rec-id').value;
      const name = document.getElementById('rec-name').value;
      const category = document.getElementById('rec-category').value;
      const amount = parseFloat(document.getElementById('rec-amount').value) || 0;
      const frequency = document.getElementById('rec-frequency').value;
      const dueDay = parseInt(document.getElementById('rec-due-day').value) || 1;

      await saveRecurringItem({ id: id || undefined, name, category, amount, frequency, dueDay });
      await refreshAllData();
      modalEdit.classList.add('hidden');
      renderRecurringList();
    });
  }

  if (btnDelete) {
    btnDelete.addEventListener('click', async () => {
      const id = document.getElementById('rec-id').value;
      if (id && confirm('Delete this recurring bill?')) {
        await deleteRecurringItem(id);
        await refreshAllData();
        modalEdit.classList.add('hidden');
        renderRecurringList();
      }
    });
  }
}

function renderRecurringList() {
  const container = document.getElementById('recurring-items-list');
  if (!container) return;

  container.innerHTML = '';
  if (state.allRecurring.length === 0) {
    container.innerHTML = '<p style="color:var(--text-secondary); text-align:center; padding:20px 0;">No recurring bills added yet. Tap "+ Add Bill" to record rent, gym, internet, etc.</p>';
    return;
  }

  const totalMonthly = state.allRecurring.reduce((sum, r) => {
    let mult = 1;
    if (r.frequency === 'Weekly') mult = 4.33;
    else if (r.frequency === 'Biweekly') mult = 2.16;
    else if (r.frequency === 'Yearly') mult = 1 / 12;
    return sum + (parseFloat(r.amount || 0) * mult);
  }, 0);

  const summary = document.createElement('div');
  summary.className = 'section-card';
  summary.innerHTML = `
    <div style="font-size:12px; font-weight:700; text-transform:uppercase; color:var(--text-secondary);">Total Monthly Fixed Bills</div>
    <div style="font-size:26px; font-weight:800; color:var(--accent-red); margin-top:4px;">${formatCurrency(totalMonthly)}/mo</div>
  `;
  container.appendChild(summary);

  state.allRecurring.forEach(r => {
    const card = document.createElement('div');
    card.className = 'tx-card';
    card.style.marginBottom = '8px';
    card.innerHTML = `
      <div class="tx-icon-box">🔁</div>
      <div class="tx-info">
        <div class="tx-title">${r.name}</div>
        <div class="tx-sub">${r.category} • Due on the ${r.dueDay || 1}th (${r.frequency || 'Monthly'})</div>
      </div>
      <div class="tx-amount expense">${formatCurrency(r.amount)}</div>
    `;

    card.addEventListener('click', () => {
      document.getElementById('recurring-modal-title').textContent = 'Edit Recurring Bill';
      document.getElementById('rec-id').value = r.id;
      document.getElementById('rec-name').value = r.name;
      document.getElementById('rec-amount').value = r.amount;
      document.getElementById('rec-frequency').value = r.frequency || 'Monthly';
      document.getElementById('rec-due-day').value = r.dueDay || 1;
      
      const sel = document.getElementById('rec-category');
      sel.innerHTML = '';
      STANDARD_EXPENSE_CATEGORIES.forEach(c => {
        const opt = document.createElement('option');
        opt.value = c.name;
        opt.textContent = c.name;
        if (c.name.toLowerCase() === (r.category || '').toLowerCase()) opt.selected = true;
        sel.appendChild(opt);
      });

      document.getElementById('btn-delete-recurring').classList.remove('hidden');
      document.getElementById('modal-edit-recurring').classList.remove('hidden');
    });

    container.appendChild(card);
  });
}

// ---------------------------------------------------------------------------
// CUSTOM CATEGORIES & SUBCATEGORIES MODAL
// ---------------------------------------------------------------------------
function setupCustomCategoriesModal() {
  const btnOpen = document.getElementById('btn-open-custom-cats-modal');
  const modal = document.getElementById('modal-custom-cats');
  const btnClose = document.getElementById('btn-close-custom-cats');
  const formCat = document.getElementById('form-add-custom-cat');
  const formSub = document.getElementById('form-add-custom-sub');

  if (btnOpen && modal) {
    btnOpen.addEventListener('click', async () => {
      modal.classList.remove('hidden');
      populateTargetCategorySelect();
      await renderCustomCategoriesList();
    });
  }

  if (btnClose && modal) {
    btnClose.addEventListener('click', () => modal.classList.add('hidden'));
  }

  // Form 1: Add Brand New Category
  if (formCat) {
    formCat.addEventListener('submit', async (e) => {
      e.preventDefault();
      const name = document.getElementById('custom-cat-name').value.trim();
      const icon = document.getElementById('custom-cat-icon').value.trim() || '🏷️';
      const subsStr = document.getElementById('custom-cat-subs').value.trim();
      const subcategories = subsStr ? subsStr.split(',').map(s => s.trim()).filter(Boolean) : ['General'];

      if (name) {
        await saveCustomCategory({
          name,
          icon,
          color: '#af52de',
          subcategories,
          isCustom: true
        });

        document.getElementById('custom-cat-name').value = '';
        document.getElementById('custom-cat-subs').value = '';

        await loadAllCategoriesAndSubcategories();
        populateTargetCategorySelect();
        await renderCustomCategoriesList();
        renderCategoryChips();
        showToast(`Category "${name}" created ✓`);
      }
    });
  }

  // Form 2: Add Subcategory to Any Existing Category
  if (formSub) {
    formSub.addEventListener('submit', async (e) => {
      e.preventDefault();
      const targetCat = document.getElementById('custom-sub-target-cat').value;
      const subName = document.getElementById('custom-sub-name').value.trim();

      if (targetCat && subName) {
        await saveCustomSubcategory(targetCat, subName);
        document.getElementById('custom-sub-name').value = '';

        await loadAllCategoriesAndSubcategories();
        await renderCustomCategoriesList();
        renderCategoryChips();
        if (state.selectedCategory.toLowerCase() === targetCat.toLowerCase()) {
          state.selectedSubcategory = subName;
          renderSubcategoryChips();
        }
        showToast(`Added "${subName}" to ${targetCat} ✓`);
      }
    });
  }
}

function populateTargetCategorySelect() {
  const sel = document.getElementById('custom-sub-target-cat');
  if (!sel) return;

  sel.innerHTML = '';
  STANDARD_EXPENSE_CATEGORIES.forEach(cat => {
    const opt = document.createElement('option');
    opt.value = cat.name;
    opt.textContent = `${cat.icon} ${cat.name}`;
    sel.appendChild(opt);
  });
}

async function renderCustomCategoriesList() {
  const container = document.getElementById('custom-cats-list');
  if (!container) return;

  container.innerHTML = '';
  const customSubMap = await getCustomSubcategories();

  STANDARD_EXPENSE_CATEGORIES.forEach(cat => {
    const card = document.createElement('div');
    card.style.cssText = 'padding:12px 0; border-bottom:0.5px solid var(--border-color);';

    const header = document.createElement('div');
    header.style.cssText = 'display:flex; justify-content:space-between; align-items:center; margin-bottom:8px;';
    header.innerHTML = `
      <div style="display:flex; align-items:center; gap:8px;">
        <span style="font-size:22px;">${cat.icon}</span>
        <div>
          <strong style="font-size:15px; color:var(--text-primary);">${cat.name}</strong>
          ${cat.isCustom ? '<span style="font-size:10px; background:rgba(0,122,255,0.15); color:var(--accent-blue); padding:2px 6px; border-radius:6px; margin-left:6px; font-weight:700;">CUSTOM</span>' : ''}
        </div>
      </div>
      <div>
        ${cat.isCustom ? `<button type="button" class="btn-del-cat" data-cat="${cat.name}" style="background:none; border:none; color:var(--accent-red); font-size:13px; font-weight:600; cursor:pointer;">Delete</button>` : `<span style="font-size:12px; color:var(--text-secondary);">${cat.subcategories.length} items</span>`}
      </div>
    `;
    card.appendChild(header);

    // Subcategories container
    const subsWrapper = document.createElement('div');
    subsWrapper.style.cssText = 'display:flex; flex-wrap:wrap; gap:6px; margin-top:6px;';

    const customSubsForCat = customSubMap[cat.name] || [];

    cat.subcategories.forEach(sub => {
      const isCustomSub = customSubsForCat.includes(sub);
      const pill = document.createElement('span');
      pill.style.cssText = `display:inline-flex; align-items:center; gap:4px; padding:4px 10px; border-radius:12px; font-size:12px; background:${isCustomSub ? 'rgba(0,122,255,0.12)' : 'var(--bg-tertiary)'}; color:var(--text-primary); border:0.5px solid ${isCustomSub ? 'var(--accent-blue)' : 'var(--border-color)'};`;

      pill.innerHTML = `
        <span>${sub}</span>
        ${isCustomSub ? `<button type="button" class="btn-del-sub" data-cat="${cat.name}" data-sub="${sub}" style="background:none; border:none; color:var(--text-secondary); font-size:12px; cursor:pointer; padding:0 2px; line-height:1;">×</button>` : ''}
      `;
      subsWrapper.appendChild(pill);
    });

    card.appendChild(subsWrapper);
    container.appendChild(card);
  });

  // Attach delete listeners for custom categories
  container.querySelectorAll('.btn-del-cat').forEach(btn => {
    btn.addEventListener('click', async (e) => {
      const catName = e.target.getAttribute('data-cat');
      if (confirm(`Delete custom category "${catName}"?`)) {
        await deleteCustomCategory(catName);
        await loadAllCategoriesAndSubcategories();
        populateTargetCategorySelect();
        await renderCustomCategoriesList();
        renderCategoryChips();
        showToast(`Category "${catName}" deleted`);
      }
    });
  });

  // Attach delete listeners for custom subcategories
  container.querySelectorAll('.btn-del-sub').forEach(btn => {
    btn.addEventListener('click', async (e) => {
      const catName = e.target.getAttribute('data-cat');
      const subName = e.target.getAttribute('data-sub');
      await deleteCustomSubcategory(catName, subName);
      await loadAllCategoriesAndSubcategories();
      await renderCustomCategoriesList();
      renderCategoryChips();
      if (state.selectedCategory.toLowerCase() === catName.toLowerCase()) {
        renderSubcategoryChips();
      }
      showToast(`Removed "${subName}"`);
    });
  });
}

