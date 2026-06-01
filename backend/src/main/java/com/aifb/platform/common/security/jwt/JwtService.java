package com.aifb.platform.common.security.jwt;

import com.aifb.platform.common.exception.ErrorCode;
import com.aifb.platform.common.exception.UnauthorizedException;
import com.aifb.platform.common.security.AuthPrincipal;
import io.jsonwebtoken.Claims;
import io.jsonwebtoken.ExpiredJwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.security.Keys;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.time.Instant;
import java.util.Base64;
import java.util.Date;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * Mints and verifies access JWTs (HS512). Claims:
 *  sub  – user id
 *  email
 *  roles[]
 *  ver  – token version (for logout-all)
 *  iss  – configured issuer
 *  exp  – issuedAt + accessTokenTtl
 *
 * The refresh-token side is opaque (random + SHA-256) and lives in
 * the auth module's RefreshTokenService — JWT is only used for access.
 */
@Service
public class JwtService {

    private final JwtProperties props;
    private final SecretKey key;

    public JwtService(JwtProperties props) {
        this.props = props;
        this.key = resolveKey(props.secret());
    }

    public String issueAccessToken(UUID userId, String email, Set<String> roles, int tokenVersion) {
        Instant now = Instant.now();
        return Jwts.builder()
                .issuer(props.issuer())
                .subject(userId.toString())
                .claim("email", email)
                .claim("roles", roles)
                .claim("ver", tokenVersion)
                .issuedAt(Date.from(now))
                .expiration(Date.from(now.plus(props.accessTokenTtl())))
                .signWith(key, Jwts.SIG.HS512)
                .compact();
    }

    public AuthPrincipal verify(String token) {
        try {
            Claims c = Jwts.parser()
                    .verifyWith(key)
                    .requireIssuer(props.issuer())
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();

            UUID userId = UUID.fromString(c.getSubject());
            String email = c.get("email", String.class);
            Object rawRoles = c.get("roles");
            Set<String> roles = rawRoles instanceof List<?> list
                    ? list.stream().map(Object::toString).collect(java.util.stream.Collectors.toUnmodifiableSet())
                    : Set.of();
            Integer ver = c.get("ver", Integer.class);
            return new AuthPrincipal(userId, email, roles, ver == null ? 0 : ver);
        } catch (ExpiredJwtException e) {
            throw new UnauthorizedException(ErrorCode.AUTH_TOKEN_EXPIRED, "Access token expired");
        } catch (JwtException | IllegalArgumentException e) {
            throw new UnauthorizedException(ErrorCode.AUTH_TOKEN_INVALID, "Invalid access token");
        }
    }

    private static SecretKey resolveKey(String secret) {
        // Accept either base64-encoded or raw UTF-8 secret. Must yield ≥64 bytes for HS512.
        byte[] bytes;
        try {
            bytes = Base64.getDecoder().decode(secret);
        } catch (IllegalArgumentException ex) {
            bytes = secret.getBytes(StandardCharsets.UTF_8);
        }
        if (bytes.length < 64) {
            throw new IllegalStateException(
                    "JWT secret too short — provide ≥64 bytes (base64-encoded) for HS512");
        }
        return Keys.hmacShaKeyFor(bytes);
    }
}
