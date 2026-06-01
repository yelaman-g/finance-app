package com.aifb.platform.finance.category.api.dto;

import com.aifb.platform.finance.category.domain.Category;

import java.util.UUID;

public record CategoryResponse(
        UUID id, String name, String type, String icon, String color,
        boolean system, boolean shared) {

    public static CategoryResponse from(Category c) {
        return new CategoryResponse(
                c.getId(), c.getName(), c.getType().name(),
                c.getIcon(), c.getColor(), c.isSystem(), c.isShared());
    }
}
