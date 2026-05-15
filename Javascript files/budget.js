// Budget management functions
let statsChart = null;
let cachedExpenses = [];

async function initializeBudget() {
  setupEventListeners();
  setDefaultDate();
  populateYears();
  handlePeriodChange();
  await loadExpenses();
  await loadStats();
}

function setupEventListeners() {
  const expenseForm = document.getElementById('expense-form');
  const periodSelect = document.getElementById('period-select');
  const categoryFilter = document.getElementById('stats-category-filter');
  const loadStatsBtn = document.getElementById('load-stats-btn');
  const expenseList = document.getElementById('expense-list');

  expenseForm.addEventListener('submit', handleAddExpense);
  periodSelect.addEventListener('change', handlePeriodChange);
  categoryFilter.addEventListener('change', handleLoadStats);
  loadStatsBtn.addEventListener('click', handleLoadStats);
  expenseList.addEventListener('click', handleExpenseListClick);
}

function setDefaultDate() {
  const today = new Date();
  const dateString = today.toISOString().split('T')[0];
  document.getElementById('expense-date').value = dateString;
}

function populateYears() {
  const yearSelect = document.getElementById('year-select');
  const startYearSelect = document.getElementById('start-year-select');
  const endYearSelect = document.getElementById('end-year-select');
  const currentYear = new Date().getFullYear();

  const yearOptions = [];
  for (let i = currentYear - 5; i <= currentYear + 1; i++) {
    yearOptions.push(i);
  }

  populateYearSelect(yearSelect, yearOptions, currentYear);
  populateYearSelect(startYearSelect, yearOptions, currentYear - 1);
  populateYearSelect(endYearSelect, yearOptions, currentYear);

  const currentMonth = new Date().getMonth() + 1;
  document.getElementById('month-select').value = String(currentMonth);
  document.getElementById('start-month-select').value = '1';
  document.getElementById('end-month-select').value = String(currentMonth);
}

function populateYearSelect(selectEl, years, selectedYear) {
  if (!selectEl) {
    return;
  }

  selectEl.innerHTML = '';
  for (const year of years) {
    const option = document.createElement('option');
    option.value = String(year);
    option.textContent = String(year);
    if (year === selectedYear) {
      option.selected = true;
    }
    selectEl.appendChild(option);
  }
}

function handlePeriodChange() {
  const period = document.getElementById('period-select').value;
  const yearMonthGroup = document.getElementById('year-month-group');
  const monthGroup = document.getElementById('month-group');
  const customRangeGroup = document.getElementById('custom-range-group');

  if (period === 'month') {
    yearMonthGroup.hidden = false;
    monthGroup.hidden = false;
    customRangeGroup.hidden = true;
  } else if (period === 'year') {
    yearMonthGroup.hidden = false;
    monthGroup.hidden = true;
    customRangeGroup.hidden = true;
  } else if (period === 'customrange') {
    yearMonthGroup.hidden = true;
    monthGroup.hidden = true;
    customRangeGroup.hidden = false;
  } else {
    yearMonthGroup.hidden = true;
    monthGroup.hidden = true;
    customRangeGroup.hidden = true;
  }

  handleLoadStats();
}

async function handleAddExpense(event) {
  event.preventDefault();

  const category = document.getElementById('expense-category').value;
  const amount = document.getElementById('expense-amount').value;
  const date = document.getElementById('expense-date').value;
  const description = document.getElementById('expense-description').value;
  const formMessage = document.getElementById('form-message');

  if (!category || !amount || !date) {
    showMessage(formMessage, 'Please fill in all required fields', 'error');
    return;
  }

  try {
    const params = new URLSearchParams();
    params.append('category', category);
    params.append('amount', amount);
    params.append('expenseDate', date);
    params.append('description', description);

    const data = await requestJson('api/budget/add', params);

    if (!data.success) {
      throw new Error(data.error || 'Failed to add expense');
    }

    showMessage(formMessage, 'Expense added successfully!', 'success');
    document.getElementById('expense-form').reset();
    setDefaultDate();
    await loadExpenses();
    await loadStats();
  } catch (error) {
    console.error('Error adding expense:', error);
    showMessage(formMessage, `Error: ${error.message}`, 'error');
  }
}

