package com.aifb.platform.finance.group.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record UpdateGroupRequest(
        @NotBlank @Size(max = 80) String name,
        @Size(max = 40) String icon,
        @Size(max = 9) String color) {
}
