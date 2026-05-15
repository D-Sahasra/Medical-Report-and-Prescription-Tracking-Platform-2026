// Profile management functions

async function loadProfile() {
  const loadingEl = document.getElementById('profile-loading');
  const contentEl = document.getElementById('profile-content');
  const errorEl = document.getElementById('profile-error');

  try {
    const response = await fetch(toApiUrl('api/profile/get'), {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8'
      }
    });

    const text = await response.text();
    let data;
    try {
      data = JSON.parse(text);
    } catch (e) {
      throw new Error(`Server returned non-JSON (${response.status}): ${text.substring(0, 100)}`);
    }

    if (!response.ok || !data.success) {
      throw new Error(data.error || `Server error: ${response.status}`);
    }

    // Populate profile data
    document.getElementById('profile-username').textContent = data.username || '-';
    document.getElementById('profile-email').textContent = data.email || '-';
    document.getElementById('profile-fullname').textContent = data.fullName || '-';
    document.getElementById('profile-dob').textContent = formatDate(data.dob) || '-';
    document.getElementById('profile-mobile').textContent = data.mobile || '-';
    document.getElementById('profile-security-question').textContent = data.securityQuestion || '-';

    loadingEl.hidden = true;
    contentEl.hidden = false;

    // Setup event listeners
    setupProfileEventListeners();
  } catch (error) {
    console.error('Error loading profile:', error);
    loadingEl.hidden = true;
    errorEl.hidden = false;
    errorEl.textContent = `Error: ${error.message}`;
  }
}

function setupProfileEventListeners() {
  const logoutBtnHeader = document.getElementById('logout-btn');
  const logoutBtnProfile = document.getElementById('logout-btn-profile');
  const deleteAccountBtn = document.getElementById('delete-account-btn');

  if (logoutBtnHeader) logoutBtnHeader.addEventListener('click', handleLogout);
  if (logoutBtnProfile) logoutBtnProfile.addEventListener('click', handleLogout);
  if (deleteAccountBtn) deleteAccountBtn.addEventListener('click', handleDeleteAccount);
}

async function handleLogout() {
  try {
    const response = await fetch(toApiUrl('api/auth/logout'), {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8'
      }
    });

    if (response.ok) {
      // Redirect to login page
      window.location.href = 'login.jsp';
    } else {
      alert('Error logging out. Please try again.');
    }
  } catch (error) {
    console.error('Error logging out:', error);
    alert('Error logging out: ' + error.message);
  }
}

async function handleDeleteAccount() {
  const confirmed = window.confirm(
    'Are you sure you want to delete your account? This action cannot be undone. All your data (journals, reminders, budget records) will be permanently deleted.'
  );

  if (!confirmed) {
    return;
  }

  const doubleConfirmed = window.prompt(
    'Please type "DELETE" to confirm account deletion:'
  );

  if (doubleConfirmed !== 'DELETE') {
    alert('Account deletion cancelled.');
    return;
  }

  try {
    const response = await fetch(toApiUrl('api/profile/delete'), {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8'
      }
    });

    const text = await response.text();
    let data;
    try {
      data = JSON.parse(text);
    } catch (e) {
      throw new Error(`Server returned non-JSON (${response.status}): ${text.substring(0, 100)}`);
    }

    if (!response.ok || !data.success) {
      throw new Error(data.error || `Server error: ${response.status}`);
    }

    alert('Your account has been permanently deleted.');
    window.location.href = 'login.jsp';
  } catch (error) {
    console.error('Error deleting account:', error);
    alert('Error deleting account: ' + error.message);
  }
}

function formatDate(dateString) {
  if (!dateString) return '';
  try {
    const date = new Date(dateString + 'T00:00:00');
    return date.toLocaleDateString('en-GB', {
      day: '2-digit',
      month: 'long',
      year: 'numeric'
    });
  } catch {
    return dateString;
  }
}
