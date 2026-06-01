package com.aifb.platform.household.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record CreateHouseholdRequest(@NotBlank @Size(max = 120) String name) {
}
