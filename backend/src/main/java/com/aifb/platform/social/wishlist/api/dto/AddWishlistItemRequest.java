package com.aifb.platform.social.wishlist.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record AddWishlistItemRequest(
        @NotBlank @Size(max = 200) String title,
        @Size(max = 500) String note
) {
}
