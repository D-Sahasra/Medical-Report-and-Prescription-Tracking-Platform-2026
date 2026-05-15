<%@ page isELIgnored="true" %>
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>RTRP Login</title>
    <link rel="stylesheet" href="styles.css" />
    <style>
      :root {
        --bg-main: #e8f4ff;
        --bg-panel: #f8fbff;
        --bg-sidebar: #d2e8ff;
        --blue-100: #d8ebff;
        --blue-200: #b8d9fb;
        --blue-400: #64a6dd;
        --blue-600: #2b76b8;
        --blue-700: #1f5f95;
        --text-main: #1c3752;
        --text-soft: #3f5f7d;
        --white: #ffffff;
        --ring-shadow: 0 12px 24px rgba(43, 118, 184, 0.2);
      }

      .login-shell {
        display: flex;
        flex-direction: column;
        height: 100vh;
        background: var(--bg-main);
      }

      .login-header {
        background: var(--blue-200);
        padding: 1.5rem 2rem;
        box-shadow: 0 2px 8px rgba(43, 118, 184, 0.1);
        display: flex;
        align-items: center;
        justify-content: flex-start;
        border-bottom: 1px solid rgba(43, 118, 184, 0.14);
      }

      .login-header .logo-chip {
        font-size: 1.8rem;
        font-weight: 600;
        color: var(--blue-600);
      }

      .login-container {
        flex: 1;
        display: flex;
        align-items: center;
        justify-content: center;
        padding: 2rem;
      }

      .login-card {
        background: #f0f6ff;
        border-radius: 12px;
        padding: 2.5rem;
        box-shadow: 0 10px 40px rgba(43, 118, 184, 0.1);
        width: 100%;
        max-width: 420px;
      }

      .login-card h2 {
        margin: 0 0 1.5rem 0;
        color: var(--text-main);
        font-size: 1.8rem;
        text-align: center;
      }

      .login-form {
        display: flex;
        flex-direction: column;
        gap: 1.2rem;
      }

      .form-group {
        display: flex;
        flex-direction: column;
        gap: 0.5rem;
      }

      .form-group label {
        font-weight: 600;
        color: var(--text-main);
        font-size: 0.95rem;
      }

      .form-group input,
      .form-group select {
        padding: 0.75rem;
        border: 2px solid var(--blue-200);
        border-radius: 6px;
        font-size: 1rem;
        transition: border-color 0.3s;
      }

      .form-group input:focus,
      .form-group select:focus {
        outline: none;
        border-color: var(--blue-600);
        box-shadow: 0 0 0 3px rgba(43, 118, 184, 0.1);
      }

      .form-group input::placeholder {
        color: #999;
      }

      .form-group select:disabled {
        background-color: #e8f4ff;
        cursor: not-allowed;
        opacity: 0.9;
      }

      .login-btn {
        background: var(--blue-600);
        color: white;
        padding: 0.75rem;
        border: none;
        border-radius: 6px;
        font-size: 1rem;
        font-weight: 600;
        cursor: pointer;
        transition: background-color 0.2s;
        margin-top: 0.5rem;
      }

      .login-btn:active {
        background: var(--blue-700);
      }

      .form-divider {
        text-align: center;
        color: #999;
        font-size: 0.9rem;
        margin: 0.5rem 0;
      }

      .register-link {
        text-align: center;
        font-size: 0.95rem;
      }

      .register-link a {
        color: var(--blue-600);
        text-decoration: none;
        font-weight: 600;
        transition: color 0.3s;
      }

      .register-link a:hover {
        color: var(--blue-700);
      }

      .error-message {
        background-color: #fee;
        color: #c33;
        padding: 0.75rem;
        border-radius: 6px;
        border-left: 4px solid #c33;
        font-size: 0.9rem;
        display: none;
        margin-bottom: 1rem;
      }

      .error-message.show {
        display: block;
      }

      .success-message {
        background-color: #efe;
        color: #3c3;
        padding: 0.75rem;
        border-radius: 6px;
        border-left: 4px solid #3c3;
        font-size: 0.9rem;
        display: none;
        margin-bottom: 1rem;
      }

      .success-message.show {
        display: block;
      }
    </style>
  </head>
  <body>
    <div class="login-shell">
      <header class="login-header">
        <span class="logo-chip"><i>Healger</i></span>
      </header>

      <div class="login-container">
        <div class="login-card">
          <h2>Login</h2>

          <div class="error-message" id="error-msg"></div>
          <div class="success-message" id="success-msg"></div>

          <form class="login-form" id="login-form">
            <div class="form-group">
              <label for="login-username">Username or Email</label>
              <input
                id="login-username"
                type="text"
                placeholder="Enter your username or email"
                required
              />
            </div>

            <div class="form-group">
              <label for="login-password">Password</label>
              <input
                id="login-password"
                type="password"
                placeholder="Enter your password"
                required
              />
            </div>

            <div class="form-group">
              <label for="login-security-question">Security Question</label>
              <select id="login-security-question" required>
                <option value="">Select a security question...</option>
                <option value="What is your mother's maiden name?">What is your mother's maiden name?</option>
                <option value="What was the name of your first pet?">What was the name of your first pet?</option>
                <option value="In what city were you born?">In what city were you born?</option>
                <option value="What is your favorite book?">What is your favorite book?</option>
                <option value="What is the name of your best friend?">What is the name of your best friend?</option>
                <option value="What was your first car?">What was your first car?</option>
                <option value="What is your favorite movie?">What is your favorite movie?</option>
                <option value="What school did you attend for high school?">What school did you attend for high school?</option>
              </select>
            </div>

            <div class="form-group">
              <label for="login-security-answer">Answer</label>
              <input
                id="login-security-answer"
                type="text"
                placeholder="Answer to your security question"
                required
              />
            </div>

            <button type="submit" class="login-btn">Login</button>
          </form>

          <div class="form-divider">Don't have an account?</div>

          <div class="register-link">
            <a href="register.jsp">Create a new account</a>
          </div>
        </div>
      </div>
    </div>

    <script>
      window.APP_CONTEXT_PATH = "<%= request.getContextPath() %>";
    </script>
    <script src="auth.js"></script>
    <script>
      document.getElementById("login-form").addEventListener("submit", async function (e) {
        e.preventDefault();

        const username = document.getElementById("login-username").value.trim();
        const password = document.getElementById("login-password").value;
        const securityQuestion = document.getElementById("login-security-question").value.trim();
        const securityAnswer = document.getElementById("login-security-answer").value.trim();

        const errorMsg = document.getElementById("error-msg");
        const successMsg = document.getElementById("success-msg");

        errorMsg.classList.remove("show");
        successMsg.classList.remove("show");

        if (!username || !password || !securityQuestion || !securityAnswer) {
          errorMsg.textContent = "Please fill in all fields";
          errorMsg.classList.add("show");
          return;
        }

        const result = await loginUser(username, password, securityAnswer);
        if (result.success) {
          successMsg.textContent = "Login successful! Redirecting...";
          successMsg.classList.add("show");
          setTimeout(() => {
            window.location.href = "dashboard.jsp";
          }, 800);
          return;
        }

        errorMsg.textContent = result.message || "Login failed";
        errorMsg.classList.add("show");
      });

      (async function () {
        if (await isUserLoggedIn()) {
          window.location.href = "dashboard.jsp";
        }
      })();
    </script>
  </body>
</html>
