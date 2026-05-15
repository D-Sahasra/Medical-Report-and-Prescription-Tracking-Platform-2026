<%@ page isELIgnored="true" %>
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>RTRP Register</title>
    <link rel="stylesheet" href="styles.css" />
    <style>
      .register-shell {
        display: flex;
        flex-direction: column;
        min-height: 100vh;
        background: #e8f4ff;
      }

      .register-header {
        background: rgba(255, 255, 255, 0.7);
        padding: 1.5rem 2rem;
        box-shadow: 0 2px 8px rgba(43, 118, 184, 0.1);
        display: flex;
        align-items: center;
        justify-content: flex-start;
        border-bottom: 1px solid rgba(43, 118, 184, 0.14);
      }

      .register-header .logo-chip {
        font-size: 1.8rem;
        font-weight: 600;
        color: #2b76b8;
      }

      .register-container {
        flex: 1;
        display: flex;
        align-items: center;
        justify-content: center;
        padding: 2rem;
      }

      .register-card {
        background: white;
        border-radius: 6px;
        padding: 2.5rem;
        box-shadow: 0 24px 50px rgba(16, 37, 62, 0.12);
        width: 100%;
        max-width: 480px;
        max-height: 90vh;
        overflow-y: auto;
        border: 1px solid rgba(11, 111, 150, 0.08);
      }

      .register-card h2 {
        margin: 0 0 1.5rem 0;
        color: #1c3752;
        font-size: 1.8rem;
        text-align: center;
      }

      .register-form {
        display: flex;
        flex-direction: column;
        gap: 1rem;
      }

      .form-group {
        display: flex;
        flex-direction: column;
        gap: 0.5rem;
      }

      .form-group label {
        font-weight: 600;
        color: #1c3752;
        font-size: 0.95rem;
      }

      .form-group input,
      .form-group select {
        padding: 0.75rem;
        border: 2px solid #b8d9fb;
        border-radius: 6px;
        font-size: 1rem;
        transition: border-color 0.3s;
      }

      .form-group input:focus,
      .form-group select:focus {
        outline: none;
        border-color: #2b76b8;
        box-shadow: 0 0 0 3px rgba(43, 118, 184, 0.1);
      }

      .form-group input::placeholder {
        color: #999;
      }

      .form-row {
        display: grid;
        grid-template-columns: 1fr 1fr;
        gap: 1rem;
      }

      .register-btn {
        background: #2b76b8;
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

      .register-btn:active {
        filter: brightness(1.02);
      }

      .register-btn:active {
        transform: translateY(0);
      }

      .form-divider {
        text-align: center;
        color: #999;
        font-size: 0.9rem;
        margin: 0.5rem 0;
      }

      .login-link {
        text-align: center;
        font-size: 0.95rem;
      }

      .login-link a {
        color: #2b76b8;
        text-decoration: none;
        font-weight: 600;
        transition: color 0.3s;
      }

      .login-link a:hover {
        color: #1f5f95;
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

      .password-warning {
        font-size: 0.85rem;
        color: #666;
        margin-top: 0.25rem;
      }
    </style>
  </head>
  <body>
    <div class="register-shell">
      <header class="register-header">
        <span class="logo-chip"><i>Healger</i></span>
      </header>

      <div class="register-container">
        <div class="register-card">
          <h2>Create Account</h2>

          <div class="error-message" id="error-msg"></div>
          <div class="success-message" id="success-msg"></div>

          <form class="register-form" id="register-form">
            <div class="form-group">
              <label for="register-name">Full Name</label>
              <input
                id="register-name"
                type="text"
                placeholder="Enter your full name"
                required
              />
            </div>

            <div class="form-group">
              <label for="register-email">Email</label>
              <input
                id="register-email"
                type="email"
                placeholder="Enter your email"
                required
              />
            </div>

            <div class="form-group">
              <label for="register-mobile">Mobile Number</label>
              <input
                id="register-mobile"
                type="tel"
                placeholder="Enter your mobile number"
                required
              />
            </div>

            <div class="form-row">
              <div class="form-group">
                <label for="register-dob">Date of Birth</label>
                <input
                  id="register-dob"
                  type="date"
                  required
                />
              </div>
              <div class="form-group">
                <label for="register-password">Password</label>
                <input
                  id="register-password"
                  type="password"
                  placeholder="Enter password"
                  required
                />
                <p class="password-warning">Min 6 characters</p>
              </div>
            </div>

            <div class="form-group">
              <label for="register-security-question">Security Question</label>
              <select id="register-security-question" required>
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
              <label for="register-security-answer">Answer</label>
              <input
                id="register-security-answer"
                type="text"
                placeholder="Answer to your security question"
                required
              />
            </div>

            <button type="submit" class="register-btn">Create Account</button>
          </form>

          <div class="form-divider">Already have an account?</div>

          <div class="login-link">
            <a href="login.jsp">Go to login</a>
          </div>
        </div>
      </div>
    </div>

    <script>
      window.APP_CONTEXT_PATH = "<%= request.getContextPath() %>";
    </script>
    <script src="auth.js"></script>
    <script>
      document.getElementById("register-form").addEventListener("submit", async function (e) {
        e.preventDefault();

        const name = document.getElementById("register-name").value.trim();
        const email = document.getElementById("register-email").value.trim();
        const mobile = document.getElementById("register-mobile").value.trim();
        const dob = document.getElementById("register-dob").value;
        const password = document.getElementById("register-password").value;
        const securityQuestion = document.getElementById("register-security-question").value;
        const securityAnswer = document.getElementById("register-security-answer").value.trim();

        const errorMsg = document.getElementById("error-msg");
        const successMsg = document.getElementById("success-msg");

        errorMsg.classList.remove("show");
        successMsg.classList.remove("show");

        if (!name || !email || !mobile || !dob || !password || !securityQuestion || !securityAnswer) {
          errorMsg.textContent = "Please fill in all fields";
          errorMsg.classList.add("show");
          return;
        }

        if (password.length < 6) {
          errorMsg.textContent = "Password must be at least 6 characters";
          errorMsg.classList.add("show");
          return;
        }

        const result = await registerUser({
          name,
          email,
          mobile,
          dob,
          password,
          securityQuestion,
          securityAnswer,
        });

        if (result.success) {
          successMsg.textContent = "Registration successful! Redirecting to login...";
          successMsg.classList.add("show");
          setTimeout(() => {
            window.location.href = "login.jsp";
          }, 1000);
          return;
        }

        errorMsg.textContent = result.message || "Registration failed";
        errorMsg.classList.add("show");
      });

      (async function () {
        if (await isUserLoggedIn()) {
          window.location.href = "login.jsp";
        }
      })();
    </script>
  </body>
</html>