async function handleLoadStats() {
  await loadStats();
}

async function loadStats() {
  const period = document.getElementById('period-select').value;
  const categoryFilter = document.getElementById('stats-category-filter').value;
  const noDataMessage = document.getElementById('no-data-message');
  const chartContainer = document.querySelector('.chart-container');

  try {
    if (!cachedExpenses || cachedExpenses.length === 0) {
      await loadExpenses();
    }

    const trendData = buildTrendData(cachedExpenses, period, categoryFilter, getPeriodSelection());
    const hasPoints = trendData.datasets.some(ds => ds.data.some(value => value > 0));

    if (!hasPoints) {
      noDataMessage.hidden = false;
      noDataMessage.innerHTML = '<p>No expenses recorded for the selected period.</p>';
      chartContainer.hidden = true;
      if (statsChart) {
        statsChart.destroy();
        statsChart = null;
      }
      return;
    }

    noDataMessage.hidden = true;
    chartContainer.hidden = false;
    renderChart(trendData);
  } catch (error) {
    console.error('Error loading stats:', error);
    noDataMessage.hidden = false;
    noDataMessage.innerHTML = `<p>Error loading statistics: ${error.message}</p>`;
    chartContainer.hidden = true;
  }
}

function getPeriodSelection() {
  const selectedYear = parseInt(document.getElementById('year-select').value, 10);
  const selectedMonth = parseInt(document.getElementById('month-select').value, 10);
  const startYear = parseInt(document.getElementById('start-year-select').value, 10);
  const startMonth = parseInt(document.getElementById('start-month-select').value, 10);
  const endYear = parseInt(document.getElementById('end-year-select').value, 10);
  const endMonth = parseInt(document.getElementById('end-month-select').value, 10);

  return {
    selectedYear,
    selectedMonth,
    startYear,
    startMonth,
    endYear,
    endMonth
  };
}

function buildTrendData(expenses, period, selectedCategory, selection) {
  const parsedExpenses = expenses
    .map(expense => ({
      ...expense,
      amountNumber: Number.parseFloat(expense.amount),
      parsedDate: parseExpenseDate(expense.expenseDate)
    }))
    .filter(expense => Number.isFinite(expense.amountNumber) && expense.parsedDate);

  if (period === 'year') {
    return buildYearTrend(parsedExpenses, selectedCategory, selection.selectedYear);
  }

  if (period === 'rolling') {
    return buildRollingTrend(parsedExpenses, selectedCategory);
  }

  if (period === 'customrange') {
    return buildCustomRangeTrend(
      parsedExpenses,
      selectedCategory,
      selection.startYear,
      selection.startMonth,
      selection.endYear,
      selection.endMonth
    );
  }

  return buildMonthTrend(parsedExpenses, selectedCategory, selection.selectedYear, selection.selectedMonth);
}

function buildMonthTrend(expenses, selectedCategory, year, month) {
  const daysInMonth = new Date(year, month, 0).getDate();
  const labels = Array.from({ length: daysInMonth }, (_, i) => `${i + 1}`);
  const selected = expenses.filter(expense => {
    return expense.parsedDate.getFullYear() === year && (expense.parsedDate.getMonth() + 1) === month;
  });

  const monthName = new Date(year, month - 1, 1).toLocaleDateString('en-GB', { month: 'long' });
  return {
    labels,
    datasets: buildCategoryDatasets(selected, selectedCategory, expense => expense.parsedDate.getDate() - 1),
    title: `Daily spending trend - ${monthName} ${year}`
  };
}

function buildYearTrend(expenses, selectedCategory, year) {
  const labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  const selected = expenses.filter(expense => expense.parsedDate.getFullYear() === year);

  return {
    labels,
    datasets: buildCategoryDatasets(selected, selectedCategory, expense => expense.parsedDate.getMonth()),
    title: `Monthly spending trend - ${year}`
  };
}

