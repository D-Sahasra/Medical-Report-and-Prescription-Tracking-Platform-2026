function toApiUrl(url) {
  if (/^https?:\/\//i.test(url)) {
    return url;
  }

  const normalizedPath = url.startsWith("/") ? url : `/${url}`;
  const explicitBase =
    typeof window.APP_CONTEXT_PATH === "string"
      ? window.APP_CONTEXT_PATH.replace(/\/$/, "")
      : "";

  if (explicitBase) {
    return `${explicitBase}${normalizedPath}`;
  }

  const pathname = window.location.pathname || "";
  const webContentIndex = pathname.indexOf("/WebContent/");
  if (webContentIndex >= 0) {
    const inferredBase = pathname.substring(0, webContentIndex);
    return `${inferredBase}${normalizedPath}`;
  }

  return normalizedPath;
}

async function apiRequest(url, options) {
  const customHeaders = (options && options.headers) || {};
  const hasContentType = Object.keys(customHeaders).some(
    (k) => k.toLowerCase() === "content-type"
  );
  const requestUrl = toApiUrl(url);

  const response = await fetch(requestUrl, {
    credentials: "same-origin",
    ...options,
    headers: {
      ...(hasContentType ? {} : { "Content-Type": "application/json" }),
      ...customHeaders,
    },
  });

  const raw = await response.text();
  let data;
  try {
    data = raw ? JSON.parse(raw) : {};
  } catch {
    data = {
      success: false,
      message: `Server returned non-JSON (${response.status}) at ${requestUrl}`,
      details: raw ? raw.slice(0, 180) : "",
    };
  }

  if (!response.ok) {
    return {
      success: false,
      message: data.message || `Request failed (${response.status}) at ${requestUrl}`,
      details: data.details || "",
    };
  }

  return data;
}

async function registerUser(userData) {
  const body = new URLSearchParams(userData).toString();
  return apiRequest("api/auth/register", {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8",
    },
    body,
  });
}

async function loginUser(username, password, securityAnswer) {
  const body = new URLSearchParams({ username, password, securityAnswer }).toString();
  return apiRequest("api/auth/login", {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded;charset=UTF-8",
    },
    body,
  });
}

async function logoutUser() {
  await apiRequest("api/auth/logout", { method: "POST" });
  window.location.href = "login.jsp";
}

async function getCurrentUser() {
  const result = await apiRequest("api/auth/me", { method: "GET" });
  return result.success ? result : null;
}

async function isUserLoggedIn() {
  const user = await getCurrentUser();
  return Boolean(user && user.userId);
}

async function requireLogin() {
  const loggedIn = await isUserLoggedIn();
  if (!loggedIn) {
    window.location.href = "login.jsp";
  }
}

document.addEventListener("DOMContentLoaded", async function () {
  const logoutBtn = document.querySelector(".logout-btn");
  if (logoutBtn) {
    logoutBtn.addEventListener("click", async function () {
      const confirmed = window.confirm("Are you sure you want to logout?");
      if (confirmed) {
        await logoutUser();
      }
    });
  }

  const profileBox = document.querySelector(".profile-box");
  if (profileBox) {
    const currentUser = await getCurrentUser();
    if (currentUser) {
      const avatar = profileBox.querySelector(".avatar");
      if (avatar && currentUser.name) {
        avatar.textContent = currentUser.name.charAt(0).toUpperCase();
      }
      const profileSpan = profileBox.querySelector("span:not(.avatar)");
      if (profileSpan && currentUser.name) {
        profileSpan.textContent = currentUser.name;
      }
    }
  }
});
