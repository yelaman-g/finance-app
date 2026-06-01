package com.aifb.platform.auth.service;

import com.aifb.platform.auth.api.dto.AuthResponse;
import com.aifb.platform.auth.api.dto.LoginRequest;
import com.aifb.platform.auth.api.dto.RegisterRequest;
import com.aifb.platform.auth.api.dto.TokenResponse;
import com.aifb.platform.auth.api.dto.UserResponse;
import com.aifb.platform.auth.domain.Role;
import com.aifb.platform.auth.domain.User;
import com.aifb.platform.auth.repository.UserRepository;
import com.aifb.platform.common.exception.ConflictException;
import com.aifb.platform.common.exception.ErrorCode;
import com.aifb.platform.common.exception.NotFoundException;
import com.aifb.platform.common.exception.UnauthorizedException;
import com.aifb.platform.common.security.jwt.JwtService;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Locale;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final RefreshTokenService refreshTokenService;

    public AuthService(UserRepository userRepository,
                       PasswordEncoder passwordEncoder,
                       JwtService jwtService,
                       RefreshTokenService refreshTokenService) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.refreshTokenService = refreshTokenService;
    }

    @Transactional
    public AuthResponse register(RegisterRequest request) {
        String email = normalizeEmail(request.email());
        if (userRepository.existsByEmailIgnoreCase(email)) {
            throw new ConflictException(ErrorCode.AUTH_EMAIL_TAKEN, "Email is already registered");
        }

        User user = new User(
                email,
                request.fullName().trim(),
                passwordEncoder.encode(request.password()),
                Set.of(Role.USER));
        user.markLoggedIn();
        userRepository.save(user);
        return issueSession(user);
    }

    @Transactional
    public AuthResponse login(LoginRequest request) {
        User user = userRepository.findByEmailIgnoreCase(normalizeEmail(request.email()))
                .orElseThrow(() -> invalidCredentials());
        if (!user.isEnabled()) {
            throw new UnauthorizedException(ErrorCode.AUTH_USER_BLOCKED, "User account is blocked");
        }
        if (!passwordEncoder.matches(request.password(), user.getPasswordHash())) {
            throw invalidCredentials();
        }
        user.markLoggedIn();
        return issueSession(user);
    }

    @Transactional
    public AuthResponse refresh(String refreshToken) {
        RefreshTokenService.RotationResult result = refreshTokenService.rotate(refreshToken);
        User user = result.user();
        return new AuthResponse(
                UserResponse.from(user),
                new TokenResponse(accessToken(user), result.refreshToken()));
    }

    @Transactional(readOnly = true)
    public UserResponse me(UUID userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new NotFoundException("User not found"));
        return UserResponse.from(user);
    }

    @Transactional
    public void logout(String refreshToken) {
        refreshTokenService.revoke(refreshToken);
    }

    @Transactional
    public void logoutAll(UUID userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new NotFoundException("User not found"));
        user.incrementTokenVersion();
        refreshTokenService.revokeAll(user);
    }

    private AuthResponse issueSession(User user) {
        RefreshTokenService.IssuedRefreshToken refresh = refreshTokenService.issue(user);
        return new AuthResponse(
                UserResponse.from(user),
                new TokenResponse(accessToken(user), refresh.rawToken()));
    }

    private String accessToken(User user) {
        Set<String> roles = user.getRoles().stream()
                .map(Role::name)
                .collect(Collectors.toUnmodifiableSet());
        return jwtService.issueAccessToken(user.getId(), user.getEmail(), roles, user.getTokenVersion());
    }

    private static String normalizeEmail(String email) {
        return email.trim().toLowerCase(Locale.ROOT);
    }

    private static UnauthorizedException invalidCredentials() {
        return new UnauthorizedException(
                ErrorCode.AUTH_INVALID_CREDENTIALS,
                "Invalid email or password");
    }
}
