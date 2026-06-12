package com.aifb.platform.auth.service.google;

public record GoogleIdentity(
        /** Google user id (JWT {@code sub} claim) — stable external identity key. */
        String subject,
        String email,
        boolean emailVerified,
        String fullName,
        String pictureUrl) {
}
