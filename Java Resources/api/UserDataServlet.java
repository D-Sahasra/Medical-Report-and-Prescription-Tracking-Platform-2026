package com.rtrp.api;

import com.rtrp.db.Database;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.BufferedReader;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

@WebServlet(urlPatterns = {"/api/data/uploads", "/api/data/journals", "/api/data/reminders"})
public class UserDataServlet extends HttpServlet {
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json");
        resp.setCharacterEncoding("UTF-8");

        Long userId = getUserId(req);
        if (userId == null) {
            writeJson(resp, 401, "{\"success\":false,\"message\":\"Not logged in\"}");
            return;
        }

        String key = tableForPath(req.getServletPath());
        if (key == null) {
            writeJson(resp, 404, "{\"success\":false,\"message\":\"Endpoint not found\"}");
            return;
        }

        try (Connection con = Database.getConnection();
             PreparedStatement ps = con.prepareStatement("SELECT payload_json FROM user_data WHERE user_id = ? AND data_key = ?")) {
            ps.setLong(1, userId);
            ps.setString(2, key);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                String payload = rs.getString("payload_json");
                if (payload == null || payload.isBlank()) {
                    payload = "[]";
                }
                writeJson(resp, 200, payload);
            } else {
                writeJson(resp, 200, "[]");
            }
        } catch (Exception e) {
            writeJson(resp, 500, "{\"success\":false,\"message\":\"" + escapeJson(e.getMessage()) + "\"}");
        }
    }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json");
        resp.setCharacterEncoding("UTF-8");

        Long userId = getUserId(req);
        if (userId == null) {
            writeJson(resp, 401, "{\"success\":false,\"message\":\"Not logged in\"}");
            return;
        }

        String key = tableForPath(req.getServletPath());
        if (key == null) {
            writeJson(resp, 404, "{\"success\":false,\"message\":\"Endpoint not found\"}");
            return;
        }

        try {
            String payload = readBody(req);
            if (payload == null || payload.isBlank()) {
                payload = "[]";
            }

            try (Connection con = Database.getConnection();
                 PreparedStatement ps = con.prepareStatement(
                         "INSERT INTO user_data (user_id, data_key, payload_json) VALUES (?, ?, ?) " +
                                 "ON DUPLICATE KEY UPDATE payload_json = VALUES(payload_json), updated_at = CURRENT_TIMESTAMP")) {
                ps.setLong(1, userId);
                ps.setString(2, key);
                ps.setString(3, payload);
                ps.executeUpdate();
            }

            writeJson(resp, 200, "{\"success\":true,\"message\":\"Saved\"}");
        } catch (Exception e) {
            writeJson(resp, 500, "{\"success\":false,\"message\":\"" + escapeJson(e.getMessage()) + "\"}");
        }
    }

    private Long getUserId(HttpServletRequest req) {
        HttpSession session = req.getSession(false);
        if (session == null) {
            return null;
        }
        Object value = session.getAttribute("userId");
        if (value instanceof Long) {
            return (Long) value;
        }
        if (value instanceof Integer) {
            return ((Integer) value).longValue();
        }
        return null;
    }

    private String tableForPath(String path) {
        if ("/api/data/uploads".equals(path)) {
            return "uploads";
        }
        if ("/api/data/journals".equals(path)) {
            return "journals";
        }
        if ("/api/data/reminders".equals(path)) {
            return "reminders";
        }
        return null;
    }

    private String readBody(HttpServletRequest req) throws IOException {
        StringBuilder sb = new StringBuilder();
        try (BufferedReader reader = req.getReader()) {
            String line;
            while ((line = reader.readLine()) != null) {
                sb.append(line);
            }
        }
        return sb.toString();
    }

    private String escapeJson(String value) {
        if (value == null) {
            return "Unexpected error";
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
