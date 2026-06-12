package com.aifb.platform.auth.service;

import com.aifb.platform.auth.api.dto.ForgotPasswordResponse;
import com.aifb.platform.auth.domain.PasswordResetCode;
import com.aifb.platform.auth.domain.User;
import com.aifb.platform.auth.repository.PasswordResetCodeRepository;
import com.aifb.platform.auth.repository.UserRepository;
import com.aifb.platform.common.exception.DomainException;
import com.aifb.platform.common.exception.ErrorCode;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.Duration;
import java.time.Instant;
import java.util.Locale;
import java.util.Optional;

@Service
public class PasswordResetService {

    private final UserRepository userRepository;
    private final PasswordResetCodeRepository codeRepository;
    private final PasswordEncoder passwordEncoder;
    private final RefreshTokenService refreshTokenService;
    private final Duration resetTtl;
    private final SecureRandom random = new SecureRandom();

    public PasswordResetService(UserRepository userRepository,
                                PasswordResetCodeRepository codeRepository,
                                PasswordEncoder passwordEncoder,
                                RefreshTokenService refreshTokenService,
                                @Value("${aifb.verification.password-reset-ttl}") Duration resetTtl) {
        this.userRepository = userRepository;
        this.codeRepository = codeRepository;
        this.passwordEncoder = passwordEncoder;
        this.refreshTokenService = refreshTokenService;
        this.resetTtl = resetTtl;
    }

    @Transactional
    public ForgotPasswordResponse forgotPassword(String rawEmail) {
        Optional<User> userOpt = userRepository.findByEmailIgnoreCase(normalize(rawEmail));
        if (userOpt.isEmpty()) {
            return new ForgotPasswordResponse(null, null);
        }
        User user = userOpt.get();
        if (user.getPasswordHash() == null) {
            // Google-only аккаунт: локального пароля нет, сброс не применим —
            // отвечаем как для неизвестного email (без выдачи кода).
            return new ForgotPasswordResponse(null, null);
        }
        Instant now = Instant.now();
        codeRepository.markAllActiveUsed(user.getId(), now);
        String code = String.format("%06d", random.nextInt(1_000_000));
        Instant expiresAt = now.plus(resetTtl);
        codeRepository.save(new PasswordResetCode(
                user.getId(), passwordEncoder.encode(code), expiresAt, now));
        return new ForgotPasswordResponse(code, expiresAt);
    }

    @Transactional
    public void reset(String rawEmail, String code, String newPassword) {
        User user = userRepository.findByEmailIgnoreCase(normalize(rawEmail))
                .orElseThrow(this::invalidCode);
        PasswordResetCode entity = codeRepository
                .findFirstByUserIdAndUsedAtIsNullOrderByCreatedAtDesc(user.getId())
                .orElseThrow(this::invalidCode);
        Instant now = Instant.now();
        if (now.isAfter(entity.getExpiresAt()) || !passwordEncoder.matches(code, entity.getCodeHash())) {
            throw invalidCode();
        }
        user.changePassword(passwordEncoder.encode(newPassword));
        user.incrementTokenVersion();
        refreshTokenService.revokeAll(user);
        entity.markUsed(now);
        // re-save: revokeAll выполняет @Modifying(clearAutomatically=true) и
        // отвязывает эту сущность, поэтому usedAt не сохранится через dirty-checking.
        codeRepository.save(entity);
    }

    private static String normalize(String email) {
        return email.trim().toLowerCase(Locale.ROOT);
    }

    private DomainException invalidCode() {
        return new DomainException(ErrorCode.AUTH_RESET_CODE_INVALID, "Invalid or expired reset code");
    }
}
