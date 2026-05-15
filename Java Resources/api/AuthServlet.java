package com.rtrp.api;

import com.rtrp.db.Database;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

@WebServlet(urlPatterns = {"/api/auth/register", "/api/auth/login", "/api/auth/logout", "/api/auth/me"})
public class AuthServlet extends HttpServlet {
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json");
        resp.setCharacterEncoding("UTF-8");
        String path = req.getServletPath();

        try {
            if ("/api/auth/register".equals(path)) {
                handleRegister(req, resp);
                return;
            }
            if ("/api/auth/login".equals(path)) {
                handleLogin(req, resp);
                return;
            }
            if ("/api/auth/logout".equals(path)) {
                req.getSession().invalidate();
                writeJson(resp, 200, jsonOk("Logged out"));
                return;
            }
            writeJson(resp, 404, jsonError("Endpoint not found"));
        } catch (Exception e) {
            writeJson(resp, 500, jsonError(e.getMessage()));
        }
    }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json");
        resp.setCharacterEncoding("UTF-8");
        if (!"/api/auth/me".equals(req.getServletPath())) {
            writeJson(resp, 404, jsonError("Endpoint not found"));
            return;
        }

        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            writeJson(resp, 401, jsonError("Not logged in"));
            return;
        }

        String body = "{"
                + "\"success\":true,"
                + "\"userId\":" + session.getAttribute("userId") + ","
                + "\"name\":\"" + escapeJson(String.valueOf(session.getAttribute("name"))) + "\","
                + "\"email\":\"" + escapeJson(String.valueOf(session.getAttribute("email"))) + "\","
                + "\"username\":\"" + escapeJson(String.valueOf(session.getAttribute("username"))) + "\""
                + "}";
        writeJson(resp, 200, body);
    }

    private void handleRegister(HttpServletRequest req, HttpServletResponse resp) throws Exception {
        String name = param(req, "name");
        String email = param(req, "email");
        String mobile = param(req, "mobile");
        String dob = param(req, "dob");
        String password = param(req, "password");
        String securityQuestion = param(req, "securityQuestion");
        String securityAnswer = param(req, "securityAnswer");

        if (name.isBlank() || email.isBlank() || mobile.isBlank() || dob.isBlank() || password.isBlank() || securityQuestion.isBlank() || securityAnswer.isBlank()) {
            writeJson(resp, 400, jsonError("Please fill in all fields"));
            return;
        }

        String username = email.contains("@") ? email.substring(0, email.indexOf('@')) : email;

        try (Connection con = Database.getConnection()) {
            try (PreparedStatement check = con.prepareStatement("SELECT id FROM users WHERE email = ? OR username = ?")) {
                check.setString(1, email);
                check.setString(2, username);
                ResultSet rs = check.executeQuery();
                if (rs.next()) {
                    writeJson(resp, 409, jsonError("Username or email already exists"));
                    return;
                }
            }

            try (PreparedStatement insert = con.prepareStatement(
                    "INSERT INTO users (username, email, password_hash, full_name, dob, mobile_number, security_question, security_answer) VALUES (?, ?, ?, ?, ?, ?, ?, ?)")) {
                insert.setString(1, username);
                insert.setString(2, email);
                insert.setString(3, sha256(password));
                insert.setString(4, name);
                insert.setString(5, dob);
                insert.setString(6, mobile);
                insert.setString(7, securityQuestion);
                insert.setString(8, securityAnswer.toLowerCase());
                insert.executeUpdate();
            }
        }

        writeJson(resp, 201, jsonOk("Registration successful"));
    }

    private void handleLogin(HttpServletRequest req, HttpServletResponse resp) throws Exception {
        String usernameOrEmail = param(req, "username");
        String password = param(req, "password");
        String securityAnswer = param(req, "securityAnswer").toLowerCase();

        if (usernameOrEmail.isBlank() || password.isBlank() || securityAnswer.isBlank()) {
            writeJson(resp, 400, jsonError("Please fill in all fields"));
            return;
        }

        try (Connection con = Database.getConnection();
             PreparedStatement ps = con.prepareStatement(
                     "SELECT id, username, email, full_name, security_question, security_answer, password_hash FROM users WHERE username = ? OR email = ?")) {
            ps.setString(1, usernameOrEmail);
            ps.setString(2, usernameOrEmail);
            ResultSet rs = ps.executeQuery();

            if (!rs.next()) {
                writeJson(resp, 401, jsonError("Invalid username/email"));
                return;
            }

            String expectedHash = rs.getString("password_hash");
            if (!expectedHash.equals(sha256(password))) {
                writeJson(resp, 401, jsonError("Invalid password"));
                return;
            }

            if (!rs.getString("security_answer").equalsIgnoreCase(securityAnswer)) {
                writeJson(resp, 401, jsonError("Incorrect security answer"));
                return;
            }

            HttpSession session = req.getSession(true);
            session.setAttribute("userId", rs.getLong("id"));
            session.setAttribute("username", rs.getString("username"));
            session.setAttribute("email", rs.getString("email"));
            session.setAttribute("name", rs.getString("full_name"));

            String body = "{"
                    + "\"success\":true,"
                    + "\"message\":\"Login successful\","
                    + "\"securityQuestion\":\"" + escapeJson(rs.getString("security_question")) + "\","
                    + "\"name\":\"" + escapeJson(rs.getString("full_name")) + "\""
                    + "}";
            writeJson(resp, 200, body);
        }
    }

    private String param(HttpServletRequest req, String key) {
        String value = req.getParameter(key);
        return value == null ? "" : value.trim();
    }

    private String sha256(String value) throws Exception {
        MessageDigest md = MessageDigest.getInstance("SHA-256");
        byte[] bytes = md.digest(value.getBytes(StandardCharsets.UTF_8));
        StringBuilder sb = new StringBuilder();
        for (byte b : bytes) {
            sb.append(String.format("%02x", b));
        }
        return sb.toString();
    }

    private String jsonOk(String message) {
        return "{\"success\":true,\"message\":\"" + escapeJson(message) + "\"}";
    }

    private String jsonError(String message) {
        String safe = message == null ? "Unexpected error" : message;
        return "{\"success\":false,\"message\":\"" + escapeJson(safe) + "\"}";
    }

    private String escapeJson(String value) {
        if (value == null) {
            return "";
        }
        return value
                .replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\n", "\\n")
                .replace("\r", "\\r");
    }

    private void writeJson(HttpServletResponse resp, int status, String body) throws IOException {
        resp.setStatus(status);
        resp.getWriter().write(body);
    }
}
