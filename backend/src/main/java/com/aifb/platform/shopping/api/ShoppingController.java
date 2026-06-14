package com.aifb.platform.shopping.api;

import com.aifb.platform.common.api.ApiResponse;
import com.aifb.platform.common.security.AuthPrincipal;
import com.aifb.platform.common.security.CurrentUser;
import com.aifb.platform.shopping.api.dto.AddShoppingItemRequest;
import com.aifb.platform.shopping.api.dto.ShoppingItemResponse;
import com.aifb.platform.shopping.service.ShoppingService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/shopping")
public class ShoppingController {

    private final ShoppingService service;

    public ShoppingController(ShoppingService service) {
        this.service = service;
    }

    @GetMapping
    public ApiResponse<List<ShoppingItemResponse>> list(@CurrentUser AuthPrincipal principal) {
        return ApiResponse.ok(service.list(principal.userId()));
    }

    @PostMapping
    public ApiResponse<ShoppingItemResponse> add(@CurrentUser AuthPrincipal principal,
                                                  @Valid @RequestBody AddShoppingItemRequest request) {
        return ApiResponse.ok(service.add(principal.userId(), request.title()));
    }

    @PostMapping("/{id}/toggle")
    public ApiResponse<ShoppingItemResponse> toggle(@CurrentUser AuthPrincipal principal,
                                                     @PathVariable UUID id) {
        return ApiResponse.ok(service.toggle(principal.userId(), id));
    }

    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@CurrentUser AuthPrincipal principal,
                                    @PathVariable UUID id) {
        service.delete(principal.userId(), id);
        return ApiResponse.ok(null);
    }
}
