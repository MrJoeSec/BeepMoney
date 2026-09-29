// Financial Analytics & Insights Engine for TheBag

export function filterTransactionsByMonth(transactions, month, year) {
  return transactions.filter(tx => {
    const d = new Date(tx.date);
    return (d.getMonth() + 1) === month && d.getFullYear() === year;
  });
}

export function calculateTotalExpenses(transactions) {
  return transactions
    .filter(tx => (tx.type || '').toLowerCase() === 'expense')
    .reduce((sum, tx) => sum + parseFloat(tx.amount || 0), 0);
}

export function calculateTotalIncome(transactions, defaultMonthlyIncome = 5000) {
  const recorded = transactions
    .filter(tx => (tx.type || '').toLowerCase() === 'income')
    .reduce((sum, tx) => sum + parseFloat(tx.amount || 0), 0);
  return recorded > 0 ? recorded : defaultMonthlyIncome;
}

export function calculateNetCashFlow(income, expenses) {
  return income - expenses;
}

export function calculateSavingsRate(income, expenses) {
  if (income <= 0) return 0;
  const rate = ((income - expenses) / income) * 100;
  return Math.max(-100, Math.min(100, rate));
}

export function getCategoryBreakdown(transactions) {
  const expenses = transactions.filter(tx => (tx.type || '').toLowerCase() === 'expense');
  const total = expenses.reduce((sum, tx) => sum + parseFloat(tx.amount || 0), 0);
  if (total <= 0) return [];

  const grouped = {};
  for (const tx of expenses) {
    const cat = tx.category || 'Other';
    if (!grouped[cat]) grouped[cat] = { amount: 0, count: 0 };
    grouped[cat].amount += parseFloat(tx.amount || 0);
    grouped[cat].count += 1;
  }

  return Object.keys(grouped).map(cat => ({
    category: cat,
    amount: grouped[cat].amount,
    percentage: (grouped[cat].amount / total) * 100,
    count: grouped[cat].count
  })).sort((a, b) => b.amount - a.amount);
}

export function getSubcategoryBreakdown(transactions, category) {
  const items = transactions.filter(tx => 
    (tx.type || '').toLowerCase() === 'expense' &&
    (tx.category || '').toLowerCase() === category.toLowerCase()
  );
  const total = items.reduce((sum, tx) => sum + parseFloat(tx.amount || 0), 0);
  const grouped = {};

  for (const tx of items) {
    const sub = tx.subcategory || tx.category || 'General';
    if (!grouped[sub]) grouped[sub] = { amount: 0, count: 0 };
    grouped[sub].amount += parseFloat(tx.amount || 0);
    grouped[sub].count += 1;
  }

  return Object.keys(grouped).map(sub => ({
    subcategory: sub,
    amount: grouped[sub].amount,
    percentage: total > 0 ? (grouped[sub].amount / total) * 100 : 0,
    count: grouped[sub].count
  })).sort((a, b) => b.amount - a.amount);
}

export function getDailyAverageSpend(expenses, month, year) {
  const now = new Date();
  let daysToDivide;

  if ((now.getMonth() + 1) === month && now.getFullYear() === year) {
    daysToDivide = Math.max(1, now.getDate());
  } else {
    // Days in specified month
    daysToDivide = new Date(year, month, 0).getDate();
  }
  return expenses / daysToDivide;
}

export function getProjectedMonthlySpend(expenses, month, year) {
  const totalDays = new Date(year, month, 0).getDate();
  const dailyAvg = getDailyAverageSpend(expenses, month, year);
  return dailyAvg * totalDays;
}

