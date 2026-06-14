package com.aifb.platform.social.feed.api;

import com.aifb.platform.common.api.ApiResponse;
import com.aifb.platform.common.security.AuthPrincipal;
import com.aifb.platform.common.security.CurrentUser;
import com.aifb.platform.social.feed.api.dto.CreateMomentRequest;
import com.aifb.platform.social.feed.api.dto.MomentResponse;
import com.aifb.platform.social.feed.service.FeedService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/feed")
public class FeedController {

    private final FeedService feedService;

    public FeedController(FeedService feedService) {
        this.feedService = feedService;
    }

    @GetMapping
    public ApiResponse<List<MomentResponse>> list(@CurrentUser AuthPrincipal principal) {
        return ApiResponse.ok(feedService.list(principal.userId()));
    }

    @PostMapping
    public ApiResponse<MomentResponse> post(@CurrentUser AuthPrincipal principal,
                                             @Valid @RequestBody CreateMomentRequest request) {
        return ApiResponse.ok(feedService.post(principal.userId(), request));
    }

    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@CurrentUser AuthPrincipal principal,
                                    @PathVariable UUID id) {
        feedService.delete(principal.userId(), id);
        return ApiResponse.ok(null);
    }

    @PostMapping("/{id}/like")
    public ApiResponse<Void> like(@CurrentUser AuthPrincipal principal,
                                   @PathVariable UUID id) {
        feedService.like(principal.userId(), id);
        return ApiResponse.ok(null);
    }

    @DeleteMapping("/{id}/like")
    public ApiResponse<Void> unlike(@CurrentUser AuthPrincipal principal,
                                     @PathVariable UUID id) {
        feedService.unlike(principal.userId(), id);
        return ApiResponse.ok(null);
    }
}
