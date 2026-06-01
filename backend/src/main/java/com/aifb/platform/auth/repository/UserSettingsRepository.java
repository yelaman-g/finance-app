package com.aifb.platform.auth.repository;

import com.aifb.platform.auth.domain.User;
import com.aifb.platform.auth.domain.UserSettings;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface UserSettingsRepository extends JpaRepository<UserSettings, UUID> {
    Optional<UserSettings> findByUser(User user);
}
