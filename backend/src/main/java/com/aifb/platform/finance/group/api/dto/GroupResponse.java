package com.aifb.platform.finance.group.api.dto;

import com.aifb.platform.finance.group.domain.CategoryGroup;

import java.util.UUID;

public record GroupResponse(
        UUID id, String name, String type, String icon, String color, boolean shared) {

    public static GroupResponse from(CategoryGroup g) {
        return new GroupResponse(g.getId(), g.getName(), g.getType().name(),
                g.getIcon(), g.getColor(), g.isShared());
    }
}
