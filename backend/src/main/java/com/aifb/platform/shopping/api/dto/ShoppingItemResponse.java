package com.aifb.platform.shopping.api.dto;

import com.aifb.platform.shopping.domain.ShoppingItem;

import java.util.UUID;

public record ShoppingItemResponse(
        UUID id,
        String title,
        boolean checked,
        UUID createdBy
) {
    public static ShoppingItemResponse from(ShoppingItem item) {
        return new ShoppingItemResponse(
                item.getId(),
                item.getTitle(),
                item.isChecked(),
                item.getCreatedBy()
        );
    }
}
