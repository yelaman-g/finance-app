package com.aifb.platform.admin.service;

import com.aifb.platform.admin.api.dto.SqlResultResponse;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Service
public class AdminDatabaseService {

    private final JdbcTemplate jdbcTemplate;

    public AdminDatabaseService(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public List<String> getPublicTables() {
        String sql = "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name";
        return jdbcTemplate.queryForList(sql, String.class);
    }

    public SqlResultResponse executeQuery(String sql) {
        try {
            if (sql == null || sql.trim().isEmpty()) {
                return SqlResultResponse.failure("SQL query cannot be empty");
            }
            
            String upperSql = sql.trim().toUpperCase();
            boolean isSelect = upperSql.startsWith("SELECT") || upperSql.startsWith("WITH") || upperSql.startsWith("EXPLAIN");

            if (isSelect) {
                List<Map<String, Object>> rows = jdbcTemplate.queryForList(sql);
                List<String> columns = new ArrayList<>();
                if (!rows.isEmpty()) {
                    columns.addAll(rows.get(0).keySet());
                }
                return SqlResultResponse.success(columns, rows);
            } else {
                int updatedRows = jdbcTemplate.update(sql);
                return SqlResultResponse.success(
                        List.of("Result"),
                        List.of(Map.of("Result", "Success: " + updatedRows + " rows affected"))
                );
            }
        } catch (DataAccessException e) {
            // Return the database error message directly to the client
            return SqlResultResponse.failure(e.getMostSpecificCause().getMessage());
        } catch (Exception e) {
            return SqlResultResponse.failure("Unknown error: " + e.getMessage());
        }
    }
}
