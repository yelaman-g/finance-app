package com.aifb.platform.household.api;

import com.aifb.platform.common.api.ApiResponse;
import com.aifb.platform.common.security.AuthPrincipal;
import com.aifb.platform.common.security.CurrentUser;
import com.aifb.platform.household.api.dto.CreateHouseholdRequest;
import com.aifb.platform.household.api.dto.HouseholdResponse;
import com.aifb.platform.household.api.dto.JoinHouseholdRequest;
import com.aifb.platform.household.api.dto.UpdateMemberRoleRequest;
import com.aifb.platform.household.service.HouseholdService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/v1/households")
public class HouseholdController {

    private final HouseholdService service;

    public HouseholdController(HouseholdService service) {
        this.service = service;
    }

    @PostMapping
    public ApiResponse<HouseholdResponse> create(
            @CurrentUser AuthPrincipal principal,
            @Valid @RequestBody CreateHouseholdRequest request) {
        return ApiResponse.ok(service.create(principal.userId(), request));
    }

    @GetMapping("/me")
    public ApiResponse<HouseholdResponse> me(@CurrentUser AuthPrincipal principal) {
        return ApiResponse.ok(service.getMine(principal.userId()));
    }

    @PostMapping("/join")
    public ApiResponse<HouseholdResponse> join(
            @CurrentUser AuthPrincipal principal,
            @Valid @RequestBody JoinHouseholdRequest request) {
        return ApiResponse.ok(service.join(principal.userId(), request));
    }

    @PutMapping("/members/{userId}/role")
    public ApiResponse<HouseholdResponse> changeRole(
            @CurrentUser AuthPrincipal principal,
            @PathVariable UUID userId,
            @Valid @RequestBody UpdateMemberRoleRequest request) {
        return ApiResponse.ok(service.changeRole(principal.userId(), userId, request.role()));
    }

    @DeleteMapping("/members/{userId}")
    public ApiResponse<Void> removeMember(
            @CurrentUser AuthPrincipal principal,
            @PathVariable UUID userId) {
        service.removeMember(principal.userId(), userId);
        return ApiResponse.ok(null);
    }

    @PostMapping("/leave")
    public ApiResponse<Void> leave(@CurrentUser AuthPrincipal principal) {
        service.leave(principal.userId());
        return ApiResponse.ok(null);
    }

    @DeleteMapping
    public ApiResponse<Void> disband(@CurrentUser AuthPrincipal principal) {
        service.disband(principal.userId());
        return ApiResponse.ok(null);
    }

    @PostMapping("/rotate-code")
    public ApiResponse<HouseholdResponse> rotateCode(@CurrentUser AuthPrincipal principal) {
        return ApiResponse.ok(service.rotateCode(principal.userId()));
    }
}
