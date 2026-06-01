package com.aifb.platform.auth.api.dto;

import com.aifb.platform.auth.domain.UserSettings;
import com.aifb.platform.common.domain.ExchangeRate;

public record UserSettingsResponse(
        String currency,
        String theme,
        String currencySymbol) {

    public static UserSettingsResponse from(UserSettings s) {
        return new UserSettingsResponse(
                s.getCurrency().name(),
                s.getTheme(),
                ExchangeRate.symbol(s.getCurrency()));
    }
}
