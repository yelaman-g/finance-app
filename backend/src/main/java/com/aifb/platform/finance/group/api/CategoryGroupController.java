package com.aifb.platform.finance.group.api;

import com.aifb.platform.common.api.ApiResponse;
import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.common.security.AuthPrincipal;
import com.aifb.platform.common.security.CurrentUser;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.group.api.dto.CreateGroupRequest;
import com.aifb.platform.finance.group.api.dto.GroupResponse;
import com.aifb.platform.finance.group.api.dto.UpdateGroupRequest;
import com.aifb.platform.finance.group.service.CategoryGroupService;
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
@RequestMapping("/api/v1/groups")
public class CategoryGroupController {

    private final CategoryGroupService service;

    public CategoryGroupController(CategoryGroupService service) {
        this.service = service;
    }

    @GetMapping
    public ApiResponse<List<GroupResponse>> list(
            @CurrentUser AuthPrincipal principal,
            @RequestParam(required = false) CategoryType type,
            @RequestParam(defaultValue = "PERSONAL") Scope scope) {
        return ApiResponse.ok(service.list(principal.userId(), type, scope));
    }

    @PostMapping
    public ApiResponse<GroupResponse> create(
            @CurrentUser AuthPrincipal principal,
            @Valid @RequestBody CreateGroupRequest request) {
        return ApiResponse.ok(service.create(principal.userId(), request));
    }

    @PutMapping("/{id}")
    public ApiResponse<GroupResponse> update(
            @CurrentUser AuthPrincipal principal,
            @PathVariable UUID id,
            @Valid @RequestBody UpdateGroupRequest request) {
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
