<%@ page isELIgnored="true" %>
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Journal Notes</title>
    <link rel="stylesheet" href="journal.css" />
  </head>
  <body>
    <main class="journal-shell">
      <header class="journal-header">
        <a class="back-link" href="dashboard.jsp" aria-label="Back to dashboard">Back</a>
        <h1>Journal</h1>
        <p class="save-state" id="save-state">Saved</p>
      </header>

      <section class="note-board" aria-label="Journal note board">
        <div class="note-topbar">
          <label class="title-group" for="note-title">Title</label>
          <input id="note-title" type="text" maxlength="80" placeholder="Today notes" />
        </div>

        <div class="toolbar" role="toolbar" aria-label="Note tools">
          <button type="button" class="tool-btn" id="bullet-btn">Pointer List</button>
          <button type="button" class="tool-btn" id="checkbox-btn">Checkbox</button>
          <button type="button" class="tool-btn" id="image-btn">Upload Image</button>
          <button type="button" class="tool-btn tool-btn-danger" id="clear-btn">Clear</button>
          <input id="image-input" type="file" accept="image/*" hidden />
        </div>

        <div
          id="note-editor"
          class="note-editor"
          contenteditable="true"
          data-placeholder="Start writing your notes..."
          spellcheck="true"
          aria-label="Journal editor"
        ></div>
      </section>
    </main>

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

      const STORAGE_KEY = "rtrp-journal-content";
      const TITLE_KEY = "rtrp-journal-title";
      const JOURNAL_LIST_KEY = "rtrp-journal-entries";
      const ACTIVE_ENTRY_ID_KEY = "rtrp-active-journal-id";
      const editor = document.getElementById("note-editor");
      const titleInput = document.getElementById("note-title");
      const saveState = document.getElementById("save-state");
      const bulletBtn = document.getElementById("bullet-btn");
      const checkboxBtn = document.getElementById("checkbox-btn");
      const imageBtn = document.getElementById("image-btn");
      const imageInput = document.getElementById("image-input");
      const clearBtn = document.getElementById("clear-btn");
      let saveTimer;

      function createEntryId() {
        if (window.crypto && typeof window.crypto.randomUUID === "function") {
          return window.crypto.randomUUID();
        }
        return `journal-${Date.now()}-${Math.floor(Math.random() * 1000000)}`;
      }

      function readJournalEntries() {
        try {
          const raw = localStorage.getItem(JOURNAL_LIST_KEY);
          const parsed = JSON.parse(raw || "[]");
          return Array.isArray(parsed) ? parsed : [];
        } catch {
          return [];
        }
      }

      function saveJournalEntries(entries) {
        localStorage.setItem(JOURNAL_LIST_KEY, JSON.stringify(entries));
      }

      function findEntryById(entryId) {
        if (!entryId) {
          return null;
        }
        return readJournalEntries().find((entry) => entry && entry.id === entryId) || null;
      }

      function normalizeEditorHtml(html) {
        const value = typeof html === "string" ? html.trim() : "";
        if (!value || value === "<p>Start writing your notes...</p>") {
          return "";
        }
        return value;
      }

      function upsertJournalEntry() {
        const title = titleInput.value.trim();
        const contentHtml = editor.innerHTML;
        const contentText = editor.textContent.trim();

        if (!title && !contentText) {
          return;
        }

        const entries = readJournalEntries();
        const now = new Date().toISOString();
        const activeId = localStorage.getItem(ACTIVE_ENTRY_ID_KEY);
        const activeIndex = activeId
          ? entries.findIndex((entry) => entry && entry.id === activeId)
          : -1;

        if (activeIndex >= 0) {
          entries[activeIndex] = {
            ...entries[activeIndex],
            title,
            contentHtml,
            contentText,
            updatedAt: now,
          };
          saveJournalEntries(entries);
          return;
        }

        const entryId = createEntryId();
        localStorage.setItem(ACTIVE_ENTRY_ID_KEY, entryId);
        entries.unshift({
          id: entryId,
          title,
          contentHtml,
          contentText,
          createdAt: now,
          updatedAt: now,
        });
        saveJournalEntries(entries);
      }

      function setSaveState(text) {
        saveState.textContent = text;
      }

      function saveNotes() {
        localStorage.setItem(STORAGE_KEY, editor.innerHTML);
        localStorage.setItem(TITLE_KEY, titleInput.value.trim());
        upsertJournalEntry();
        setSaveState("Saved");
      }

      function scheduleSave() {
        setSaveState("Saving...");
        clearTimeout(saveTimer);
        saveTimer = setTimeout(saveNotes, 300);
      }

      function insertAtCaret(html) {
        editor.focus();
        const selection = window.getSelection();

        if (!selection || selection.rangeCount === 0) {
          editor.insertAdjacentHTML("beforeend", html);
          scheduleSave();
          return;
        }

        const range = selection.getRangeAt(0);
        range.deleteContents();

        const temp = document.createElement("div");
        temp.innerHTML = html;
        const fragment = document.createDocumentFragment();
        let node;

        while ((node = temp.firstChild)) {
          fragment.appendChild(node);
        }

        range.insertNode(fragment);
        range.collapse(false);
        selection.removeAllRanges();
        selection.addRange(range);
        scheduleSave();
      }

      const params = new URLSearchParams(window.location.search);
      const queryEntryId = params.get("entryId");
      const selectedEntry = findEntryById(queryEntryId);

      if (selectedEntry) {
        editor.innerHTML = normalizeEditorHtml(selectedEntry.contentHtml);
        titleInput.value = selectedEntry.title || "";
        localStorage.setItem(ACTIVE_ENTRY_ID_KEY, selectedEntry.id);
        localStorage.setItem(STORAGE_KEY, editor.innerHTML);
        localStorage.setItem(TITLE_KEY, titleInput.value);
      } else {
        localStorage.removeItem(ACTIVE_ENTRY_ID_KEY);
        localStorage.removeItem(STORAGE_KEY);
        localStorage.removeItem(TITLE_KEY);
        editor.innerHTML = "";
        titleInput.value = "";
      }

      editor.addEventListener("input", scheduleSave);
      titleInput.addEventListener("input", scheduleSave);

      bulletBtn.addEventListener("click", () => {
        insertAtCaret("<ul><li></li></ul>");
      });

      checkboxBtn.addEventListener("click", () => {
        insertAtCaret(
          '<label class="checkbox-row"><input type="checkbox" /> <span></span></label><br />'
        );
      });

      imageBtn.addEventListener("click", () => {
        imageInput.click();
      });

      imageInput.addEventListener("change", () => {
        const [file] = imageInput.files;
        if (!file) {
          return;
        }

        const reader = new FileReader();
        reader.onload = (event) => {
          const src = event.target?.result;
          if (typeof src === "string") {
            insertAtCaret(`<img class="note-image" src="${src}" alt="Uploaded note" />`);
          }
        };
        reader.readAsDataURL(file);
        imageInput.value = "";
      });

      clearBtn.addEventListener("click", () => {
        const confirmed = window.confirm("Clear all saved journal notes?");
        if (!confirmed) {
          return;
        }

        editor.innerHTML = "";
        titleInput.value = "";
        localStorage.removeItem(ACTIVE_ENTRY_ID_KEY);
        saveNotes();
      });
    </script>
  </body>
</html>
