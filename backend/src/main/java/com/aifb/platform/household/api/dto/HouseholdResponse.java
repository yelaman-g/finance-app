package com.aifb.platform.household.api.dto;

import java.util.List;
import java.util.UUID;

public record HouseholdResponse(
        UUID id,
        String name,
        String inviteCode,
        String myRole,
        List<MemberResponse> members) {
}