function buildRollingTrend(expenses, selectedCategory) {
  const now = new Date();
  const from = new Date(now.getFullYear(), now.getMonth() - 11, 1);
  const to = new Date(now.getFullYear(), now.getMonth(), 1);
  const labelsAndIndex = buildMonthBuckets(from, to);

  return {
    labels: labelsAndIndex.labels,
    datasets: buildCategoryDatasets(
      expenses.filter(expense => monthStart(expense.parsedDate) >= from && monthStart(expense.parsedDate) <= to),
      selectedCategory,
      expense => labelsAndIndex.indexByKey.get(monthKey(monthStart(expense.parsedDate)))
    ),
    title: 'Spending trend - Last 12 months'
  };
}

function buildCustomRangeTrend(expenses, selectedCategory, startYear, startMonth, endYear, endMonth) {
  const from = new Date(startYear, startMonth - 1, 1);
  const to = new Date(endYear, endMonth - 1, 1);

  if (from > to) {
    throw new Error('Custom range is invalid. "From" month must be before "To" month.');
  }

  const labelsAndIndex = buildMonthBuckets(from, to);
  const filtered = expenses.filter(expense => {
    const bucket = monthStart(expense.parsedDate);
    return bucket >= from && bucket <= to;
  });

  return {
    labels: labelsAndIndex.labels,
    datasets: buildCategoryDatasets(
      filtered,
      selectedCategory,
      expense => labelsAndIndex.indexByKey.get(monthKey(monthStart(expense.parsedDate)))
    ),
    title: `Custom trend - ${labelsAndIndex.labels[0]} to ${labelsAndIndex.labels[labelsAndIndex.labels.length - 1]}`
  };
}

function buildMonthBuckets(from, to) {
  const labels = [];
  const indexByKey = new Map();
  const cursor = new Date(from.getFullYear(), from.getMonth(), 1);

  while (cursor <= to) {
    const key = monthKey(cursor);
    indexByKey.set(key, labels.length);
    labels.push(cursor.toLocaleDateString('en-GB', { month: 'short', year: '2-digit' }));
    cursor.setMonth(cursor.getMonth() + 1);
  }

  return { labels, indexByKey };
}

function buildCategoryDatasets(expenses, selectedCategory, indexResolver) {
  const categories = [...new Set(expenses.map(expense => expense.category).filter(Boolean))].sort();
  const datasetLength = resolveDatasetLength(indexResolver, expenses);

  if (selectedCategory === '__all__') {
    const datasets = [];
    const overallData = new Array(datasetLength).fill(0);

    for (const expense of expenses) {
      const idx = indexResolver(expense);
      if (idx === undefined || idx === null || idx < 0 || idx >= datasetLength) {
        continue;
      }
      overallData[idx] += expense.amountNumber;
    }

    datasets.push({
      label: 'Overall Spend',
      data: overallData,
      borderColor: '#1f5f95',
      backgroundColor: 'rgba(31, 95, 149, 0.12)',
      borderWidth: 3,
      fill: true,
      tension: 0.28,
      pointRadius: 3,
      pointHoverRadius: 5
    });

    categories.forEach((category, idx) => {
      const categoryData = new Array(datasetLength).fill(0);
      for (const expense of expenses) {
        if (expense.category !== category) {
          continue;
        }

        const dataIdx = indexResolver(expense);
        if (dataIdx === undefined || dataIdx === null || dataIdx < 0 || dataIdx >= datasetLength) {
          continue;
        }
        categoryData[dataIdx] += expense.amountNumber;
      }

      const color = paletteColor(idx);
      datasets.push({
        label: category,
        data: categoryData,
        borderColor: color,
        backgroundColor: `${hexToRgba(color, 0.08)}`,
        borderWidth: 2,
        fill: false,
        tension: 0.25,
        pointRadius: 2,
        pointHoverRadius: 4
      });
    });

    return datasets;
  }

  const onlyData = new Array(datasetLength).fill(0);
  for (const expense of expenses) {
    if (expense.category !== selectedCategory) {
      continue;
    }
    const idx = indexResolver(expense);
    if (idx === undefined || idx === null || idx < 0 || idx >= datasetLength) {
      continue;
    }
    onlyData[idx] += expense.amountNumber;
  }

  return [{
    label: selectedCategory,
    data: onlyData,
    borderColor: '#ff6b6b',
    backgroundColor: 'rgba(255, 107, 107, 0.12)',
    borderWidth: 3,
    fill: true,
    tension: 0.28,
    pointRadius: 3,
    pointHoverRadius: 5
  }];
}

