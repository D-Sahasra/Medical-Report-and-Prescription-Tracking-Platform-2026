<%@ page isELIgnored="true" %>
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Profile</title>
    <link rel="stylesheet" href="styles.css" />
    <link rel="stylesheet" href="profile.css" />
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

        <main class="profile-main">
          <section class="profile-shell">
            <header class="profile-header">
              <h1>User Profile</h1>
              <p class="profile-subtitle">Manage your account information</p>
            </header>

            <section id="profile-loading" class="loading">
              <p>Loading profile...</p>
            </section>

            <section id="profile-content" class="profile-content" hidden>
              <div class="profile-card">
                <div class="profile-field">
                  <label>Username</label>
                  <p id="profile-username" class="profile-value">-</p>
                </div>
                <div class="profile-field">
                  <label>Email</label>
                  <p id="profile-email" class="profile-value">-</p>
                </div>
                <div class="profile-field">
                  <label>Full Name</label>
                  <p id="profile-fullname" class="profile-value">-</p>
                </div>
                <div class="profile-field">
                  <label>Date of Birth</label>
                  <p id="profile-dob" class="profile-value">-</p>
                </div>
                <div class="profile-field">
                  <label>Mobile Number</label>
                  <p id="profile-mobile" class="profile-value">-</p>
                </div>
                <div class="profile-field">
                  <label>Security Question</label>
                  <p id="profile-security-question" class="profile-value">-</p>
                </div>
              </div>

              <div class="profile-actions">
                <button id="logout-btn-profile" class="btn btn-primary">Logout</button>
                <button id="delete-account-btn" class="btn btn-danger">Delete Account</button>
              </div>
            </section>

            <section id="profile-error" class="error-message" hidden></section>
          </section>
        </main>
      </div>
    </div>

    <script>
      window.APP_CONTEXT_PATH = "<%= request.getContextPath() %>";
    </script>
    <script src="auth.js"></script>
    <script src="profile.js"></script>
    <script>
      requireLogin();
      loadProfile();
    </script>
  </body>
</html>
