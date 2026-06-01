package com.aifb.platform.finance.goal.api;

import com.aifb.platform.common.api.ApiResponse;
import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.common.security.AuthPrincipal;
import com.aifb.platform.common.security.CurrentUser;
import com.aifb.platform.finance.goal.api.dto.ContributionResponse;
import com.aifb.platform.finance.goal.api.dto.CreateContributionRequest;
import com.aifb.platform.finance.goal.api.dto.CreateGoalRequest;
import com.aifb.platform.finance.goal.api.dto.GoalResponse;
import com.aifb.platform.finance.goal.api.dto.UpdateGoalRequest;
import com.aifb.platform.finance.goal.service.GoalService;
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
@RequestMapping("/api/v1/goals")
public class GoalController {

    private final GoalService service;

    public GoalController(GoalService service) {
        this.service = service;
    }

    @GetMapping
    public ApiResponse<List<GoalResponse>> list(@CurrentUser AuthPrincipal principal,
                                                @RequestParam(defaultValue = "PERSONAL") Scope scope) {
        return ApiResponse.ok(service.list(principal.userId(), scope));
    }

    @GetMapping("/{id}")
    public ApiResponse<GoalResponse> get(@CurrentUser AuthPrincipal principal,
                                         @PathVariable UUID id) {
        return ApiResponse.ok(service.get(principal.userId(), id));
    }

    @PostMapping
    public ApiResponse<GoalResponse> create(@CurrentUser AuthPrincipal principal,
                                            @Valid @RequestBody CreateGoalRequest request) {
        return ApiResponse.ok(service.create(principal.userId(), request));
    }

    @PutMapping("/{id}")
    public ApiResponse<GoalResponse> update(@CurrentUser AuthPrincipal principal,
                                            @PathVariable UUID id,
                                            @Valid @RequestBody UpdateGoalRequest request) {
        return ApiResponse.ok(service.update(principal.userId(), id, request));
    }

    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@CurrentUser AuthPrincipal principal,
                                    @PathVariable UUID id) {
        service.delete(principal.userId(), id);
        return ApiResponse.ok(null);
    }

    @GetMapping("/{id}/contributions")
    public ApiResponse<List<ContributionResponse>> listContributions(
            @CurrentUser AuthPrincipal principal,
            @PathVariable UUID id) {
        return ApiResponse.ok(service.listContributions(principal.userId(), id));
    }

    @PostMapping("/{id}/contributions")
    public ApiResponse<ContributionResponse> addContribution(
            @CurrentUser AuthPrincipal principal,
            @PathVariable UUID id,
            @Valid @RequestBody CreateContributionRequest request) {
        return ApiResponse.ok(service.addContribution(principal.userId(), id, request));
    }

    @DeleteMapping("/{id}/contributions/{contributionId}")
    public ApiResponse<Void> deleteContribution(
            @CurrentUser AuthPrincipal principal,
            @PathVariable UUID id,
            @PathVariable UUID contributionId) {
        service.deleteContribution(principal.userId(), id, contributionId);
        return ApiResponse.ok(null);
    }
}
