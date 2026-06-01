package com.aifb.platform.household.api.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record JoinHouseholdRequest(@NotBlank @Size(max = 12) String inviteCode) {
}
