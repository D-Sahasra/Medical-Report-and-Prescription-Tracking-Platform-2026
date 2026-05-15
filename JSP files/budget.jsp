<%@ page isELIgnored="true" %>
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Budget Analysis</title>
    <link rel="stylesheet" href="styles.css" />
    <link rel="stylesheet" href="budget.css" />
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
  </head>
  <body>
    <div class="app-shell">
      <aside class="sidebar" aria-label="Sidebar navigation">
        

        <nav>
          <p class="nav-heading">Navigation</p><br><br>
          <ul class="nav-list">
            <li><a class="nav-link" href="dashboard.jsp">Home</a></li>
            <li><a class="nav-link" href="history.jsp">History</a></li>
            <li><a class="nav-link" href="reminders.jsp">Reminders</a></li>
            <li><a class="nav-link" href="tracking.jsp">Tracking</a></li>
          </ul>
        </nav>
      </aside>

      <div class="main-region">
        <header class="topbar">
          <div class="logo-area" aria-label="Logo">
            <span class="logo-chip"><i>Healger</i></span>
          </div>

          <div class="topbar-actions">
            <a href="profile.jsp" class="profile-box" aria-label="Profile" title="Profile">
              <div class="avatar">TU</div>
              <span>Profile</span>
            </a>

            <div class="calendar-box" aria-label="Calendar">
              <span id="calendar-trigger" style="cursor: pointer;">Calendar</span>
              <input
                id="calendar-input"
                type="date"
                aria-label="Pick a date"
                style="position: absolute; opacity: 0; width: 1px; height: 1px; pointer-events: none;"
              />
              <span id="today-date"></span>
            </div>

            <button class="logout-btn" type="button" id="logout-btn">Logout</button>
          </div>
        </header>

        <main class="budget-main">
          <section class="budget-shell">
            <header class="budget-header">
              <h1>Budget Analysis</h1>
              <p class="budget-subtitle">Track and analyze your healthcare expenses</p>
            </header>

            <div class="budget-container">
              <section class="budget-form-section">
                <h2>Add Expense</h2>
                <form id="expense-form" class="expense-form">
                  <div class="form-group">
                    <label for="expense-category">Category</label>
                    <select id="expense-category" name="category" required>
                      <option value="">Select a category</option>
                      <option value="Diagnostic Imaging">Diagnostic Imaging (X-rays, CT scans, MRI)</option>
                      <option value="Ultrasound">Ultrasound Imaging</option>
                      <option value="Laboratory Tests">Laboratory Tests & Blood Work</option>
                      <option value="General Consultation">General Consultation</option>
                      <option value="Specialist Consultation">Specialist Consultation</option>
                      <option value="General Checkup">General Health Checkup</option>
                      <option value="Preventive Care">Preventive Care & Vaccinations</option>
                      <option value="Diabetes Management">Diabetes Management & Medication</option>
                      <option value="Hypertension Medication">Hypertension Medication</option>
                      <option value="Cardiovascular Medicine">Cardiovascular Medicine</option>
                      <option value="Joint & Bone Medicine">Joint & Bone Medicine</option>
                      <option value="Thyroid Treatment">Thyroid Treatment</option>
                      <option value="Mental Health">Mental Health Services</option>
                      <option value="Dental Care">Dental Care & Treatment</option>
                      <option value="Vision Care">Vision Care & Glasses</option>
                      <option value="Physical Therapy">Physical Therapy & Rehabilitation</option>
                      <option value="Surgical Procedure">Surgical Procedure</option>
                      <option value="Emergency Care">Emergency Care</option>
                      <option value="Prescription Medication">Prescription Medication</option>
                      <option value="Over-the-Counter">Over-the-Counter Medication</option>
                      <option value="Hospital Stay">Hospital Stay & Room Charges</option>
                      <option value="Medical Equipment">Medical Equipment & Devices</option>
                      <option value="Other">Other Healthcare Expense</option>
                    </select>
                  </div>

                  <div class="form-group">
                    <label for="expense-amount">Amount (₹)</label>
                    <input type="number" id="expense-amount" name="amount" placeholder="0.00" step="0.01" min="0" required />
                  </div>

                  <div class="form-group">
                    <label for="expense-date">Date</label>
                    <input type="date" id="expense-date" name="expenseDate" required />
                  </div>

                  <div class="form-group">
                    <label for="expense-description">Description (Optional)</label>
                    <input type="text" id="expense-description" name="description" placeholder="e.g., Annual checkup" />
                  </div>

                  <button type="submit" class="btn btn-primary">Add Expense</button>
                </form>
                <div id="form-message" class="message" hidden></div>
              </section>

              <section class="budget-stats-section">
                <h2>Expense Statistics</h2>
                <div class="stats-controls">
                  <div class="form-group">
                    <label for="period-select">Time Period</label>
                    <select id="period-select">
                      <option value="month">Monthly View (Daily Trend)</option>
                      <option value="year">Yearly View (Monthly Trend)</option>
                      <option value="rolling">Last 12 Months</option>
                      <option value="customrange">Custom Month Range</option>
                    </select>
                  </div>

                  <div class="form-group">
                    <label for="stats-category-filter">Category</label>
                    <select id="stats-category-filter">
                      <option value="__all__">All Categories</option>
                    </select>
                  </div>

                  <div class="form-group" id="year-month-group" hidden>
                    <label for="year-select">Year</label>
                    <select id="year-select"></select>
                  </div>

                  <div class="form-group" id="month-group" hidden>
                    <label for="month-select">Month</label>
                    <select id="month-select">
                      <option value="1">January</option>
                      <option value="2">February</option>
                      <option value="3">March</option>
                      <option value="4">April</option>
                      <option value="5">May</option>
                      <option value="6">June</option>
                      <option value="7">July</option>
                      <option value="8">August</option>
                      <option value="9">September</option>
                      <option value="10">October</option>
                      <option value="11">November</option>
                      <option value="12">December</option>
                    </select>
                  </div>

                  <div class="range-group" id="custom-range-group" hidden>
                    <div class="form-group">
                      <label for="start-year-select">From Year</label>
                      <select id="start-year-select"></select>
                    </div>

                    <div class="form-group">
                      <label for="start-month-select">From Month</label>
                      <select id="start-month-select">
                        <option value="1">January</option>
                        <option value="2">February</option>
                        <option value="3">March</option>
                        <option value="4">April</option>
                        <option value="5">May</option>
                        <option value="6">June</option>
                        <option value="7">July</option>
                        <option value="8">August</option>
                        <option value="9">September</option>
                        <option value="10">October</option>
                        <option value="11">November</option>
                        <option value="12">December</option>
                      </select>
                    </div>

                    <div class="form-group">
                      <label for="end-year-select">To Year</label>
                      <select id="end-year-select"></select>
                    </div>

                    <div class="form-group">
                      <label for="end-month-select">To Month</label>
                      <select id="end-month-select">
                        <option value="1">January</option>
                        <option value="2">February</option>
                        <option value="3">March</option>
                        <option value="4">April</option>
                        <option value="5">May</option>
                        <option value="6">June</option>
                        <option value="7">July</option>
                        <option value="8">August</option>
                        <option value="9">September</option>
                        <option value="10">October</option>
                        <option value="11">November</option>
                        <option value="12">December</option>
                      </select>
                    </div>
                  </div>

                  <button id="load-stats-btn" class="btn btn-secondary">Load Statistics</button>
                </div>

                <div class="chart-container">
                  <canvas id="stats-chart"></canvas>
                </div>

                <div id="no-data-message" class="empty-message" hidden>
                  <p>No expenses recorded for this period.</p>
                </div>
              </section>

              <section class="expense-list-section">
                <h2>Expenses</h2>
                <div id="expense-list" class="expense-list"></div>
                <div id="no-expenses-message" class="empty-message" hidden>
                  <p>No expenses yet. Add your first expense above.</p>
                </div>
              </section>
            </div>
          </section>
        </main>
      </div>
    </div>

    <script>
      window.APP_CONTEXT_PATH = "<%= request.getContextPath() %>";
    </script>
    <script src="auth.js"></script>
    <script src="budget.js"></script>
    <script>
      requireLogin();
      initializeBudget();
      
      // Logout button
      document.getElementById('logout-btn').addEventListener('click', async () => {
        try {
          const response = await fetch('api/auth/logout', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8'
            }
          });
          if (response.ok) {
            window.location.href = 'login.jsp';
          }
        } catch (error) {
          console.error('Logout error:', error);
        }
      });
    </script>
  </body>
</html>
