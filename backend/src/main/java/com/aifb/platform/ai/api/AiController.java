package com.aifb.platform.ai.api;

import com.aifb.platform.ai.api.dto.*;
import com.aifb.platform.ai.service.AiService;
import com.aifb.platform.common.api.ApiResponse;
import com.aifb.platform.common.security.AuthPrincipal;
import com.aifb.platform.common.security.CurrentUser;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/ai")
public class AiController {

    private final AiService aiService;

    public AiController(AiService aiService) {
        this.aiService = aiService;
    }

    @PostMapping("/chat")
    public ApiResponse<AiMessageResponse> chat(@CurrentUser AuthPrincipal principal,
                                               @Valid @RequestBody ChatRequest request) {
        return ApiResponse.ok(aiService.chat(principal.userId(), request));
    }

    @PostMapping("/analyze-budget")
    public ApiResponse<BudgetAnalysisResponse> analyze(@CurrentUser AuthPrincipal principal,
                                                       @RequestBody(required = false) AnalyzeBudgetRequest request) {
        return ApiResponse.ok(aiService.analyzeBudget(principal.userId(), request));
    }

    @GetMapping("/insights")
    public ApiResponse<List<InsightResponse>> insights(@CurrentUser AuthPrincipal principal) {
        return ApiResponse.ok(aiService.insights(principal.userId()));
    }

    @PostMapping("/savings-plan")
    public ApiResponse<SavingsPlanResponse> savingsPlan(@CurrentUser AuthPrincipal principal,
                                                        @Valid @RequestBody SavingsPlanRequest request) {
        return ApiResponse.ok(aiService.savingsPlan(principal.userId(), request));
    }
}
