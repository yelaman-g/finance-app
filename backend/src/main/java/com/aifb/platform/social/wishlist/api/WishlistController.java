package com.aifb.platform.social.wishlist.api;

import com.aifb.platform.common.api.ApiResponse;
import com.aifb.platform.common.security.AuthPrincipal;
import com.aifb.platform.common.security.CurrentUser;
import com.aifb.platform.social.wishlist.api.dto.AddWishlistItemRequest;
import com.aifb.platform.social.wishlist.api.dto.WishlistItemResponse;
import com.aifb.platform.social.wishlist.service.WishlistService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/wishlist")
public class WishlistController {

    private final WishlistService service;

    public WishlistController(WishlistService service) {
        this.service = service;
    }

    @GetMapping
    public ApiResponse<List<WishlistItemResponse>> list(@CurrentUser AuthPrincipal principal) {
        return ApiResponse.ok(service.list(principal.userId()));
    }

    @PostMapping
    public ApiResponse<WishlistItemResponse> add(@CurrentUser AuthPrincipal principal,
                                                  @Valid @RequestBody AddWishlistItemRequest request) {
        return ApiResponse.ok(service.add(principal.userId(), request));
    }

    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@CurrentUser AuthPrincipal principal,
                                    @PathVariable UUID id) {
        service.delete(principal.userId(), id);
        return ApiResponse.ok(null);
    }

    @PostMapping("/{id}/reserve")
    public ApiResponse<WishlistItemResponse> reserve(@CurrentUser AuthPrincipal principal,
                                                      @PathVariable UUID id) {
        return ApiResponse.ok(service.reserve(principal.userId(), id));
    }

    @DeleteMapping("/{id}/reserve")
    public ApiResponse<WishlistItemResponse> unreserve(@CurrentUser AuthPrincipal principal,
                                                        @PathVariable UUID id) {
        return ApiResponse.ok(service.unreserve(principal.userId(), id));
    }
}
