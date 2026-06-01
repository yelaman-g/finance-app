package com.aifb.platform.common.security;

import java.util.Set;
import java.util.UUID;

/**
 * Lightweight authenticated principal stored in the SecurityContext.
 * Built from validated JWT claims by {@code JwtAuthenticationFilter}.
 */
public record AuthPrincipal(
        UUID userId,
        String email,
        Set<String> roles,
        int tokenVersion) {
}