export function generateDynamicInsights(allTransactions, currentMonth, currentYear, monthlyIncome, formatCurrency) {
  const insights = [];

  const currentItems = filterTransactionsByMonth(allTransactions, currentMonth, currentYear);
  const currentExpenses = calculateTotalExpenses(currentItems);
  const currentIncome = calculateTotalIncome(currentItems, monthlyIncome);

  let prevMonth = currentMonth - 1;
  let prevYear = currentYear;
  if (prevMonth < 1) {
    prevMonth = 12;
    prevYear -= 1;
  }
  const prevItems = filterTransactionsByMonth(allTransactions, prevMonth, prevYear);
  const prevExpenses = calculateTotalExpenses(prevItems);

  // 1. Remaining budget / buffer
  const remaining = currentIncome - currentExpenses;
  if (currentIncome > 0) {
    if (remaining >= 0) {
      insights.push({
        icon: '💵',
        title: 'Monthly Buffer',
        message: `You have ${formatCurrency(remaining)} remaining for the month based on your current income and spending.`
      });
    } else {
      insights.push({
        icon: '⚠️',
        title: 'Over Monthly Income',
        message: `You are currently ${formatCurrency(Math.abs(remaining))} over your monthly income.`
      });
    }
  }

  // 2. Daily burn rate and projected spend
  if (currentExpenses > 0) {
    const dailyAvg = getDailyAverageSpend(currentExpenses, currentMonth, currentYear);
    const projected = getProjectedMonthlySpend(currentExpenses, currentMonth, currentYear);
    insights.push({
      icon: '📈',
      title: 'Daily Spend Rate',
      message: `Your spending is currently averaging ${formatCurrency(dailyAvg)}/day. At your current spending rate, you may spend approximately ${formatCurrency(projected)} this month.`
    });
  }

  // 3. Category MoM & top category insights
  const currentCats = getCategoryBreakdown(currentItems);
  const prevCats = getCategoryBreakdown(prevItems);

  if (currentCats.length > 0 && currentExpenses > 0) {
    const topCat = currentCats[0];
    insights.push({
      icon: '🏷️',
      title: 'Top Category',
      message: `${topCat.category} represents ${Math.round(topCat.percentage)}% of your monthly spending (${formatCurrency(topCat.amount)}).`
    });

    // Check MoM changes
    for (const cat of currentCats.slice(0, 3)) {
      const prevCat = prevCats.find(c => c.category.toLowerCase() === cat.category.toLowerCase());
      if (prevCat && prevCat.amount > 0) {
        const diff = cat.amount - prevCat.amount;
        const pct = Math.round((diff / prevCat.amount) * 100);
        if (pct >= 15) {
          insights.push({
            icon: '📊',
            title: `${cat.category} Shift`,
            message: `Your ${cat.category} spending is ${pct}% higher than last month (${formatCurrency(cat.amount)} vs ${formatCurrency(prevCat.amount)}).`
          });
        } else if (pct <= -15) {
          insights.push({
            icon: '📉',
            title: `${cat.category} Reduction`,
            message: `You're spending ${Math.abs(pct)}% less on ${cat.category} than last month.`
          });
        }
      }
    }
  }

  // 4. Dining / Restaurant purchases
  const diningCount = currentItems.filter(tx => {
    const cat = (tx.category || '').toLowerCase();
    const sub = (tx.subcategory || '').toLowerCase();
    return cat.includes('eat') || sub.includes('restaurant') || sub.includes('dinner') || sub.includes('lunch') || sub.includes('coffee') || sub.includes('fast food');
  }).length;

  if (diningCount >= 3) {
    insights.push({
      icon: '🍽️',
      title: 'Dining Frequency',
      message: `You made ${diningCount} restaurant / food purchases this month.`
    });
  }

  // 5. Largest expense
  const expensesList = currentItems.filter(tx => (tx.type || '').toLowerCase() === 'expense');
  if (expensesList.length > 0) {
    const largest = expensesList.reduce((max, tx) => (parseFloat(tx.amount) > parseFloat(max.amount) ? tx : max), expensesList[0]);
    const label = largest.merchant || largest.subcategory || largest.category;
    insights.push({
      icon: '💳',
      title: 'Largest Expense',
      message: `Your largest single expense was ${formatCurrency(largest.amount)} on ${label}.`
    });
  }

  if (insights.length === 0) {
    insights.push({
      icon: '✨',
      title: 'Ready to Track',
      message: 'Log your purchases with Quick Add to unlock personalized spending trends and real-time insights.'
    });
  }

  return insights;
}

export function getMonthlyTrends(allTransactions, monthsBack = 6, defaultMonthlyIncome = 5000) {
  const points = [];
  const now = new Date();

  for (let i = monthsBack - 1; i >= 0; i--) {
    const target = new Date(now.getFullYear(), now.getMonth() - i, 1);
    const m = target.getMonth() + 1;
    const y = target.getFullYear();

    const items = filterTransactionsByMonth(allTransactions, m, y);
    const spent = calculateTotalExpenses(items);
    const income = calculateTotalIncome(items, defaultMonthlyIncome);
    const label = target.toLocaleDateString('default', { month: 'short' });

    points.push({
      monthLabel: label,
      month: m,
      year: y,
      spent,
      income,
      net: income - spent
    });
  }
  return points;
}
