(function () {
  const STORAGE_KEY = "rtrp-reminders";
  const CHECK_INTERVAL_MS = 1000;
  const MAX_CATCH_UP_CYCLES = 120;
  const MS_IN_DAY = 24 * 60 * 60 * 1000;
  const SAME_MINUTE_GRACE_MS = 60 * 1000;

  let intervalId = null;
  let audioCtx = null;

  function createId() {
    if (window.crypto && typeof window.crypto.randomUUID === "function") {
      return window.crypto.randomUUID();
    }
    return `rem-${Date.now()}-${Math.floor(Math.random() * 1000000)}`;
  }

  function safeParse(raw) {
    try {
      const parsed = JSON.parse(raw || "[]");
      return Array.isArray(parsed) ? parsed : [];
    } catch {
      return [];
    }
  }

  function toIso(date) {
    return date.toISOString();
  }

  function parseDate(value) {
    const date = new Date(value);
    return Number.isNaN(date.getTime()) ? null : date;
  }

  function normalizeRepeat(value) {
    const allowed = ["none", "daily", "no-sundays", "weekly", "biweekly"];
    return allowed.includes(value) ? value : "none";
  }

  function normalizeWeekday(value, fallback) {
    const numeric = Number(value);
    if (Number.isInteger(numeric) && numeric >= 0 && numeric <= 6) {
      return numeric;
    }
    return fallback;
  }

  function parseTimeOfDay(value) {
    if (typeof value !== "string") {
      return null;
    }

    const match = value.match(/^(\d{2}):(\d{2})$/);
    if (!match) {
      return null;
    }

    const hours = Number(match[1]);
    const minutes = Number(match[2]);
    if (
      !Number.isInteger(hours) ||
      !Number.isInteger(minutes) ||
      hours < 0 ||
      hours > 23 ||
      minutes < 0 ||
      minutes > 59
    ) {
      return null;
    }

    return { hours, minutes };
  }

  function toTimeOfDay(date) {
    const hh = String(date.getHours()).padStart(2, "0");
    const mm = String(date.getMinutes()).padStart(2, "0");
    return `${hh}:${mm}`;
  }

  function startOfDay(date) {
    return new Date(date.getFullYear(), date.getMonth(), date.getDate());
  }

  function buildDateWithTime(baseDate, timeOfDay) {
    const parsed = parseTimeOfDay(timeOfDay);
    if (!parsed) {
      return null;
    }

    return new Date(
      baseDate.getFullYear(),
      baseDate.getMonth(),
      baseDate.getDate(),
      parsed.hours,
      parsed.minutes,
      0,
      0
    );
  }

  function getDailyCandidate(afterDate, timeOfDay) {
    let candidate = buildDateWithTime(afterDate, timeOfDay);
    if (!candidate) {
      return null;
    }

    if (candidate <= afterDate) {
      const lag = afterDate.getTime() - candidate.getTime();
      if (lag >= SAME_MINUTE_GRACE_MS) {
        candidate = new Date(candidate.getTime() + MS_IN_DAY);
      }
    }

    return candidate;
  }

  function getWeeklyCandidate(afterDate, timeOfDay, weekday) {
    const base = buildDateWithTime(afterDate, timeOfDay);
    if (!base) {
      return null;
    }

    const currentWeekday = base.getDay();
    let daysAhead = weekday - currentWeekday;
    if (daysAhead < 0) {
      daysAhead += 7;
    }

    let candidate = new Date(base.getTime() + daysAhead * MS_IN_DAY);
    if (candidate <= afterDate) {
      const lag = afterDate.getTime() - candidate.getTime();
      if (lag >= SAME_MINUTE_GRACE_MS) {
        candidate = new Date(candidate.getTime() + 7 * MS_IN_DAY);
      }
    }

    return candidate;
  }

  function weeksBetween(anchorDate, candidateDate) {
    const anchor = startOfDay(anchorDate);
    const candidate = startOfDay(candidateDate);
    return Math.floor((candidate.getTime() - anchor.getTime()) / (7 * MS_IN_DAY));
  }

  function getNextTrigger(reminder, afterDate) {
    if (reminder.repeat === "none") {
      return parseDate(reminder.reminderAt);
    }

    if (reminder.repeat === "daily") {
      return getDailyCandidate(afterDate, reminder.timeOfDay);
    }

    if (reminder.repeat === "no-sundays") {
      let candidate = getDailyCandidate(afterDate, reminder.timeOfDay);
      if (!candidate) {
        return null;
      }

      while (candidate.getDay() === 0) {
        candidate = new Date(candidate.getTime() + MS_IN_DAY);
      }

      return candidate;
    }

    if (reminder.repeat === "weekly") {
      return getWeeklyCandidate(afterDate, reminder.timeOfDay, reminder.weekday);
    }

    if (reminder.repeat === "biweekly") {
      const anchorAt = parseDate(reminder.anchorAt) || afterDate;
      let candidate = getWeeklyCandidate(afterDate, reminder.timeOfDay, reminder.weekday);
      if (!candidate) {
        return null;
      }

      let loops = 0;
      while (weeksBetween(anchorAt, candidate) % 2 !== 0 && loops < MAX_CATCH_UP_CYCLES) {
        candidate = new Date(candidate.getTime() + 7 * MS_IN_DAY);
        loops += 1;
      }

      return candidate;
    }

    return null;
  }

  function readReminders() {
    const items = safeParse(localStorage.getItem(STORAGE_KEY));
    const now = new Date();

    return items
      .map((item) => {
        const repeat = normalizeRepeat(item.repeat);
        const reminderAt = typeof item.reminderAt === "string" ? item.reminderAt : "";
        const reminderDate = parseDate(reminderAt);
        const derivedTimeOfDay = reminderDate ? toTimeOfDay(reminderDate) : "";
        const timeOfDay = typeof item.timeOfDay === "string" ? item.timeOfDay : derivedTimeOfDay;
        const fallbackWeekday = reminderDate ? reminderDate.getDay() : now.getDay();
        const weekday = normalizeWeekday(item.weekday, fallbackWeekday);
        const createdAt = typeof item.createdAt === "string" ? item.createdAt : toIso(now);
        const anchorAt = typeof item.anchorAt === "string" ? item.anchorAt : createdAt;

        const normalized = {
          id: typeof item.id === "string" ? item.id : createId(),
          reminderAt,
          timeOfDay,
          weekday,
          anchorAt,
          note: typeof item.note === "string" ? item.note : "",
          repeat,
          soundEnabled: item.soundEnabled !== false,
          createdAt,
          nextTriggerAt: typeof item.nextTriggerAt === "string" ? item.nextTriggerAt : null,
          lastTriggeredAt: typeof item.lastTriggeredAt === "string" ? item.lastTriggeredAt : null,
        };

        if (!normalized.nextTriggerAt) {
          const next = getNextTrigger(normalized, now);
          normalized.nextTriggerAt = next ? toIso(next) : null;
        }

        return normalized;
      })
      .filter((item) => {
        if (item.repeat === "none") {
          return Boolean(item.reminderAt);
        }
        return Boolean(item.timeOfDay);
      });
  }

  function saveReminders(reminders) {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(reminders));
  }

  function unlockAudio() {
    if (audioCtx) {
      return;
    }

    try {
      const Ctx = window.AudioContext || window.webkitAudioContext;
      if (!Ctx) {
        return;
      }
      audioCtx = new Ctx();
      if (audioCtx.state === "suspended") {
        audioCtx.resume();
      }
    } catch {
      audioCtx = null;
    }
  }

  function beep(durationMs, frequency, delayMs) {
    if (!audioCtx) {
      return;
    }

    const startTime = audioCtx.currentTime + delayMs / 1000;
    const endTime = startTime + durationMs / 1000;

    const oscillator = audioCtx.createOscillator();
    const gainNode = audioCtx.createGain();

    oscillator.type = "sine";
    oscillator.frequency.setValueAtTime(frequency, startTime);

    gainNode.gain.setValueAtTime(0.0001, startTime);
    gainNode.gain.exponentialRampToValueAtTime(0.18, startTime + 0.02);
    gainNode.gain.exponentialRampToValueAtTime(0.0001, endTime);

    oscillator.connect(gainNode);
    gainNode.connect(audioCtx.destination);
    oscillator.start(startTime);
    oscillator.stop(endTime + 0.02);
  }

  function playAlarmSound() {
    unlockAudio();
    if (!audioCtx) {
      return;
    }

    if (audioCtx.state === "suspended") {
      audioCtx.resume().catch(() => {
        // Ignore resume failures.
      });
    }

    const patternDurationMs = 800;
    const totalDurationMs = 10000;
    let offset = 0;

    while (offset < totalDurationMs) {
      beep(240, 880, offset);
      beep(240, 660, offset + 260);
      beep(280, 990, offset + 520);
      offset += patternDurationMs;
    }
  }

  function formatRepeatLabel(repeat) {
    if (repeat === "daily") {
      return "Daily";
    }
    if (repeat === "no-sundays") {
      return "No Sundays";
    }
    if (repeat === "weekly") {
      return "Weekly";
    }
    if (repeat === "biweekly") {
      return "Biweekly";
    }
    return "One-time";
  }

  function createReminder({ reminderAt, note, repeat, soundEnabled, timeOfDay, weekday }) {
    const normalizedRepeat = normalizeRepeat(repeat);
    const now = new Date();

    const normalized = {
      id: createId(),
      reminderAt: typeof reminderAt === "string" ? reminderAt : "",
      timeOfDay: typeof timeOfDay === "string" ? timeOfDay : "",
      weekday: normalizeWeekday(weekday, now.getDay()),
      anchorAt: toIso(now),
      note: typeof note === "string" ? note.trim() : "",
      repeat: normalizedRepeat,
      soundEnabled: soundEnabled !== false,
      createdAt: toIso(now),
      nextTriggerAt: null,
      lastTriggeredAt: null,
    };

    if (!normalized.note) {
      throw new Error("Reminder note is required.");
    }

    if (normalized.repeat === "none") {
      if (!parseDate(normalized.reminderAt)) {
        throw new Error("Invalid reminder date/time.");
      }
    } else if (!parseTimeOfDay(normalized.timeOfDay)) {
      throw new Error("Invalid reminder time.");
    }

    const next = getNextTrigger(normalized, new Date(now.getTime() - 1000));
    if (!next) {
      throw new Error("Invalid reminder schedule.");
    }

    normalized.nextTriggerAt = toIso(next);

    const reminders = readReminders();
    reminders.push(normalized);
    saveReminders(reminders);
    checkAlarms();

    return normalized;
  }

  function deleteReminder(id) {
    const reminders = readReminders();
    const next = reminders.filter((item) => item.id !== id);
    saveReminders(next);
  }

  function triggerReminder(reminder) {
    if (reminder.soundEnabled) {
      playAlarmSound();
    }

    if (typeof window.Notification === "function" && Notification.permission === "granted") {
      try {
        new Notification("RTRP Reminder", {
          body: reminder.note,
        });
      } catch {
        // Ignore notification failures.
      }
    }

    window.alert(`Reminder: ${reminder.note}`);
  }

  function updateAfterTrigger(reminder) {
    const nextState = { ...reminder, lastTriggeredAt: reminder.nextTriggerAt };

    if (reminder.repeat === "none") {
      nextState.nextTriggerAt = null;
      return nextState;
    }

    const currentTriggerDate = parseDate(reminder.nextTriggerAt);
    if (!currentTriggerDate) {
      nextState.nextTriggerAt = null;
      return nextState;
    }

    const nextDate = getNextTrigger(nextState, currentTriggerDate);
    nextState.nextTriggerAt = nextDate ? toIso(nextDate) : null;
    return nextState;
  }

  function checkAlarms() {
    const reminders = readReminders();
    const now = new Date();
    let changed = false;

    const nextReminders = reminders
      .map((reminder) => {
        if (!reminder.nextTriggerAt) {
          return reminder;
        }

        const dueDate = parseDate(reminder.nextTriggerAt);
        if (!dueDate) {
          changed = true;
          return { ...reminder, nextTriggerAt: null };
        }

        if (dueDate > now) {
          return reminder;
        }

        if (reminder.lastTriggeredAt === reminder.nextTriggerAt) {
          return reminder;
        }

        triggerReminder(reminder);
        changed = true;
        return updateAfterTrigger(reminder);
      })
      .filter((reminder) => reminder.nextTriggerAt || reminder.repeat !== "none");

    if (changed) {
      saveReminders(nextReminders);
    }
  }

  function startAlarmEngine() {
    if (intervalId !== null) {
      return;
    }

    if (typeof window.Notification === "function" && Notification.permission === "default") {
      Notification.requestPermission().catch(() => {
        // Ignore permission errors.
      });
    }

    const unlock = function () {
      unlockAudio();
    };

    document.addEventListener("click", unlock, { once: true });
    document.addEventListener("keydown", unlock, { once: true });

    checkAlarms();
    intervalId = window.setInterval(checkAlarms, CHECK_INTERVAL_MS);
  }

  window.RTRPReminders = {
    STORAGE_KEY,
    createReminder,
    readReminders,
    saveReminders,
    deleteReminder,
    startAlarmEngine,
    formatRepeatLabel,
  };

  startAlarmEngine();
})();
