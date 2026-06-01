package com.aifb.platform.auth.service;

import com.aifb.platform.auth.api.dto.UserSettingsResponse;
import com.aifb.platform.auth.domain.User;
import com.aifb.platform.auth.domain.UserSettings;
import com.aifb.platform.auth.repository.UserSettingsRepository;
import com.aifb.platform.common.domain.Currency;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserSettingsService {

    private final UserSettingsRepository repository;

    public UserSettingsService(UserSettingsRepository repository) {
        this.repository = repository;
    }

    @Transactional(readOnly = true)
    public UserSettingsResponse get(User user) {
        UserSettings settings = repository.findByUser(user)
                .orElseGet(() -> createDefault(user));
        return UserSettingsResponse.from(settings);
    }

    @Transactional
    public UserSettingsResponse updateCurrency(User user, Currency currency) {
        UserSettings settings = repository.findByUser(user)
                .orElseGet(() -> createDefault(user));
        settings.setCurrency(currency);
        repository.save(settings);
        return UserSettingsResponse.from(settings);
    }

    @Transactional
    public UserSettingsResponse updateTheme(User user, String theme) {
        UserSettings settings = repository.findByUser(user)
                .orElseGet(() -> createDefault(user));
        settings.setTheme(theme);
        repository.save(settings);
        return UserSettingsResponse.from(settings);
    }

    private UserSettings createDefault(User user) {
        UserSettings settings = new UserSettings(user);
        return repository.save(settings);
    }
}
