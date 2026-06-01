package com.aifb.platform.finance.transaction.api;

import com.aifb.platform.common.api.ApiResponse;
import com.aifb.platform.common.api.PageResponse;
import com.aifb.platform.common.security.AuthPrincipal;
import com.aifb.platform.common.security.CurrentUser;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.transaction.api.dto.CreateTransactionRequest;
import com.aifb.platform.finance.transaction.api.dto.TransactionResponse;
import com.aifb.platform.finance.transaction.api.dto.UpdateTransactionRequest;
import com.aifb.platform.finance.transaction.service.TransactionService;
import jakarta.validation.Valid;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/transactions")
public class TransactionController {

    private final TransactionService service;

    public TransactionController(TransactionService service) {
        this.service = service;
    }

    @GetMapping
    public ApiResponse<PageResponse<TransactionResponse>> list(
            @CurrentUser AuthPrincipal principal,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            @RequestParam(required = false) CategoryType type,
            @RequestParam(required = false) UUID categoryId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {
        return ApiResponse.ok(service.list(principal.userId(), from, to, type, categoryId, page, size));
    }

    @GetMapping("/{id}")
    public ApiResponse<TransactionResponse> get(
            @CurrentUser AuthPrincipal principal,
            @PathVariable UUID id) {
        return ApiResponse.ok(service.get(principal.userId(), id));
    }

    @PostMapping
    public ApiResponse<TransactionResponse> create(
            @CurrentUser AuthPrincipal principal,
            @Valid @RequestBody CreateTransactionRequest request) {
        return ApiResponse.ok(service.create(principal.userId(), request));
    }

    @PutMapping("/{id}")
    public ApiResponse<TransactionResponse> update(
            @CurrentUser AuthPrincipal principal,
            @PathVariable UUID id,
            @Valid @RequestBody UpdateTransactionRequest request) {
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
