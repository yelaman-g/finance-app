package com.aifb.platform.social.poll.api;

import com.aifb.platform.common.api.ApiResponse;
import com.aifb.platform.common.security.AuthPrincipal;
import com.aifb.platform.common.security.CurrentUser;
import com.aifb.platform.social.poll.api.dto.CreatePollRequest;
import com.aifb.platform.social.poll.api.dto.PollResponse;
import com.aifb.platform.social.poll.api.dto.VoteRequest;
import com.aifb.platform.social.poll.service.PollService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/polls")
public class PollController {

    private final PollService pollService;

    public PollController(PollService pollService) {
        this.pollService = pollService;
    }

    @GetMapping
    public ApiResponse<List<PollResponse>> list(@CurrentUser AuthPrincipal principal) {
        return ApiResponse.ok(pollService.list(principal.userId()));
    }

    @PostMapping
    public ApiResponse<PollResponse> create(@CurrentUser AuthPrincipal principal,
                                             @Valid @RequestBody CreatePollRequest request) {
        return ApiResponse.ok(pollService.create(principal.userId(), request));
    }

    @PostMapping("/{id}/vote")
    public ApiResponse<Void> vote(@CurrentUser AuthPrincipal principal,
                                   @PathVariable UUID id,
                                   @Valid @RequestBody VoteRequest request) {
        pollService.vote(principal.userId(), id, request.optionId());
        return ApiResponse.ok(null);
    }

    @PostMapping("/{id}/close")
    public ApiResponse<PollResponse> close(@CurrentUser AuthPrincipal principal,
                                            @PathVariable UUID id) {
        return ApiResponse.ok(pollService.close(principal.userId(), id));
    }
}