function resolveDatasetLength(indexResolver, expenses) {
  let maxIndex = -1;
  for (const expense of expenses) {
    const idx = indexResolver(expense);
    if (Number.isInteger(idx) && idx > maxIndex) {
      maxIndex = idx;
    }
  }
  return Math.max(maxIndex + 1, 1);
}

function renderChart(trendData) {
  const ctx = document.getElementById('stats-chart').getContext('2d');

  if (statsChart) {
    statsChart.destroy();
  }

  statsChart = new Chart(ctx, {
    type: 'line',
    data: {
      labels: trendData.labels,
      datasets: trendData.datasets
    },
    options: {
      responsive: true,
      maintainAspectRatio: true,
      interaction: {
        mode: 'index',
        intersect: false
      },
      plugins: {
        title: {
          display: true,
          text: trendData.title,
          color: '#1c3752',
          font: {
            size: 14,
            weight: 'bold'
          },
          padding: {
            bottom: 16
          }
        },
        legend: {
          position: 'top',
          labels: {
            font: {
              size: 12
            },
            color: '#1c3752',
            padding: 12
          }
        },
        tooltip: {
          callbacks: {
            label: function (context) {
              const value = Number(context.parsed.y || 0);
              return `${context.dataset.label}: INR ${value.toFixed(2)}`;
            }
          }
        }
      },
      scales: {
        y: {
          beginAtZero: true,
          ticks: {
            color: '#3f5f7d',
            callback: function (value) {
              return `INR ${value}`;
            }
          },
          grid: {
            color: 'rgba(43, 118, 184, 0.12)'
          }
        },
        x: {
          ticks: {
            color: '#3f5f7d'
          },
          grid: {
            color: 'rgba(43, 118, 184, 0.08)'
          }
        }
      }
    }
  });
}

async function handleExpenseListClick(event) {
  const actionBtn = event.target.closest('.expense-action-btn');
  if (!actionBtn) {
    return;
  }

  const expenseId = actionBtn.getAttribute('data-expense-id');
  if (!expenseId) {
    return;
  }

  const expense = cachedExpenses.find(item => String(item.id) === String(expenseId));
  if (!expense) {
    return;
  }

  const action = actionBtn.getAttribute('data-action');
  if (action === 'edit') {
    await handleEditExpense(expense);
    return;
  }

  if (action === 'delete') {
    await handleDeleteExpense(expense);
  }
}

async function handleEditExpense(expense) {
  const category = window.prompt('Edit category:', expense.category || '');
  if (category === null) {
    return;
  }

  const amount = window.prompt('Edit amount:', String(expense.amount || ''));
  if (amount === null) {
    return;
  }

  const expenseDate = window.prompt('Edit date (YYYY-MM-DD):', expense.expenseDate || '');
  if (expenseDate === null) {
    return;
  }

  const description = window.prompt('Edit description (optional):', expense.description || '');
  if (description === null) {
    return;
  }

  if (!category.trim() || !amount.trim() || !expenseDate.trim()) {
    window.alert('Category, amount and date are required.');
    return;
  }

  if (!/^\d{4}-\d{2}-\d{2}$/.test(expenseDate.trim())) {
    window.alert('Date must be in YYYY-MM-DD format.');
    return;
  }

  try {
    const params = new URLSearchParams();
    params.append('expenseId', String(expense.id));
    params.append('category', category.trim());
    params.append('amount', amount.trim());
    params.append('expenseDate', expenseDate.trim());
    params.append('description', description.trim());

    const result = await requestJson('api/budget/update', params);
    if (!result.success) {
      throw new Error(result.error || 'Failed to update expense');
    }

    await loadExpenses();
    await loadStats();
  } catch (error) {
    console.error('Error updating expense:', error);
    window.alert(`Error updating expense: ${error.message}`);
  }
}

