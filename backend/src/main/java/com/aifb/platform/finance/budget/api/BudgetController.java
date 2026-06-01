package com.aifb.platform.finance.budget.api;

import com.aifb.platform.common.api.ApiResponse;
import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.common.security.AuthPrincipal;
import com.aifb.platform.common.security.CurrentUser;
import com.aifb.platform.finance.budget.api.dto.BudgetResponse;
import com.aifb.platform.finance.budget.api.dto.CreateBudgetRequest;
import com.aifb.platform.finance.budget.api.dto.UpdateBudgetRequest;
import com.aifb.platform.finance.budget.service.BudgetService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/budgets")
public class BudgetController {

    private final BudgetService service;

    public BudgetController(BudgetService service) {
        this.service = service;
    }

    @GetMapping
    public ApiResponse<List<BudgetResponse>> list(
            @CurrentUser AuthPrincipal principal,
            @RequestParam(defaultValue = "PERSONAL") Scope scope) {
        return ApiResponse.ok(service.list(principal.userId(), scope));
    }

    @PostMapping
    public ApiResponse<BudgetResponse> create(
            @CurrentUser AuthPrincipal principal,
            @Valid @RequestBody CreateBudgetRequest request) {
        return ApiResponse.ok(service.create(principal.userId(), request));
    }

    @PutMapping("/{id}")
    public ApiResponse<BudgetResponse> update(
            @CurrentUser AuthPrincipal principal,
            @PathVariable UUID id,
            @Valid @RequestBody UpdateBudgetRequest request) {
        return ApiResponse.ok(service.update(principal.userId(), id, request));
    }

    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(
            @CurrentUser AuthPrincipal principal,
            @PathVariable UUID id) {
        service.delete(principal.userId(), id);
        return ApiResponse.ok(null);
    }
}
