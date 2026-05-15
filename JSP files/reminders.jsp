<%@ page isELIgnored="true" %>
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Reminders</title>
    <link rel="stylesheet" href="reminders.css" />
  </head>
  <body>
    <div class="app-shell">
      <aside class="sidebar" aria-label="Sidebar navigation">
        <nav>
          <p class="nav-heading">Navigation</p>
          <ul class="nav-list">
            <li><a class="nav-link" href="dashboard.jsp">Home</a></li>
            <li><a class="nav-link" href="history.jsp">History</a></li>
            <li><a class="nav-link is-active" href="reminders.jsp">Reminders</a></li>
            <li><a class="nav-link" href="tracking.jsp">Tracking</a></li>
          </ul>
        </nav>
      </aside>

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

          <button class="logout-btn" type="button">Logout</button>
        </div>
      </header>

      <main class="reminder-main">
        <section class="reminder-shell">
          <header class="reminder-header">
            <h1>Reminders</h1>
            <p class="reminder-subtitle">All reminder notes set from the Home page.</p>
          </header>

          <section id="reminder-empty" class="empty-card" hidden>
            <h2>No reminders yet</h2>
            <p>Click Set Reminder on the Home page to create your first reminder.</p>
          </section>

          <section id="reminder-list" class="reminder-list" aria-label="Saved reminders"></section>
        </section>
      </main>
    </div>

    <script>
      window.APP_CONTEXT_PATH = "<%= request.getContextPath() %>";
    </script>
    <script src="auth.js"></script>
    <script src="sync.js"></script>
    <script src="reminder-alarm.js"></script>
    <script>
      // Check if user is logged in, redirect to login if not
      requireLogin();
      RTRPSync.setupAutoSync();
      RTRPSync.initialLoad();

      const todayElement = document.getElementById("today-date");
      const calendarInput = document.getElementById("calendar-input");
      const calendarTrigger = document.getElementById("calendar-trigger");

      function formatDisplayDate(date) {
        return date.toLocaleDateString("en-GB", {
          day: "2-digit",
          month: "short",
          year: "numeric",
        });
      }

      if (todayElement) {
        const currentDate = new Date();
        todayElement.textContent = formatDisplayDate(currentDate);
      }

      if (calendarTrigger && calendarInput) {
        calendarTrigger.addEventListener("click", () => {
          calendarInput.showPicker();
        });
        calendarInput.addEventListener("change", () => {
          const selectedDate = new Date(calendarInput.value);
          if (!Number.isNaN(selectedDate.getTime()) && todayElement) {
            todayElement.textContent = formatDisplayDate(selectedDate);
          }
        });
      }

      const reminderList = document.getElementById("reminder-list");
      const reminderEmpty = document.getElementById("reminder-empty");

      function readReminders() {
        return window.RTRPReminders.readReminders();
      }

      function formatReminderDate(dateValue) {
        const date = new Date(dateValue);
        if (Number.isNaN(date.getTime())) {
          return "Invalid date";
        }

        return date.toLocaleString("en-GB", {
          day: "2-digit",
          month: "short",
          year: "numeric",
          hour: "2-digit",
          minute: "2-digit",
        });
      }

      function escapeHtml(text) {
        return String(text)
          .replaceAll("&", "&amp;")
          .replaceAll("<", "&lt;")
          .replaceAll(">", "&gt;")
          .replaceAll('"', "&quot;")
          .replaceAll("'", "&#39;");
      }

      function deleteReminderById(id) {
        window.RTRPReminders.deleteReminder(id);
        renderReminders();
      }

      function renderReminders() {
        const reminders = readReminders().sort((a, b) => {
          const aDate = new Date(a.nextTriggerAt || a.reminderAt);
          const bDate = new Date(b.nextTriggerAt || b.reminderAt);
          return aDate - bDate;
        });

        if (reminders.length === 0) {
          reminderEmpty.hidden = false;
          reminderList.innerHTML = "";
          return;
        }

        reminderEmpty.hidden = true;
        reminderList.innerHTML = reminders
          .map(
            (item) => `
              <article class="reminder-card">
                <p class="reminder-time">${formatReminderDate(item.nextTriggerAt || item.reminderAt)}</p>
                <p class="reminder-repeat">${window.RTRPReminders.formatRepeatLabel(item.repeat)} | ${
              item.soundEnabled ? "Sound on" : "Sound off"
            }</p>
                <p class="reminder-note">${escapeHtml(item.note || "")}</p>
                <button class="delete-btn" type="button" data-delete-id="${item.id}">Delete</button>
              </article>
            `
          )
          .join("");
      }

      reminderList.addEventListener("click", (event) => {
        const target = event.target;
        if (!(target instanceof HTMLElement)) {
          return;
        }

        const deleteButton = target.closest("[data-delete-id]");
        if (!deleteButton) {
          return;
        }

        const reminderId = deleteButton.getAttribute("data-delete-id");
        if (!reminderId) {
          return;
        }

        const confirmed = window.confirm("Delete this reminder?");
        if (!confirmed) {
          return;
        }

        deleteReminderById(reminderId);
      });

      renderReminders();
    </script>
  </body>
</html>
