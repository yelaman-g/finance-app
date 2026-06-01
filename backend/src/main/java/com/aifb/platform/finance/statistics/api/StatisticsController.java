package com.aifb.platform.finance.statistics.api;

import com.aifb.platform.common.api.ApiResponse;
import com.aifb.platform.common.security.AuthPrincipal;
import com.aifb.platform.common.security.CurrentUser;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.statistics.api.dto.CategoryBreakdownResponse;
import com.aifb.platform.finance.statistics.api.dto.SummaryResponse;
import com.aifb.platform.finance.statistics.api.dto.TrendPointResponse;
import com.aifb.platform.finance.statistics.service.StatisticsService;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/v1/statistics")
public class StatisticsController {

    private final StatisticsService service;

    public StatisticsController(StatisticsService service) {
        this.service = service;
    }

    @GetMapping("/summary")
    public ApiResponse<SummaryResponse> summary(
            @CurrentUser AuthPrincipal principal,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return ApiResponse.ok(service.summary(principal.userId(), from, to));
    }

    @GetMapping("/by-category")
    public ApiResponse<List<CategoryBreakdownResponse>> byCategory(
            @CurrentUser AuthPrincipal principal,
            @RequestParam(defaultValue = "EXPENSE") CategoryType type,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return ApiResponse.ok(service.byCategory(principal.userId(), type, from, to));
    }

    @GetMapping("/trend")
    public ApiResponse<List<TrendPointResponse>> trend(
            @CurrentUser AuthPrincipal principal,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {
        return ApiResponse.ok(service.trend(principal.userId(), from, to));
    }
}
