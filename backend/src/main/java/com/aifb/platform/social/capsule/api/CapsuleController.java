package com.aifb.platform.social.capsule.api;

import com.aifb.platform.common.api.ApiResponse;
import com.aifb.platform.common.security.AuthPrincipal;
import com.aifb.platform.common.security.CurrentUser;
import com.aifb.platform.social.capsule.api.dto.CapsuleResponse;
import com.aifb.platform.social.capsule.api.dto.CreateCapsuleRequest;
import com.aifb.platform.social.capsule.service.CapsuleService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/capsules")
public class CapsuleController {

    private final CapsuleService service;

    public CapsuleController(CapsuleService service) {
        this.service = service;
    }

    @GetMapping
    public ApiResponse<List<CapsuleResponse>> list(@CurrentUser AuthPrincipal principal) {
        return ApiResponse.ok(service.list(principal.userId()));
    }

    @PostMapping
    public ApiResponse<CapsuleResponse> create(@CurrentUser AuthPrincipal principal,
                                                @Valid @RequestBody CreateCapsuleRequest request) {
        return ApiResponse.ok(service.create(principal.userId(), request));
    }

    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@CurrentUser AuthPrincipal principal,
                                    @PathVariable UUID id) {
        service.delete(principal.userId(), id);
        return ApiResponse.ok(null);
    }
}
