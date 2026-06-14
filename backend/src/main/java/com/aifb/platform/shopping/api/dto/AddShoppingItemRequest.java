package com.aifb.platform.shopping.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record AddShoppingItemRequest(
        @NotBlank @Size(max = 200) String title
) {
}
