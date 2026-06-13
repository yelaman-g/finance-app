package com.aifb.platform.ai.advisor;

import com.aifb.platform.auth.domain.UserSettings;
import com.aifb.platform.auth.repository.UserRepository;
import com.aifb.platform.auth.repository.UserSettingsRepository;
import com.aifb.platform.common.domain.Currency;
import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.statistics.service.StatisticsService;
import com.aifb.platform.household.service.HouseholdContextService;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.UUID;

/** Собирает финансовый контекст пользователя для подстановки в промпт Claude. */
@Component
public class FinanceContextBuilder {

    private final StatisticsService statistics;
    private final HouseholdContextService householdContext;
    private final UserRepository userRepository;
    private final UserSettingsRepository userSettingsRepository;

    public FinanceContextBuilder(StatisticsService statistics,
                                 HouseholdContextService householdContext,
                                 UserRepository userRepository,
                                 UserSettingsRepository userSettingsRepository) {
        this.statistics = statistics;
        this.householdContext = householdContext;
        this.userRepository = userRepository;
        this.userSettingsRepository = userSettingsRepository;
    }

    /** requested == null → эффективный scope: FAMILY если есть семья, иначе PERSONAL. */
    @Transactional(readOnly = true)
    public FinanceContext build(UUID userId, Scope requested) {
        Scope scope = resolveScope(userId, requested);
        LocalDate today = LocalDate.now();
        LocalDate curStart = today.withDayOfMonth(1);
        LocalDate prevStart = curStart.minusMonths(1);
        LocalDate prevEnd = curStart.minusDays(1);
        LocalDate trendStart = curStart.minusMonths(5);

        return new FinanceContext(
                currencyOf(userId),
                scope,
                statistics.summary(userId, curStart, today, scope),
                statistics.summary(userId, prevStart, prevEnd, scope),
                statistics.byCategory(userId, CategoryType.EXPENSE, curStart, today, scope),
                statistics.trend(userId, trendStart, today, scope));
    }

    public Scope resolveScope(UUID userId, Scope requested) {
        if (requested != null) {
            return requested;
        }
        return householdContext.membershipOrNull(userId) != null ? Scope.FAMILY : Scope.PERSONAL;
    }

    private Currency currencyOf(UUID userId) {
        return userRepository.findById(userId)
                .flatMap(userSettingsRepository::findByUser)
                .map(UserSettings::getCurrency)
                .orElse(Currency.KZT);
    }
}
