package com.aifb.platform.auth.repository;

import com.aifb.platform.auth.domain.PasswordResetCode;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.Optional;
import java.util.UUID;

public interface PasswordResetCodeRepository extends JpaRepository<PasswordResetCode, UUID> {

    Optional<PasswordResetCode> findFirstByUserIdAndUsedAtIsNullOrderByCreatedAtDesc(UUID userId);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("update PasswordResetCode c set c.usedAt = :now "
            + "where c.userId = :userId and c.usedAt is null")
    int markAllActiveUsed(@Param("userId") UUID userId, @Param("now") Instant now);
}
