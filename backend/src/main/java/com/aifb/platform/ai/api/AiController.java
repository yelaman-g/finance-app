package com.aifb.platform.ai.api;

import com.aifb.platform.ai.api.dto.*;
import com.aifb.platform.ai.service.AiService;
import com.aifb.platform.ai.service.ReminderService;
import com.aifb.platform.common.api.ApiResponse;
import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.common.security.AuthPrincipal;
import com.aifb.platform.common.security.CurrentUser;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/ai")
public class AiController {

    private final AiService aiService;
    private final ReminderService reminderService;

    public AiController(AiService aiService, ReminderService reminderService) {
        this.aiService = aiService;
        this.reminderService = reminderService;
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

    @GetMapping("/reminders")
    public ApiResponse<List<ReminderResponse>> reminders(
            @CurrentUser AuthPrincipal principal,
            @RequestParam(defaultValue = "PERSONAL") Scope scope) {
        return ApiResponse.ok(reminderService.list(principal.userId(), scope));
    }

    @PostMapping("/reminders")
    public ApiResponse<ReminderResponse> createReminder(
            @CurrentUser AuthPrincipal principal,
            @Valid @RequestBody CreateReminderRequest request) {
        return ApiResponse.ok(reminderService.create(principal.userId(), request));
    }

    @DeleteMapping("/reminders/{id}")
    public ApiResponse<Void> deleteReminder(
            @CurrentUser AuthPrincipal principal,
            @PathVariable UUID id) {
        reminderService.delete(principal.userId(), id);
        return ApiResponse.ok(null);
    }
}
