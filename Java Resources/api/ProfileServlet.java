package com.rtrp.api;

import com.rtrp.db.Database;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

@WebServlet(urlPatterns = {"/api/profile/get", "/api/profile/delete"})
public class ProfileServlet extends HttpServlet {
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws IOException {
        resp.setContentType("application/json");
        resp.setCharacterEncoding("UTF-8");
        String path = req.getServletPath();

        HttpSession session = req.getSession(false);
        if (session == null || session.getAttribute("userId") == null) {
            writeJson(resp, 401, jsonError("Not logged in"));
            return;
        }

        try {
            if ("/api/profile/get".equals(path)) {
                handleGetProfile(req, resp, (Long) session.getAttribute("userId"));
                return;
            }
            if ("/api/profile/delete".equals(path)) {
                handleDeleteAccount(req, resp, (Long) session.getAttribute("userId"), session);
                return;
            }
            writeJson(resp, 404, jsonError("Endpoint not found"));
        } catch (Exception e) {
            writeJson(resp, 500, jsonError(e.getMessage()));
        }
    }

    private void handleGetProfile(HttpServletRequest req, HttpServletResponse resp, Long userId) throws SQLException, IOException {
        Connection conn = Database.getConnection();
        try {
            String sql = "SELECT id, username, email, full_name, dob, mobile_number, security_question FROM users WHERE id = ?";
            PreparedStatement pstmt = conn.prepareStatement(sql);
            pstmt.setLong(1, userId);
            ResultSet rs = pstmt.executeQuery();

            if (rs.next()) {
                String body = "{"
                        + "\"success\":true,"
                        + "\"username\":\"" + escapeJson(rs.getString("username")) + "\","
                        + "\"email\":\"" + escapeJson(rs.getString("email")) + "\","
                        + "\"fullName\":\"" + escapeJson(rs.getString("full_name")) + "\","
                        + "\"dob\":\"" + escapeJson(rs.getString("dob")) + "\","
                        + "\"mobile\":\"" + escapeJson(rs.getString("mobile_number")) + "\","
                        + "\"securityQuestion\":\"" + escapeJson(rs.getString("security_question")) + "\""
                        + "}";
                writeJson(resp, 200, body);
            } else {
                writeJson(resp, 404, jsonError("User not found"));
            }
            rs.close();
            pstmt.close();
        } finally {
            conn.close();
        }
    }

    private void handleDeleteAccount(HttpServletRequest req, HttpServletResponse resp, Long userId, HttpSession session) throws SQLException, IOException {
        Connection conn = Database.getConnection();
        try {
            // Delete all budget expenses
            String deleteBudgetSql = "DELETE FROM budget_expenses WHERE user_id = ?";
            PreparedStatement budgetStmt = conn.prepareStatement(deleteBudgetSql);
            budgetStmt.setLong(1, userId);
            budgetStmt.executeUpdate();
            budgetStmt.close();

            // Delete all user data (journals, reminders, etc.)
            String deleteDataSql = "DELETE FROM user_data WHERE user_id = ?";
            PreparedStatement dataStmt = conn.prepareStatement(deleteDataSql);
            dataStmt.setLong(1, userId);
            dataStmt.executeUpdate();
            dataStmt.close();

            // Delete user account (cascades will handle rest)
            String deleteUserSql = "DELETE FROM users WHERE id = ?";
            PreparedStatement userStmt = conn.prepareStatement(deleteUserSql);
            userStmt.setLong(1, userId);
            int rowsAffected = userStmt.executeUpdate();
            userStmt.close();

            if (rowsAffected > 0) {
                session.invalidate();
                writeJson(resp, 200, jsonOk("Account deleted successfully"));
            } else {
                writeJson(resp, 404, jsonError("User not found"));
            }
        } finally {
            conn.close();
        }
    }

    protected void writeJson(HttpServletResponse resp, int status, String body) throws IOException {
        resp.setStatus(status);
        resp.getWriter().write(body);
    }

    protected String jsonOk(String message) {
        return "{\"success\":true,\"message\":\"" + escapeJson(message) + "\"}";
    }

    protected String jsonError(String message) {
        return "{\"success\":false,\"error\":\"" + escapeJson(message) + "\"}";
    }

    protected String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r");
    }
}
