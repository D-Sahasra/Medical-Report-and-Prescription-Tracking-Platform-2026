<%@ page isELIgnored="true" %>
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Healger - Keep Your Records Organized</title>
    <link rel="stylesheet" href="styles.css" />
    <style>
      * {
        margin: 0;
        padding: 0;
        box-sizing: border-box;
      }

      body {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', 'Roboto', 'Oxygen', 'Ubuntu', 'Cantarell', sans-serif;
        background: #f5f9fc;
        color: #1c3752;
        line-height: 1.6;
      }

      /* Header/Navigation */
      .landing-header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 1.2rem 3rem;
        background: #d2e8ff;
        border-bottom: 1px solid rgba(43, 118, 184, 0.14);
        box-shadow: 0 2px 8px rgba(43, 118, 184, 0.1);
      }

      .header-brand {
        display: flex;
        align-items: center;
        gap: 10px;
        text-decoration: none;
        color: #1c3752;
      }

      .header-brand .logo-chip {
        font-size: 1.7rem;
        font-weight: 700;
        color: #2b76b8;
        letter-spacing: -0.5px;
      }

      .header-signin {
        padding: 0.65rem 1.4rem;
        background: #2b76b8;
        color: white;
        border: none;
        border-radius: 6px;
        font-weight: 600;
        font-size: 0.95rem;
        text-decoration: none;
        cursor: pointer;
        transition: all 0.3s ease;
      }

      .header-signin:hover {
        background: #1f5f95;
        transform: translateY(-2px);
        box-shadow: 0 4px 12px rgba(43, 118, 184, 0.25);
      }

      /* Hero Section */
      .hero-section {
        display: grid;
        grid-template-columns: 1.35fr 0.9fr;
        gap: 2.5rem;
        align-items: flex-start;
        padding: 4rem 2.5rem;
        max-width: 1400px;
        margin: 0 auto;
      }

      .hero-left {
        padding-right: 2rem;
      }

      .hero-title {
        font-size: 3.9rem;
        font-weight: 700;
        color: #1c3752;
        line-height: 1.1;
        margin-bottom: 1.2rem;
        letter-spacing: -0.75px;
      }

      .hero-subtitle {
        font-size: 0.98rem;
        color: #4a6fa5;
        margin-bottom: 2rem;
        line-height: 1.65;
      }

      .hero-login-btn {
        display: inline-block;
        padding: 1rem 2.5rem;
        background: #2b76b8;
        color: white;
        border: none;
        border-radius: 6px;
        font-size: 1rem;
        font-weight: 700;
        text-decoration: none;
        cursor: pointer;
        transition: all 0.3s ease;
        margin-bottom: 3rem;
        box-shadow: 0 4px 15px rgba(43, 118, 184, 0.2);
      }

      .hero-login-btn:hover {
        background: #1f5f95;
        transform: translateY(-2px);
        box-shadow: 0 6px 20px rgba(43, 118, 184, 0.3);
      }

      /* Why Use It Section */
      .why-use-container {
        margin-top: 2rem;
        width: 100%;
      }

      .why-use-section {
        background: #f5f9fc;
        padding: 0 2.5rem 4rem;
      }

      .why-use-wrap {
        max-width: 1400px;
        margin: 0 auto;
      }

      .why-use-title {
        font-size: 0.9rem;
        color: #2b76b8;
        font-weight: 700;
        text-transform: uppercase;
        letter-spacing: 1.5px;
        margin-bottom: 1.8rem;
        display: block;
      }

      .why-use-cards {
        display: grid;
        grid-template-columns: repeat(3, minmax(0, 1fr));
        gap: 1rem;
        width: 100%;
      }

      .why-card {
        min-height: 112px;
        padding: 1rem 1.2rem;
        background: white;
        border-radius: 8px;
        border-left: 3px solid #2b76b8;
        box-shadow: 0 2px 8px rgba(43, 118, 184, 0.08);
        transition: all 0.3s ease;
      }

      .why-card:hover {
        box-shadow: 0 4px 16px rgba(43, 118, 184, 0.12);
        transform: translateX(4px);
      }

      .why-card h4 {
        font-size: 1rem;
        color: #2b76b8;
        margin-bottom: 0.6rem;
        font-weight: 600;
      }

      .why-card p {
        font-size: 0.95rem;
        color: #4a6fa5;
        line-height: 1.6;
      }

      .why-use-section .why-use-cards {
        grid-template-columns: repeat(3, minmax(0, 1fr));
      }

      /* Dashboard Preview */
      .hero-right {
        position: relative;
      }

      .dashboard-preview {
        background: linear-gradient(135deg, #1f5f95 0%, #2b76b8 100%);
        border-radius: 12px;
        padding: 1.25rem;
        color: white;
        box-shadow: 0 16px 48px rgba(43, 118, 184, 0.25);
        min-height: 270px;
        height: fit-content;
        display: flex;
        flex-direction: column;
        justify-content: space-between;
        border: 1px solid rgba(255, 255, 255, 0.1);
        position: relative;
        overflow: hidden;
      }

      .dashboard-preview::before {
        content: '';
        position: absolute;
        top: -50%;
        right: -50%;
        width: 200%;
        height: 200%;
        background: radial-gradient(circle, rgba(255, 255, 255, 0.05) 1px, transparent 1px);
        background-size: 50px 50px;
        pointer-events: none;
      }

      .dashboard-header {
        margin-bottom: 1rem;
        position: relative;
        z-index: 1;
      }

      .dashboard-header h3 {
        font-size: 1.5rem;
        font-weight: 700;
        margin-bottom: 0.6rem;
        letter-spacing: -0.5px;
      }

      .dashboard-header p {
        font-size: 0.95rem;
        opacity: 0.95;
        line-height: 1.5;
      }

      .dashboard-features {
        display: flex;
        flex-direction: column;
        gap: 0.75rem;
        position: relative;
        z-index: 1;
      }

      .feature-item {
        padding: 0.85rem 0.95rem;
        background: rgba(255, 255, 255, 0.12);
        border-radius: 8px;
        font-size: 0.9rem;
        line-height: 1.5;
        border: 1px solid rgba(255, 255, 255, 0.15);
        transition: all 0.3s ease;
      }

      .feature-item:hover {
        background: rgba(255, 255, 255, 0.18);
        border-color: rgba(255, 255, 255, 0.25);
      }

      .feature-item strong {
        display: block;
        margin-bottom: 0.5rem;
        font-weight: 700;
        font-size: 1rem;
      }

      /* About Us Section */
      .about-section {
        background: white;
        padding: 4rem 2.5rem;
        margin-top: 2rem;
        border-top: 1px solid #e5ecf2;
      }

      .about-container {
        max-width: 1400px;
        margin: 0 auto;
      }

      .about-title {
        font-size: 2.2rem;
        font-weight: 700;
        color: #1c3752;
        margin-bottom: 2rem;
        letter-spacing: -0.5px;
      }

      .about-grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
        gap: 1.5rem;
      }

      .about-card {
        padding: 1.5rem;
        background: #f5f9fc;
        border-radius: 8px;
        border: 1px solid #e5ecf2;
        transition: all 0.3s ease;
      }

      .about-card:hover {
        box-shadow: 0 4px 16px rgba(43, 118, 184, 0.1);
        transform: translateY(-4px);
      }

      .about-card h3 {
        font-size: 1.3rem;
        color: #2b76b8;
        margin-bottom: 1rem;
        font-weight: 600;
      }

      .about-card p {
        color: #4a6fa5;
        font-size: 0.95rem;
        line-height: 1.7;
      }
      @media (max-width: 1024px) {
        .hero-section {
          grid-template-columns: 1fr;
          gap: 2rem;
          padding: 3rem 1.5rem;
        }

        .hero-left {
          padding-right: 0;
        }

        .hero-title {
          font-size: 2.9rem;
        }

        .dashboard-preview {
          min-height: 350px;
        }

        .why-use-cards {
          grid-template-columns: repeat(3, minmax(0, 1fr));
        }

        .about-section {
          padding: 3rem 1.5rem;
        }

        .about-title {
          font-size: 2rem;
        }
      }

      @media (max-width: 768px) {
        .landing-header {
          padding: 1rem 1.5rem;
        }

        .hero-section {
          padding: 2rem 1.25rem;
          gap: 1.5rem;
        }

        .hero-title {
          font-size: 2.2rem;
        }

        .hero-subtitle {
          font-size: 1rem;
        }

        .hero-login-btn {
          width: 100%;
          text-align: center;
          margin-bottom: 2.25rem;
        }

        .why-use-cards {
          grid-template-columns: 1fr;
        }

        .why-use-section {
          padding: 0 1.5rem 3rem;
        }

        .dashboard-preview {
          min-height: 350px;
          padding: 1.4rem;
        }

        .about-section {
          padding: 2.5rem 1.25rem;
        }

        .about-title {
          font-size: 1.9rem;
        }
      }
    </style>
  </head>
  <body>
    <header class="landing-header">
      <a class="header-brand" href="index.jsp">
        <span class="logo-chip"><i>Healger</i></span>
      </a>
      <a href="register.jsp" class="header-signin">Sign up</a>
    </header>

    <section class="hero-section">
      <div class="hero-left">
        <h1 class="hero-title">Keep your records, reminders, and daily tracking in one calm place.</h1>
        <p class="hero-subtitle">Simple. Secure. Ready when you are. Manage your health, budget, and daily life with an integrated platform designed for you.</p>
        <a href="login.jsp" class="hero-login-btn">Login</a>
      </div>

      <div class="hero-right">
        <div class="dashboard-preview">
          <div class="dashboard-header">
            <h3>Everything you need in one dashboard</h3>
            <p>Why people use Healger</p>
          </div>
          <div class="dashboard-features">
            <div class="feature-item">
              <strong>Track Everything</strong>
              Stay organized, reduce missed tasks, and keep important notes easy to find.
            </div>
            <div class="feature-item">
              <strong>Smart Budget</strong>
              Log in, view reminders, track history, review budgets, and keep journal notes together.
            </div>
            <div class="feature-item">
              <strong>Health Tracking</strong>
              Monitor your wellness journey with daily tracking and personalized insights.
            </div>
          </div>
        </div>
      </div>
    </section>

    <section class="why-use-section">
      <div class="why-use-wrap">
        <span class="why-use-title">Why Healger</span>
        <div class="why-use-cards">
          <div class="why-card">
            <h4>One home for your workflow</h4>
            <p>Users can move from tracking in one interface with your dashboard without confusion.</p>
          </div>
          <div class="why-card">
            <h4>Quick, secure access</h4>
            <p>A clear login path keeps the public page simple while protecting the app area.</p>
          </div>
          <div class="why-card">
            <h4>Designed to feel consistent</h4>
            <p>The same blue theme carries from the landing page into the sign-in experience.</p>
          </div>
        </div>
      </div>
    </section>

    <!-- About Us Section -->
    <section class="about-section">
      <div class="about-container">
        <h2 class="about-title">About Healger</h2>
        <div class="about-grid">
          <div class="about-card">
            <h3>Our Mission</h3>
            <p>We empower individuals to take control of their health and finances by providing a unified platform for tracking, managing, and achieving their personal goals.</p>
          </div>
          <div class="about-card">
            <h3>Our Vision</h3>
            <p>To make personal wellness and financial management accessible, intuitive, and integrated for everyone, eliminating the need to juggle multiple apps.</p>
          </div>
          <div class="about-card">
            <h3>Our Values</h3>
            <p>We prioritize your privacy, security, and simplicity. Your data is protected, your experience is seamless, and your satisfaction is our success.</p>
          </div>
        </div>
      </div>
    </section>
  </body>
</html>
