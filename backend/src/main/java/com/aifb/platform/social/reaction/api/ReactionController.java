package com.aifb.platform.social.reaction.api;

import com.aifb.platform.common.api.ApiResponse;
import com.aifb.platform.common.security.AuthPrincipal;
import com.aifb.platform.common.security.CurrentUser;
import com.aifb.platform.social.reaction.api.dto.ReactRequest;
import com.aifb.platform.social.reaction.api.dto.ReactionResponse;
import com.aifb.platform.social.reaction.service.ReactionService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/transactions")
public class ReactionController {

    private final ReactionService reactionService;

    public ReactionController(ReactionService reactionService) {
        this.reactionService = reactionService;
    }

    @PostMapping("/{transactionId}/reactions")
    public ApiResponse<Void> react(@CurrentUser AuthPrincipal principal,
                                   @PathVariable UUID transactionId,
                                   @Valid @RequestBody ReactRequest request) {
        reactionService.react(principal.userId(), transactionId, request.emoji());
        return ApiResponse.ok(null);
    }

    @DeleteMapping("/{transactionId}/reactions")
    public ApiResponse<Void> removeReaction(@CurrentUser AuthPrincipal principal,
                                            @PathVariable UUID transactionId) {
        reactionService.removeReaction(principal.userId(), transactionId);
        return ApiResponse.ok(null);
    }

    @GetMapping("/reactions")
    public ApiResponse<Map<UUID, List<ReactionResponse>>> reactionsByTransaction(
            @CurrentUser AuthPrincipal principal,
            @RequestParam List<UUID> transactionIds) {
        return ApiResponse.ok(reactionService.reactionsByTransaction(principal.userId(), transactionIds));
    }
}
