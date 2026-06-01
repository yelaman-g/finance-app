package com.aifb.platform.household.api.dto;

import com.aifb.platform.household.domain.HouseholdRole;
import jakarta.validation.constraints.NotNull;

public record UpdateMemberRoleRequest(@NotNull HouseholdRole role) {
}
