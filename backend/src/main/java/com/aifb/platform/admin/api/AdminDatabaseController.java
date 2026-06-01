package com.aifb.platform.admin.api;

import com.aifb.platform.admin.api.dto.SqlQueryRequest;
import com.aifb.platform.admin.api.dto.SqlResultResponse;
import com.aifb.platform.admin.service.AdminDatabaseService;
import com.aifb.platform.common.api.ApiResponse;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/admin/db")
@PreAuthorize("hasRole('ADMIN')")
public class AdminDatabaseController {

    private final AdminDatabaseService adminDatabaseService;

    public AdminDatabaseController(AdminDatabaseService adminDatabaseService) {
        this.adminDatabaseService = adminDatabaseService;
    }

    @GetMapping("/tables")
    public ApiResponse<List<String>> getTables() {
        return ApiResponse.ok(adminDatabaseService.getPublicTables());
    }

    @PostMapping("/query")
    public ApiResponse<SqlResultResponse> executeQuery(@RequestBody SqlQueryRequest request) {
        SqlResultResponse result = adminDatabaseService.executeQuery(request.query());
        if (result.error() != null) {
            // Wrap failure in HTTP 200, the error is inside the DTO for the frontend to render nicely in the SQL console
            return ApiResponse.ok(result);
        }
        return ApiResponse.ok(result);
    }
}
