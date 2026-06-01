package com.aifb.platform.admin.api.dto;

import java.util.List;
import java.util.Map;

public record SqlResultResponse(
    List<String> columns,
    List<Map<String, Object>> rows,
    String error
) {
    public static SqlResultResponse success(List<String> columns, List<Map<String, Object>> rows) {
        return new SqlResultResponse(columns, rows, null);
    }

    public static SqlResultResponse failure(String error) {
        return new SqlResultResponse(null, null, error);
    }
}
