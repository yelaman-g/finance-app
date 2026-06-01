package com.aifb.platform.auth.api.dto;

import com.aifb.platform.auth.domain.Role;
import com.aifb.platform.auth.domain.User;

import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

public record UserResponse(
        UUID id,
        String email,
        String fullName,
        boolean emailVerified,
        String avatarUrl,
        Set<String> roles) {

    public static UserResponse from(User user) {
        return new UserResponse(
                user.getId(),
                user.getEmail(),
                user.getFullName(),
                user.isEmailVerified(),
                user.getAvatarUrl(),
                user.getRoles().stream().map(Role::name).collect(Collectors.toUnmodifiableSet()));
    }
}
