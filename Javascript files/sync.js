(function () {
  const UPLOADS_KEY = "rtrp-upload-items";
  const JOURNALS_KEY = "rtrp-journal-entries";
  const REMINDERS_KEY = "rtrp-reminders";

  const endpointByKey = {
    [UPLOADS_KEY]: "api/data/uploads",
    [JOURNALS_KEY]: "api/data/journals",
    [REMINDERS_KEY]: "api/data/reminders",
  };

  let inSyncWrite = false;

  async function fetchPayload(endpoint) {
    const response = await fetch(endpoint, { credentials: "same-origin" });
    if (!response.ok) {
      throw new Error("Unable to load data");
    }
    const payload = await response.text();
    return payload || "[]";
  }

  async function savePayload(endpoint, payload) {
    await fetch(endpoint, {
      method: "POST",
      credentials: "same-origin",
      headers: {
        "Content-Type": "text/plain;charset=UTF-8",
      },
      body: payload,
    });
  }

  async function initialLoad() {
    const keys = Object.keys(endpointByKey);
    for (const key of keys) {
      try {
        const payload = await fetchPayload(endpointByKey[key]);
        inSyncWrite = true;
        localStorage.setItem(key, payload);
      } catch {
        // Keep existing local value if backend is temporarily unreachable.
      } finally {
        inSyncWrite = false;
      }
    }
  }

  function setupAutoSync() {
    const originalSetItem = localStorage.setItem.bind(localStorage);

    localStorage.setItem = function (key, value) {
      originalSetItem(key, value);
      if (inSyncWrite) {
        return;
      }

      const endpoint = endpointByKey[key];
      if (!endpoint) {
        return;
      }

      savePayload(endpoint, String(value)).catch(() => {
        // Ignore transient sync failures in UI path.
      });
    };
  }

  window.RTRPSync = {
    initialLoad,
    setupAutoSync,
  };
})();
