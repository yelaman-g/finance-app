package com.aifb.platform.auth.service;

import com.aifb.platform.auth.domain.RefreshToken;
import com.aifb.platform.auth.domain.User;
import com.aifb.platform.auth.repository.RefreshTokenRepository;
import com.aifb.platform.common.exception.ErrorCode;
import com.aifb.platform.common.exception.UnauthorizedException;
import com.aifb.platform.common.security.jwt.JwtProperties;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.Base64;
import java.util.HexFormat;

@Service
public class RefreshTokenService {

    private static final int TOKEN_BYTES = 64;

    private final RefreshTokenRepository refreshTokenRepository;
    private final JwtProperties jwtProperties;
    private final SecureRandom secureRandom = new SecureRandom();

    public RefreshTokenService(RefreshTokenRepository refreshTokenRepository, JwtProperties jwtProperties) {
        this.refreshTokenRepository = refreshTokenRepository;
        this.jwtProperties = jwtProperties;
    }

    @Transactional
    public IssuedRefreshToken issue(User user) {
        String raw = generateToken();
        RefreshToken entity = new RefreshToken(
                user,
                hash(raw),
                Instant.now().plus(jwtProperties.refreshTokenTtl()));
        refreshTokenRepository.save(entity);
        return new IssuedRefreshToken(raw, entity);
    }

    @Transactional
    public RotationResult rotate(String rawToken) {
        RefreshToken current = refreshTokenRepository.findByTokenHash(hash(rawToken))
                .orElseThrow(() -> new UnauthorizedException(
                        ErrorCode.AUTH_REFRESH_INVALID,
                        "Недействительный токен обновления"));

        User user = current.getUser();
        if (current.isRevoked()) {
            revokeAll(user);
            throw new UnauthorizedException(
                    ErrorCode.AUTH_REFRESH_REUSE_DETECTED,
                    "Повторное использование токена обновления");
        }
        if (current.isExpired()) {
            current.revoke();
            throw new UnauthorizedException(
                    ErrorCode.AUTH_REFRESH_INVALID,
                    "Refresh token expired");
        }

        IssuedRefreshToken next = issue(user);
        current.revoke(next.entity().getId());
        return new RotationResult(user, next.rawToken());
    }

    @Transactional
    public void revoke(String rawToken) {
        refreshTokenRepository.findByTokenHash(hash(rawToken))
                .ifPresent(RefreshToken::revoke);
    }

    @Transactional
    public void revokeAll(User user) {
        refreshTokenRepository.revokeAllActiveByUser(user, Instant.now());
    }

    private String generateToken() {
        byte[] bytes = new byte[TOKEN_BYTES];
        secureRandom.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    public String hash(String rawToken) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hashed = digest.digest(rawToken.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(hashed);
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 digest unavailable", e);
        }
    }

    public record IssuedRefreshToken(String rawToken, RefreshToken entity) {
    }

    public record RotationResult(User user, String refreshToken) {
    }
}
