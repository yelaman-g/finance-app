package com.aifb.platform.finance.categorization.api;

import com.aifb.platform.common.api.ApiResponse;
import com.aifb.platform.common.security.AuthPrincipal;
import com.aifb.platform.common.security.CurrentUser;
import com.aifb.platform.finance.categorization.api.dto.CreateRuleRequest;
import com.aifb.platform.finance.categorization.api.dto.RuleResponse;
import com.aifb.platform.finance.categorization.api.dto.SuggestRequest;
import com.aifb.platform.finance.categorization.api.dto.SuggestResponse;
import com.aifb.platform.finance.categorization.api.dto.UpdateRuleRequest;
import com.aifb.platform.finance.categorization.service.CategorizationService;
import com.aifb.platform.finance.category.domain.Category;
import com.aifb.platform.finance.category.repository.CategoryRepository;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/categorization")
public class CategorizationController {

    private final CategorizationService service;
    private final CategoryRepository categoryRepository;

    public CategorizationController(CategorizationService service,
                                    CategoryRepository categoryRepository) {
        this.service = service;
        this.categoryRepository = categoryRepository;
    }

    @GetMapping("/rules")
    public ApiResponse<List<RuleResponse>> list(@CurrentUser AuthPrincipal principal) {
        return ApiResponse.ok(service.list(principal.userId()));
    }

    @PostMapping("/rules")
    public ApiResponse<RuleResponse> create(
            @CurrentUser AuthPrincipal principal,
            @Valid @RequestBody CreateRuleRequest request) {
        return ApiResponse.ok(service.create(principal.userId(), request));
    }

    @PutMapping("/rules/{id}")
    public ApiResponse<RuleResponse> update(
            @CurrentUser AuthPrincipal principal,
            @PathVariable UUID id,
            @Valid @RequestBody UpdateRuleRequest request) {
        return ApiResponse.ok(service.update(principal.userId(), id, request));
    }

    @DeleteMapping("/rules/{id}")
    public ApiResponse<Void> delete(
            @CurrentUser AuthPrincipal principal,
            @PathVariable UUID id) {
        service.delete(principal.userId(), id);
        return ApiResponse.ok(null);
    }

    @PostMapping("/suggest")
    public ApiResponse<SuggestResponse> suggest(
            @CurrentUser AuthPrincipal principal,
            @Valid @RequestBody SuggestRequest request) {
        return ApiResponse.ok(service.resolve(principal.userId(), request.note(), request.type())
                .map(categoryId -> new SuggestResponse(
                        categoryId,
                        categoryRepository.findById(categoryId).map(Category::getName).orElse("—")))
                .orElse(null));
    }
}