async function handleDeleteExpense(expense) {
  const confirmed = window.confirm(`Delete expense of INR ${Number.parseFloat(expense.amount).toFixed(2)} on ${expense.expenseDate}?`);
  if (!confirmed) {
    return;
  }

  try {
    const params = new URLSearchParams();
    params.append('expenseId', String(expense.id));

    const result = await requestJson('api/budget/delete', params);
    if (!result.success) {
      throw new Error(result.error || 'Failed to delete expense');
    }

    await loadExpenses();
    await loadStats();
  } catch (error) {
    console.error('Error deleting expense:', error);
    window.alert(`Error deleting expense: ${error.message}`);
  }
}

async function loadExpenses() {
  const expenseList = document.getElementById('expense-list');
  const noExpensesMessage = document.getElementById('no-expenses-message');

  try {
    const params = new URLSearchParams();
    params.append('startDate', '');
    params.append('endDate', '');

    const data = await requestJson('api/budget/get', params);

    if (!data.success) {
      throw new Error(data.error || 'Failed to load expenses');
    }

    cachedExpenses = Array.isArray(data.expenses) ? data.expenses : [];
    populateCategoryFilter(cachedExpenses);

    if (cachedExpenses.length === 0) {
      expenseList.innerHTML = '';
      noExpensesMessage.hidden = false;
      return cachedExpenses;
    }

    noExpensesMessage.hidden = true;

    const parsed = cachedExpenses
      .map(expense => ({
        ...expense,
        parsedDate: parseExpenseDate(expense.expenseDate),
        amountNumber: Number.parseFloat(expense.amount)
      }))
      .filter(expense => expense.parsedDate && Number.isFinite(expense.amountNumber))
      .sort((a, b) => b.parsedDate.getTime() - a.parsedDate.getTime());

    const yearHistory = buildYearMonthHistory(parsed);
    expenseList.innerHTML = renderYearHistory(yearHistory);

    return cachedExpenses;
  } catch (error) {
    console.error('Error loading expenses:', error);
    expenseList.innerHTML = '';
    noExpensesMessage.hidden = false;
    noExpensesMessage.innerHTML = `<p>Error loading expenses: ${error.message}</p>`;
    return [];
  }
}

function buildYearMonthHistory(expenses) {
  const yearMap = new Map();

  for (const expense of expenses) {
    const year = expense.parsedDate.getFullYear();
    const month = expense.parsedDate.getMonth();

    if (!yearMap.has(year)) {
      yearMap.set(year, {
        year,
        total: 0,
        months: new Map()
      });
    }

    const yearEntry = yearMap.get(year);
    yearEntry.total += expense.amountNumber;

    if (!yearEntry.months.has(month)) {
      yearEntry.months.set(month, {
        month,
        label: new Date(year, month, 1).toLocaleDateString('en-GB', { month: 'long' }),
        total: 0,
        expenses: []
      });
    }

    const monthEntry = yearEntry.months.get(month);
    monthEntry.total += expense.amountNumber;
    monthEntry.expenses.push(expense);
  }

  return [...yearMap.values()]
    .sort((a, b) => b.year - a.year)
    .map(yearEntry => ({
      ...yearEntry,
      months: [...yearEntry.months.values()].sort((a, b) => b.month - a.month)
    }));
}

function renderYearHistory(yearHistory) {
  if (yearHistory.length === 0) {
    return '<p class="expense-empty">No expenses available.</p>';
  }

  return yearHistory
    .map(yearEntry => {
      const monthsHtml = yearEntry.months
        .map(monthEntry => renderExpenseGroup(`${monthEntry.label} ${yearEntry.year}`, monthEntry.total, monthEntry.expenses))
        .join('');

      return `
        <section class="expense-year-group">
          <h3 class="expense-year-title">
            <span>Year ${yearEntry.year}</span>
            <span class="expense-group-total">Year Total: INR ${yearEntry.total.toFixed(2)}</span>
          </h3>
          <div class="expense-year-months">
            ${monthsHtml}
          </div>
        </section>
      `;
    })
    .join('');
}

