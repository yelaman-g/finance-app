package com.aifb.platform.household.api.dto;

import com.aifb.platform.auth.domain.User;

import java.util.UUID;

public record MemberResponse(UUID userId, String fullName, String role) {
    public static MemberResponse from(User u) {
        return new MemberResponse(
                u.getId(),
                u.getFullName(),
                u.getHouseholdRole() == null ? null : u.getHouseholdRole().name());
    }
}
