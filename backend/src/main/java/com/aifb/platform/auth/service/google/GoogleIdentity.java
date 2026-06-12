package com.aifb.platform.auth.service.google;

public record GoogleIdentity(
        String subject,
        String email,
        boolean emailVerified,
        String fullName,
        String pictureUrl) {
}
