<%@ page isELIgnored="true" %>
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>RTRP Dashboard</title>
    <link rel="stylesheet" href="styles.css" />
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

            <button class="logout-btn" type="button">Logout</button>
          </div>
        </header>

        <main class="dashboard-content">
          <section class="circle-grid" aria-label="Quick actions">
            <button class="circle-card" id="upload-trigger" type="button">Upload</button>
            <button class="circle-card" id="reminder-trigger" type="button">Set Reminder</button>
            <a class="circle-card circle-link" href="budget.jsp">Budget Analysis</a>
            <a class="circle-card circle-link" href="journal.jsp">Journal</a>
          </section>
        </main>
      </div>
    </div>

    <div class="modal-backdrop" id="upload-modal" aria-hidden="true">
      <section class="modal-card" role="dialog" aria-modal="true" aria-labelledby="upload-modal-title">
        <button class="modal-close" id="upload-close" type="button" aria-label="Close upload popup">x</button>
        <h2 id="upload-modal-title">Upload Image</h2>
        <p class="modal-note">Choose an image and add a category before saving.</p>

        <form id="upload-form" class="upload-form">
          <label for="upload-image">Image</label>
          <input id="upload-image" name="image" type="file" accept="image/*" required />

          <label for="upload-category-select">Category</label>
          <select id="upload-category-select" name="category" required>
            <option value="other">Other</option>
            <option value="Orthopaedic">Orthopaedic</option>
            <option value="Cardiac">Cardiac</option>
            <option value="Neurology">Neurology</option>
            <option value="Dermatology">Dermatology</option>
            <option value="ENT">ENT</option>
            <option value="Ophthalmology">Ophthalmology</option>
            <option value="Dental">Dental</option>
            <option value="Gynaecology">Gynaecology</option>
            <option value="Paediatrics">Paediatrics</option>
            <option value="Psychiatry">Psychiatry</option>
            <option value="General Medicine">General Medicine</option>
          </select>

          <input
            id="upload-category-other"
            name="categoryOther"
            type="text"
            maxlength="40"
            placeholder="Enter custom category"
            required
          />

          <img id="upload-preview" class="upload-preview" alt="Selected upload preview" hidden />

          <div class="modal-actions">
            <button type="button" class="btn-ghost" id="upload-cancel">Cancel</button>
            <button type="submit" class="btn-primary">Save Upload</button>
          </div>
        </form>
      </section>
    </div>

    <div class="modal-backdrop" id="reminder-modal" aria-hidden="true">
      <section class="modal-card" role="dialog" aria-modal="true" aria-labelledby="reminder-modal-title">
        <button class="modal-close" id="reminder-close" type="button" aria-label="Close reminder popup">x</button>
        <h2 id="reminder-modal-title">Set Reminder</h2>
        <p class="modal-note">One-time uses date/time. Repeating reminders use time only.</p>

        <form id="reminder-form" class="upload-form">
          <label for="reminder-repeat">Repeat</label>
          <select id="reminder-repeat" name="repeat">
            <option value="none">One-time</option>
            <option value="daily">Daily</option>
            <option value="no-sundays">No Sundays</option>
            <option value="weekly">Weekly</option>
            <option value="biweekly">Biweekly</option>
          </select>

          <label for="reminder-date-time" id="reminder-date-time-label">Reminder Date & Time</label>
          <input id="reminder-date-time" name="dateTime" type="datetime-local" required />

          <label for="reminder-time" id="reminder-time-label" hidden>Reminder Time</label>
          <input id="reminder-time" name="time" type="time" hidden />

          <label for="reminder-weekday" id="reminder-weekday-label" hidden>Day of Week</label>
          <select id="reminder-weekday" name="weekday" hidden>
            <option value="0">Sunday</option>
            <option value="1">Monday</option>
            <option value="2">Tuesday</option>
            <option value="3">Wednesday</option>
            <option value="4">Thursday</option>
            <option value="5">Friday</option>
            <option value="6">Saturday</option>
          </select>

          <label class="inline-check" for="reminder-sound">
            <input id="reminder-sound" name="soundEnabled" type="checkbox" checked />
            <span>Play alarm sound</span>
          </label>

          <label for="reminder-note">Reminder Note</label>
          <textarea
            id="reminder-note"
            name="note"
            maxlength="220"
            placeholder="Ex: Take medicine after lunch"
            required
          ></textarea>

          <div class="modal-actions">
            <button type="button" class="btn-ghost" id="reminder-cancel">Cancel</button>
            <button type="submit" class="btn-primary">Save Reminder</button>
          </div>
        </form>
      </section>
    </div>

    <script>
      window.APP_CONTEXT_PATH = "<%= request.getContextPath() %>";
    </script>
    <script src="auth.js"></script>
    <script src="sync.js"></script>
    <script src="reminder-alarm.js"></script>
    <script>
      requireLogin();
      RTRPSync.setupAutoSync();
      RTRPSync.initialLoad();

      const todayElement = document.getElementById("today-date");
      const calendarInput = document.getElementById("calendar-input");
      const calendarTrigger = document.getElementById("calendar-trigger");
      const uploadTrigger = document.getElementById("upload-trigger");
      const uploadModal = document.getElementById("upload-modal");
      const uploadClose = document.getElementById("upload-close");
      const uploadCancel = document.getElementById("upload-cancel");
      const uploadForm = document.getElementById("upload-form");
      const uploadImageInput = document.getElementById("upload-image");
      const uploadCategorySelect = document.getElementById("upload-category-select");
      const uploadCategoryOtherInput = document.getElementById("upload-category-other");
      const uploadPreview = document.getElementById("upload-preview");
      const uploadStorageKey = "rtrp-upload-items";
      const reminderTrigger = document.getElementById("reminder-trigger");
      const reminderModal = document.getElementById("reminder-modal");
      const reminderClose = document.getElementById("reminder-close");
      const reminderCancel = document.getElementById("reminder-cancel");
      const reminderForm = document.getElementById("reminder-form");
      const reminderDateTimeInput = document.getElementById("reminder-date-time");
      const reminderRepeatInput = document.getElementById("reminder-repeat");
      const reminderDateTimeLabel = document.getElementById("reminder-date-time-label");
      const reminderTimeLabel = document.getElementById("reminder-time-label");
      const reminderTimeInput = document.getElementById("reminder-time");
      const reminderWeekdayLabel = document.getElementById("reminder-weekday-label");
      const reminderWeekdayInput = document.getElementById("reminder-weekday");
      const reminderSoundInput = document.getElementById("reminder-sound");
      const reminderNoteInput = document.getElementById("reminder-note");

      function formatDate(dateValue) {
        return new Date(dateValue).toLocaleDateString("en-GB", {
          day: "2-digit",
          month: "short",
          year: "numeric",
        });
      }

      if (todayElement) {
        const today = new Date();
        const todayIso = today.toISOString().split("T")[0];
        todayElement.textContent = formatDate(todayIso);

        if (calendarInput) {
          calendarInput.value = todayIso;

          calendarInput.addEventListener("change", () => {
            if (calendarInput.value) {
              todayElement.textContent = formatDate(calendarInput.value);
            }
          });
        }
      }

      if (calendarTrigger && calendarInput) {
        calendarTrigger.addEventListener("click", () => {
          if (typeof calendarInput.showPicker === "function") {
            calendarInput.showPicker();
          } else {
            calendarInput.focus();
            calendarInput.click();
          }
        });
      }

      function openUploadModal() {
        uploadModal.classList.add("is-open");
        uploadModal.setAttribute("aria-hidden", "false");
        toggleOtherCategoryInput();
      }

      function closeUploadModal() {
        uploadModal.classList.remove("is-open");
        uploadModal.setAttribute("aria-hidden", "true");
        uploadForm.reset();
        uploadPreview.hidden = true;
        uploadPreview.removeAttribute("src");
        toggleOtherCategoryInput();
      }

      function toggleOtherCategoryInput() {
        const isOther = uploadCategorySelect.value === "other";
        uploadCategoryOtherInput.hidden = !isOther;
        uploadCategoryOtherInput.required = isOther;
        if (!isOther) {
          uploadCategoryOtherInput.value = "";
        }
      }

      function getSelectedCategory() {
        if (uploadCategorySelect.value === "other") {
          return uploadCategoryOtherInput.value.trim();
        }
        return uploadCategorySelect.value.trim();
      }

      function readImageAsDataUrl(file) {
        return new Promise((resolve, reject) => {
          const reader = new FileReader();
          reader.onload = () => resolve(reader.result);
          reader.onerror = () => reject(new Error("Unable to read selected image."));
          reader.readAsDataURL(file);
        });
      }

      if (uploadTrigger && uploadModal && uploadForm) {
        toggleOtherCategoryInput();
        uploadCategorySelect.addEventListener("change", toggleOtherCategoryInput);

        uploadTrigger.addEventListener("click", openUploadModal);
        uploadClose.addEventListener("click", closeUploadModal);
        uploadCancel.addEventListener("click", closeUploadModal);

        uploadModal.addEventListener("click", (event) => {
          if (event.target === uploadModal) {
            closeUploadModal();
          }
        });

        document.addEventListener("keydown", (event) => {
          if (event.key === "Escape" && uploadModal.classList.contains("is-open")) {
            closeUploadModal();
          }
        });

        uploadImageInput.addEventListener("change", async () => {
          const [file] = uploadImageInput.files;
          if (!file) {
            uploadPreview.hidden = true;
            uploadPreview.removeAttribute("src");
            return;
          }

          try {
            const imageData = await readImageAsDataUrl(file);
            if (typeof imageData === "string") {
              uploadPreview.src = imageData;
              uploadPreview.hidden = false;
            }
          } catch (error) {
            window.alert(error.message);
          }
        });

        uploadForm.addEventListener("submit", async (event) => {
          event.preventDefault();

          const [file] = uploadImageInput.files;
          const category = getSelectedCategory();

          if (!file || !category) {
            window.alert("Please choose an image and enter a category.");
            return;
          }

          try {
            const imageData = await readImageAsDataUrl(file);
            const storedItems = JSON.parse(localStorage.getItem(uploadStorageKey) || "[]");

            storedItems.push({
              category,
              image: imageData,
              createdAt: new Date().toISOString(),
            });

            localStorage.setItem(uploadStorageKey, JSON.stringify(storedItems));
            window.alert("Image uploaded and saved with category.");
            closeUploadModal();
          } catch (error) {
            window.alert(error.message || "Upload failed. Please try again.");
          }
        });
      }

      function openReminderModal() {
        reminderModal.classList.add("is-open");
        reminderModal.setAttribute("aria-hidden", "false");
      }

      function closeReminderModal() {
        reminderModal.classList.remove("is-open");
        reminderModal.setAttribute("aria-hidden", "true");
        reminderForm.reset();
        syncReminderScheduleInputs();
      }

      function syncReminderScheduleInputs() {
        const repeat = reminderRepeatInput.value;
        const isOneTime = repeat === "none";
        const needsWeekday = repeat === "weekly" || repeat === "biweekly";

        reminderDateTimeLabel.hidden = !isOneTime;
        reminderDateTimeInput.hidden = !isOneTime;
        reminderDateTimeInput.required = isOneTime;

        reminderTimeLabel.hidden = isOneTime;
        reminderTimeInput.hidden = isOneTime;
        reminderTimeInput.required = !isOneTime;

        reminderWeekdayLabel.hidden = !needsWeekday;
        reminderWeekdayInput.hidden = !needsWeekday;
        reminderWeekdayInput.required = needsWeekday;

        if (!needsWeekday) {
          reminderWeekdayInput.value = "1";
        }
      }

      if (reminderTrigger && reminderModal && reminderForm) {
        syncReminderScheduleInputs();
        reminderRepeatInput.addEventListener("change", syncReminderScheduleInputs);

        reminderTrigger.addEventListener("click", openReminderModal);
        reminderClose.addEventListener("click", closeReminderModal);
        reminderCancel.addEventListener("click", closeReminderModal);

        reminderModal.addEventListener("click", (event) => {
          if (event.target === reminderModal) {
            closeReminderModal();
          }
        });

        document.addEventListener("keydown", (event) => {
          if (event.key === "Escape" && reminderModal.classList.contains("is-open")) {
            closeReminderModal();
          }
        });

        reminderForm.addEventListener("submit", (event) => {
          event.preventDefault();

          const repeat = reminderRepeatInput.value;
          const reminderAt = reminderDateTimeInput.value;
          const timeOfDay = reminderTimeInput.value;
          const weekday = Number(reminderWeekdayInput.value);
          const soundEnabled = reminderSoundInput.checked;
          const note = reminderNoteInput.value.trim();

          const needsOneTimeDate = repeat === "none";
          const needsTime = repeat !== "none";
          const needsWeekday = repeat === "weekly" || repeat === "biweekly";

          if (!note) {
            window.alert("Please add a reminder note.");
            return;
          }

          if (needsOneTimeDate && !reminderAt) {
            window.alert("Please select date and time for one-time reminder.");
            return;
          }

          if (needsTime && !timeOfDay) {
            window.alert("Please select time for repeating reminder.");
            return;
          }

          if (needsWeekday && !Number.isInteger(weekday)) {
            window.alert("Please select a day of week.");
            return;
          }

          try {
            window.RTRPReminders.createReminder({
              reminderAt,
              repeat,
              note,
              soundEnabled,
              timeOfDay,
              weekday,
            });
            window.alert("Reminder saved and alarm is active.");
            closeReminderModal();
          } catch (error) {
            window.alert(error.message || "Unable to save reminder.");
          }
        });
      }
    </script>
  </body>
</html>