function renderExpenseGroup(title, totalAmount, expenses) {
  const itemsHtml = expenses.length > 0
    ? expenses.map(renderExpenseItem).join('')
    : '<p class="expense-empty">No expenses in this period yet.</p>';

  return `
    <section class="expense-group">
      <h3 class="expense-group-title">
        <span>${escapeHtml(title)}</span>
        <span class="expense-group-total">Total: INR ${totalAmount.toFixed(2)}</span>
      </h3>
      <div class="expense-group-items">
        ${itemsHtml}
      </div>
    </section>
  `;
}

function renderExpenseItem(expense) {
  const safeAmount = Number.isFinite(expense.amountNumber)
    ? expense.amountNumber.toFixed(2)
    : '0.00';
  const safeCategory = escapeHtml(expense.category || 'Other');
  const safeDate = formatExpenseDate(expense.expenseDate);
  const safeDescription = expense.description
    ? `<p class="expense-description">${escapeHtml(expense.description)}</p>`
    : '';

  return `
    <div class="expense-item">
      <div class="expense-info">
        <p class="expense-category">${safeCategory}</p>
        <p class="expense-date">${safeDate}</p>
        ${safeDescription}
      </div>
      <p class="expense-amount">INR ${safeAmount}</p>
      <div class="expense-actions">
        <button class="expense-action-btn" data-action="edit" data-expense-id="${expense.id}" type="button">Edit</button>
        <button class="expense-action-btn delete" data-action="delete" data-expense-id="${expense.id}" type="button">Delete</button>
      </div>
    </div>
  `;
}

async function requestJson(path, params) {
  const response = await fetch(resolveApiUrl(path), {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8'
    },
    body: params.toString()
  });

  const text = await response.text();
  let data;
  try {
    data = JSON.parse(text);
  } catch (e) {
    throw new Error(`Server returned non-JSON (${response.status}): ${text.substring(0, 120)}`);
  }

  if (!response.ok) {
    throw new Error(data.error || `Server error: ${response.status}`);
  }

  return data;
}

function resolveApiUrl(path) {
  if (typeof toApiUrl === 'function') {
    return toApiUrl(path);
  }
  return path;
}

function populateCategoryFilter(expenses) {
  const filter = document.getElementById('stats-category-filter');
  if (!filter) {
    return;
  }

  const previousSelection = filter.value || '__all__';
  const categories = [...new Set(expenses.map(expense => expense.category).filter(Boolean))].sort();

  filter.innerHTML = '<option value="__all__">All Categories</option>';
  for (const category of categories) {
    const option = document.createElement('option');
    option.value = category;
    option.textContent = category;
    filter.appendChild(option);
  }

  if (categories.includes(previousSelection)) {
    filter.value = previousSelection;
  } else {
    filter.value = '__all__';
  }
}

function parseExpenseDate(dateString) {
  if (!dateString) {
    return null;
  }

  const parsed = new Date(`${dateString}T00:00:00`);
  if (Number.isNaN(parsed.getTime())) {
    return null;
  }

  return parsed;
}

function monthStart(date) {
  return new Date(date.getFullYear(), date.getMonth(), 1);
}

function monthKey(date) {
  return `${date.getFullYear()}-${date.getMonth()}`;
}

function paletteColor(index) {
  const colors = ['#2b76b8', '#64a6dd', '#ff6b6b', '#4ecdc4', '#f7b731', '#5f27cd', '#00b894', '#fd79a8', '#6c5ce7', '#e17055'];
  return colors[index % colors.length];
}

function hexToRgba(hex, alpha) {
  const normalized = hex.replace('#', '');
  const bigint = Number.parseInt(normalized, 16);
  const r = (bigint >> 16) & 255;
  const g = (bigint >> 8) & 255;
  const b = bigint & 255;
  return `rgba(${r}, ${g}, ${b}, ${alpha})`;
}

function formatExpenseDate(dateString) {
  try {
    const date = new Date(`${dateString}T00:00:00`);
    return date.toLocaleDateString('en-GB', {
      day: 'numeric',
      month: 'short',
      year: 'numeric'
    });
  } catch {
    return dateString;
  }
}

function escapeHtml(text) {
  return String(text)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}

function showMessage(element, message, type) {
  element.textContent = message;
  element.className = `message ${type}`;
  element.hidden = false;

  setTimeout(() => {
    element.hidden = true;
  }, 5000);
}
