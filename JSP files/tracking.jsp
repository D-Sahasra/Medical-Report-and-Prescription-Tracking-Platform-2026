<%@ page isELIgnored="true" %>
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Journal Tracking</title>
    <link rel="stylesheet" href="tracking.css" />
  </head>
  <body>
    <div class="app-shell">
      <aside class="sidebar" aria-label="Sidebar navigation">
        <nav>
          <p class="nav-heading">Navigation</p>
          <ul class="nav-list">
            <li><a class="nav-link" href="dashboard.jsp">Home</a></li>
            <li><a class="nav-link" href="history.jsp">History</a></li>
            <li><a class="nav-link" href="reminders.jsp">Reminders</a></li>
            <li><a class="nav-link is-active" href="tracking.jsp">Tracking</a></li>
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

      <main class="tracking-main">
        <section class="tracking-shell">
          <header class="tracking-header">
            <h1>Journal Tracking</h1>
            <p class="tracking-subtitle">All saved journals are listed here.</p>
          </header>

          <section id="tracking-empty" class="empty-card" hidden>
            <h2>No saved journals yet</h2>
            <p>Open Journal from Home and start writing to create your first tracked entry.</p>
          </section>

          <section id="tracking-list" class="tracking-list" aria-label="Saved journal entries"></section>
        </section>
      </main>
    </div>

    <div class="modal-backdrop" id="journal-modal" aria-hidden="true">
      <section class="modal-card" role="dialog" aria-modal="true" aria-labelledby="journal-modal-title">
        <button class="modal-close" id="journal-close" type="button" aria-label="Close journal view">x</button>
        <h2 id="journal-modal-title">Journal Entry</h2>
        <p class="modal-date" id="journal-modal-date"></p>
        <article class="modal-content" id="journal-modal-content"></article>
      </section>
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

      const JOURNAL_LIST_KEY = "rtrp-journal-entries";
      const LEGACY_CONTENT_KEY = "rtrp-journal-content";
      const LEGACY_TITLE_KEY = "rtrp-journal-title";
      const trackingList = document.getElementById("tracking-list");
      const trackingEmpty = document.getElementById("tracking-empty");
      const journalModal = document.getElementById("journal-modal");
      const journalClose = document.getElementById("journal-close");
      const journalModalTitle = document.getElementById("journal-modal-title");
      const journalModalDate = document.getElementById("journal-modal-date");
      const journalModalContent = document.getElementById("journal-modal-content");

      function createEntryId() {
        if (window.crypto && typeof window.crypto.randomUUID === "function") {
          return window.crypto.randomUUID();
        }
        return `journal-${Date.now()}-${Math.floor(Math.random() * 1000000)}`;
      }

      function readEntries() {
        try {
          const raw = localStorage.getItem(JOURNAL_LIST_KEY);
          const parsed = JSON.parse(raw || "[]");
          return Array.isArray(parsed) ? parsed : [];
        } catch {
          return [];
        }
      }

      function saveEntries(entries) {
        localStorage.setItem(JOURNAL_LIST_KEY, JSON.stringify(entries));
      }

      function migrateLegacyDraft() {
        const entries = readEntries();
        if (entries.length > 0) {
          return;
        }

        const legacyHtml = localStorage.getItem(LEGACY_CONTENT_KEY) || "";
        const legacyTitle = (localStorage.getItem(LEGACY_TITLE_KEY) || "").trim();
        const legacyText = new DOMParser()
          .parseFromString(legacyHtml, "text/html")
          .body.textContent.trim();

        if (!legacyTitle && !legacyText) {
          return;
        }

        const now = new Date().toISOString();
        saveEntries([
          {
            id: createEntryId(),
            title: legacyTitle,
            contentHtml: legacyHtml,
            contentText: legacyText,
            createdAt: now,
            updatedAt: now,
          },
        ]);
      }

      function escapeHtml(text) {
        return String(text)
          .replaceAll("&", "&amp;")
          .replaceAll("<", "&lt;")
          .replaceAll(">", "&gt;")
          .replaceAll('"', "&quot;")
          .replaceAll("'", "&#39;");
      }

      function formatDate(value) {
        const date = new Date(value);
        if (Number.isNaN(date.getTime())) {
          return "Unknown date";
        }

        return date.toLocaleString("en-GB", {
          day: "2-digit",
          month: "short",
          year: "numeric",
          hour: "2-digit",
          minute: "2-digit",
        });
      }

      function renderEntries() {
        const entries = readEntries().slice().sort((a, b) => new Date(b.updatedAt) - new Date(a.updatedAt));

        if (entries.length === 0) {
          trackingEmpty.hidden = false;
          trackingList.innerHTML = "";
          return;
        }

        trackingEmpty.hidden = true;
        trackingList.innerHTML = entries
          .map((entry) => {
            const title = entry.title ? escapeHtml(entry.title) : "Untitled journal";
            const preview = entry.contentText
              ? escapeHtml(entry.contentText).slice(0, 180)
              : "No text content";

            return `
              <article class="entry-card">
                <div class="entry-header">
                  <h2>${title}</h2>
                  <p>${formatDate(entry.updatedAt || entry.createdAt)}</p>
                </div>
                <p class="entry-preview">${preview}</p>
                <div class="entry-actions">
                  <button type="button" class="view-btn" data-view-id="${entry.id}">View</button>
                  <button type="button" class="edit-btn" data-edit-id="${entry.id}">Edit</button>
                  <button type="button" class="delete-btn" data-delete-id="${entry.id}">Delete</button>
                </div>
              </article>
            `;
          })
          .join("");
      }

      function openModal(entry) {
        journalModalTitle.textContent = entry.title || "Untitled journal";
        journalModalDate.textContent = formatDate(entry.updatedAt || entry.createdAt);
        journalModalContent.innerHTML = entry.contentHtml || "<p>No content.</p>";
        journalModal.classList.add("is-open");
        journalModal.setAttribute("aria-hidden", "false");
      }

      function closeModal() {
        journalModal.classList.remove("is-open");
        journalModal.setAttribute("aria-hidden", "true");
      }

      function deleteEntryById(id) {
        const entries = readEntries();
        const nextEntries = entries.filter((entry) => entry.id !== id);
        saveEntries(nextEntries);
        renderEntries();
      }

      trackingList.addEventListener("click", (event) => {
        const target = event.target;
        if (!(target instanceof HTMLElement)) {
          return;
        }

        const viewButton = target.closest("[data-view-id]");
        if (viewButton) {
          const entryId = viewButton.getAttribute("data-view-id");
          const entry = readEntries().find((item) => item.id === entryId);
          if (entry) {
            openModal(entry);
          }
          return;
        }

        const editButton = target.closest("[data-edit-id]");
        if (editButton) {
          const entryId = editButton.getAttribute("data-edit-id");
          if (entryId) {
            localStorage.setItem("rtrp-active-journal-id", entryId);
            window.location.href = `journal.jsp?entryId=${encodeURIComponent(entryId)}`;
          }
          return;
        }

        const deleteButton = target.closest("[data-delete-id]");
        if (deleteButton) {
          const entryId = deleteButton.getAttribute("data-delete-id");
          const confirmed = window.confirm("Delete this journal entry from tracking?");
          if (!confirmed) {
            return;
          }
          deleteEntryById(entryId);
        }
      });

      journalClose.addEventListener("click", closeModal);
      journalModal.addEventListener("click", (event) => {
        if (event.target === journalModal) {
          closeModal();
        }
      });

      document.addEventListener("keydown", (event) => {
        if (event.key === "Escape" && journalModal.classList.contains("is-open")) {
          closeModal();
        }
      });

      migrateLegacyDraft();
      renderEntries();
    </script>
  </body>
</html>
