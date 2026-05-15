<%@ page isELIgnored="true" %>
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Upload History</title>
    <link rel="stylesheet" href="history.css" />
  </head>
  <body>
    <div class="app-shell">
      <aside class="sidebar" aria-label="Sidebar navigation">
        <nav>
          <p class="nav-heading">Navigation</p>
          <ul class="nav-list">
            <li><a class="nav-link" href="dashboard.jsp">Home</a></li>
            <li><a class="nav-link is-active" href="history.jsp">History</a></li>
            <li><a class="nav-link" href="reminders.jsp">Reminders</a></li>
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

      <main class="history-main">
        <section class="history-shell">
          <header class="history-header">
            <h1>Upload History</h1>
            <p class="history-subtitle">Uploads grouped by category</p>
          </header>

          <section id="history-empty" class="empty-card" hidden>
            <h2>No uploads yet</h2>
            <p>Use the Upload circle on the home to add your first image with a category.</p>
          </section>

          <section id="history-groups" class="group-list" aria-label="Grouped upload history"></section>
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

      const STORAGE_KEY = "rtrp-upload-items";
      const groupsContainer = document.getElementById("history-groups");
      const emptyCard = document.getElementById("history-empty");

      function formatDate(isoDate) {
        const date = new Date(isoDate);
        if (Number.isNaN(date.getTime())) {
          return "Unknown date";
        }

        return date.toLocaleDateString("en-GB", {
          day: "2-digit",
          month: "short",
          year: "numeric",
        });
      }

      function readUploads() {
        try {
          const raw = localStorage.getItem(STORAGE_KEY);
          const parsed = JSON.parse(raw || "[]");
          return Array.isArray(parsed)
            ? parsed.map((item, index) => ({
                ...item,
                _id: index,
              }))
            : [];
        } catch {
          return [];
        }
      }

      function escapeHtml(text) {
        return String(text)
          .replaceAll("&", "&amp;")
          .replaceAll("<", "&lt;")
          .replaceAll(">", "&gt;")
          .replaceAll('"', "&quot;")
          .replaceAll("'", "&#39;");
      }

      function deleteUploadById(id) {
        const uploads = readUploads();
        const nextUploads = uploads
          .filter((item) => item._id !== id)
          .map(({ _id, ...rest }) => rest);

        localStorage.setItem(STORAGE_KEY, JSON.stringify(nextUploads));
        renderHistory();
      }

      function groupByCategory(items) {
        return items.reduce((grouped, item) => {
          const category = (item.category || "Uncategorized").trim() || "Uncategorized";
          if (!grouped[category]) {
            grouped[category] = [];
          }
          grouped[category].push(item);
          return grouped;
        }, {});
      }

      function renderHistory() {
        const uploads = readUploads();

        if (uploads.length === 0) {
          emptyCard.hidden = false;
          groupsContainer.innerHTML = "";
          return;
        }

        emptyCard.hidden = true;
        const grouped = groupByCategory(uploads);
        const sortedCategories = Object.keys(grouped).sort((a, b) => a.localeCompare(b));

        groupsContainer.innerHTML = sortedCategories
          .map((category) => {
            const cards = grouped[category]
              .slice()
              .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
              .map(
                (item) => `
                  <article class="upload-card">
                    <img src="${item.image}" alt="${escapeHtml(category)} upload" loading="lazy" />
                    <div class="card-meta">
                      <p class="meta-category">${escapeHtml(category)}</p>
                      <p class="meta-date">${formatDate(item.createdAt)}</p>
                      <button class="delete-btn" type="button" data-delete-id="${item._id}">Delete</button>
                    </div>
                  </article>
                `
              )
              .join("");

            return `
              <section class="category-group">
                <h2>${category}</h2>
                <div class="cards-grid">${cards}</div>
              </section>
            `;
          })
          .join("");
      }

      groupsContainer.addEventListener("click", (event) => {
        const target = event.target;
        if (!(target instanceof HTMLElement)) {
          return;
        }

        const deleteButton = target.closest("[data-delete-id]");
        if (!deleteButton) {
          return;
        }

        const uploadId = Number(deleteButton.getAttribute("data-delete-id"));
        if (!Number.isInteger(uploadId)) {
          return;
        }

        const confirmed = window.confirm("Delete this upload?");
        if (!confirmed) {
          return;
        }

        deleteUploadById(uploadId);
      });

      renderHistory();
    </script>
  </body>
</html>
