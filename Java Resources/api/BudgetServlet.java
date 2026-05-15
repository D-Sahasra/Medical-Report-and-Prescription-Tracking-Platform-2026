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

@WebServlet(urlPatterns = {"/api/budget/add", "/api/budget/get", "/api/budget/stats", "/api/budget/update", "/api/budget/delete"})
public class BudgetServlet extends HttpServlet {
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
            Long userId = (Long) session.getAttribute("userId");
            if ("/api/budget/add".equals(path)) {
                handleAddExpense(req, resp, userId);
                return;
            }
            if ("/api/budget/get".equals(path)) {
                handleGetExpenses(req, resp, userId);
                return;
            }
            if ("/api/budget/stats".equals(path)) {
                handleGetStats(req, resp, userId);
                return;
            }
            if ("/api/budget/update".equals(path)) {
                handleUpdateExpense(req, resp, userId);
                return;
            }
            if ("/api/budget/delete".equals(path)) {
                handleDeleteExpense(req, resp, userId);
                return;
            }
            writeJson(resp, 404, jsonError("Endpoint not found"));
        } catch (Exception e) {
            writeJson(resp, 500, jsonError(e.getMessage()));
        }
    }

    private void handleUpdateExpense(HttpServletRequest req, HttpServletResponse resp, Long userId) throws SQLException, IOException {
        String expenseId = param(req, "expenseId");
        String category = param(req, "category");
        String amount = param(req, "amount");
        String description = param(req, "description");
        String expenseDate = param(req, "expenseDate");

        if (expenseId.isBlank() || category.isBlank() || amount.isBlank() || expenseDate.isBlank()) {
            writeJson(resp, 400, jsonError("Missing required fields"));
            return;
        }

        long expenseIdValue;
        try {
            expenseIdValue = Long.parseLong(expenseId);
        } catch (NumberFormatException e) {
            writeJson(resp, 400, jsonError("Invalid expense id"));
            return;
        }

        double amountValue;
        try {
            amountValue = Double.parseDouble(amount);
            if (amountValue <= 0) {
                writeJson(resp, 400, jsonError("Amount must be greater than 0"));
                return;
            }
        } catch (NumberFormatException e) {
            writeJson(resp, 400, jsonError("Invalid amount format"));
            return;
        }

        Connection conn = Database.getConnection();
        try {
            String sql = "UPDATE budget_expenses SET category = ?, amount = ?, description = ?, expense_date = ? WHERE id = ? AND user_id = ?";
            PreparedStatement pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, category);
            pstmt.setDouble(2, amountValue);
            pstmt.setString(3, description.isBlank() ? null : description);
            pstmt.setString(4, expenseDate);
            pstmt.setLong(5, expenseIdValue);
            pstmt.setLong(6, userId);
            int updatedRows = pstmt.executeUpdate();
            pstmt.close();

            if (updatedRows == 0) {
                writeJson(resp, 404, jsonError("Expense not found"));
                return;
            }

            writeJson(resp, 200, jsonOk("Expense updated successfully"));
        } finally {
            conn.close();
        }
    }

    private void handleDeleteExpense(HttpServletRequest req, HttpServletResponse resp, Long userId) throws SQLException, IOException {
        String expenseId = param(req, "expenseId");
        if (expenseId.isBlank()) {
            writeJson(resp, 400, jsonError("Missing expense id"));
            return;
        }

        long expenseIdValue;
        try {
            expenseIdValue = Long.parseLong(expenseId);
        } catch (NumberFormatException e) {
            writeJson(resp, 400, jsonError("Invalid expense id"));
            return;
        }

        Connection conn = Database.getConnection();
        try {
            String sql = "DELETE FROM budget_expenses WHERE id = ? AND user_id = ?";
            PreparedStatement pstmt = conn.prepareStatement(sql);
            pstmt.setLong(1, expenseIdValue);
            pstmt.setLong(2, userId);
            int deletedRows = pstmt.executeUpdate();
            pstmt.close();

            if (deletedRows == 0) {
                writeJson(resp, 404, jsonError("Expense not found"));
                return;
            }

            writeJson(resp, 200, jsonOk("Expense deleted successfully"));
        } finally {
            conn.close();
        }
    }

    private void handleAddExpense(HttpServletRequest req, HttpServletResponse resp, Long userId) throws SQLException, IOException {
        String category = param(req, "category");
        String amount = param(req, "amount");
        String description = param(req, "description");
        String expenseDate = param(req, "expenseDate");

        if (category.isBlank() || amount.isBlank() || expenseDate.isBlank()) {
            writeJson(resp, 400, jsonError("Missing required fields"));
            return;
        }

        try {
            double amountValue = Double.parseDouble(amount);
            if (amountValue <= 0) {
                writeJson(resp, 400, jsonError("Amount must be greater than 0"));
                return;
            }
        } catch (NumberFormatException e) {
            writeJson(resp, 400, jsonError("Invalid amount format"));
            return;
        }

        Connection conn = Database.getConnection();
        try {
            String sql = "INSERT INTO budget_expenses (user_id, category, amount, description, expense_date) VALUES (?, ?, ?, ?, ?)";
            PreparedStatement pstmt = conn.prepareStatement(sql);
            pstmt.setLong(1, userId);
            pstmt.setString(2, category);
            pstmt.setDouble(3, Double.parseDouble(amount));
            pstmt.setString(4, description.isBlank() ? null : description);
            pstmt.setString(5, expenseDate);
            pstmt.executeUpdate();
            pstmt.close();
            writeJson(resp, 200, jsonOk("Expense added successfully"));
        } finally {
            conn.close();
        }
    }

    private void handleGetExpenses(HttpServletRequest req, HttpServletResponse resp, Long userId) throws SQLException, IOException {
        String startDate = param(req, "startDate");
        String endDate = param(req, "endDate");

        Connection conn = Database.getConnection();
        try {
            StringBuilder sql = new StringBuilder("SELECT id, category, amount, description, expense_date FROM budget_expenses WHERE user_id = ?");
            if (!startDate.isBlank() && !endDate.isBlank()) {
                sql.append(" AND expense_date >= ? AND expense_date <= ?");
            }
            sql.append(" ORDER BY expense_date DESC");

            PreparedStatement pstmt = conn.prepareStatement(sql.toString());
            pstmt.setLong(1, userId);
            if (!startDate.isBlank() && !endDate.isBlank()) {
                pstmt.setString(2, startDate);
                pstmt.setString(3, endDate);
            }

            ResultSet rs = pstmt.executeQuery();
            StringBuilder expenses = new StringBuilder("[");
            boolean first = true;

            while (rs.next()) {
                if (!first) expenses.append(",");
                expenses.append("{")
                        .append("\"id\":").append(rs.getLong("id")).append(",")
                        .append("\"category\":\"").append(escapeJson(rs.getString("category"))).append("\",")
                        .append("\"amount\":").append(rs.getDouble("amount")).append(",")
                        .append("\"description\":\"").append(escapeJson(rs.getString("description") != null ? rs.getString("description") : "")).append("\",")
                        .append("\"expenseDate\":\"").append(escapeJson(rs.getString("expense_date"))).append("\"")
                        .append("}");
                first = false;
            }
            expenses.append("]");

            rs.close();
            pstmt.close();

            String body = "{\"success\":true,\"expenses\":" + expenses.toString() + "}";
            writeJson(resp, 200, body);
        } finally {
            conn.close();
        }
    }

    private void handleGetStats(HttpServletRequest req, HttpServletResponse resp, Long userId) throws SQLException, IOException {
        String period = param(req, "period"); // "month" or "year"
        String year = param(req, "year");
        String month = param(req, "month");

        Connection conn = Database.getConnection();
        try {
            StringBuilder sql = new StringBuilder("SELECT category, SUM(amount) as total FROM budget_expenses WHERE user_id = ?");
            
            if ("year".equalsIgnoreCase(period) && !year.isBlank()) {
                sql.append(" AND YEAR(expense_date) = ?");
            } else if ("month".equalsIgnoreCase(period) && !year.isBlank() && !month.isBlank()) {
                sql.append(" AND YEAR(expense_date) = ? AND MONTH(expense_date) = ?");
            }
            
            sql.append(" GROUP BY category ORDER BY total DESC");

            PreparedStatement pstmt = conn.prepareStatement(sql.toString());
            int paramIndex = 1;
            pstmt.setLong(paramIndex++, userId);
            
            if ("year".equalsIgnoreCase(period) && !year.isBlank()) {
                pstmt.setInt(paramIndex++, Integer.parseInt(year));
            } else if ("month".equalsIgnoreCase(period) && !year.isBlank() && !month.isBlank()) {
                pstmt.setInt(paramIndex++, Integer.parseInt(year));
                pstmt.setInt(paramIndex++, Integer.parseInt(month));
            }

            ResultSet rs = pstmt.executeQuery();
            StringBuilder stats = new StringBuilder("[");
            boolean first = true;

            while (rs.next()) {
                if (!first) stats.append(",");
                stats.append("{")
                        .append("\"category\":\"").append(escapeJson(rs.getString("category"))).append("\",")
                        .append("\"total\":").append(rs.getDouble("total"))
                        .append("}");
                first = false;
            }
            stats.append("]");

            rs.close();
            pstmt.close();

            String body = "{\"success\":true,\"stats\":" + stats.toString() + "}";
            writeJson(resp, 200, body);
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

    protected String param(HttpServletRequest req, String name) {
        String value = req.getParameter(name);
        return value != null ? value : "";
    }

    protected String escapeJson(String s) {
        if (s == null) return "";
        return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "\\r");
    }
}
