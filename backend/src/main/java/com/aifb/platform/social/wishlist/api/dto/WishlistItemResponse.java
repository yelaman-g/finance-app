package com.aifb.platform.social.wishlist.api.dto;

import com.aifb.platform.social.wishlist.domain.WishlistItem;

import java.util.UUID;

public record WishlistItemResponse(
        UUID id,
        UUID ownerId,
        String ownerName,
        String title,
        String note,
        boolean reserved,
        UUID reservedBy
) {
    public static WishlistItemResponse from(WishlistItem item, String ownerName) {
        return new WishlistItemResponse(
                item.getId(),
                item.getUserId(),
                ownerName,
                item.getTitle(),
                item.getNote(),
                item.getReservedBy() != null,
                item.getReservedBy()
        );
    }
}
