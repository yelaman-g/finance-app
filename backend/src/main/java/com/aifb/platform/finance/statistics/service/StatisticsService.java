package com.aifb.platform.finance.statistics.service;

import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.finance.category.domain.Category;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.category.repository.CategoryRepository;
import com.aifb.platform.finance.statistics.api.dto.CategoryBreakdownResponse;
import com.aifb.platform.finance.statistics.api.dto.MemberBreakdownResponse;
import com.aifb.platform.finance.statistics.api.dto.SummaryResponse;
import com.aifb.platform.finance.statistics.api.dto.TrendPointResponse;
import com.aifb.platform.finance.transaction.repository.TransactionRepository;
import com.aifb.platform.household.service.HouseholdContextService;
import com.aifb.platform.household.service.HouseholdContextService.HouseholdContext;
import com.aifb.platform.auth.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
public class StatisticsService {

    private final TransactionRepository transactionRepository;
    private final CategoryRepository categoryRepository;
    private final HouseholdContextService householdContext;
    private final UserRepository userRepository;

    public StatisticsService(TransactionRepository transactionRepository,
                             CategoryRepository categoryRepository,
                             HouseholdContextService householdContext,
                             UserRepository userRepository) {
        this.transactionRepository = transactionRepository;
        this.categoryRepository = categoryRepository;
        this.householdContext = householdContext;
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public SummaryResponse summary(UUID userId, LocalDate from, LocalDate to, Scope scope) {
        List<TransactionRepository.TypeTotal> rows;
        if (scope == Scope.FAMILY) {
            HouseholdContext ctx = householdContext.membershipOrNull(userId);
            if (ctx == null) {
                return new SummaryResponse(BigDecimal.ZERO, BigDecimal.ZERO, BigDecimal.ZERO);
            }
            rows = transactionRepository.sumByTypeFamily(ctx.householdId(), from, to);
        } else {
            rows = transactionRepository.sumByType(userId, from, to);
        }
        BigDecimal income = BigDecimal.ZERO;
        BigDecimal expense = BigDecimal.ZERO;
        for (TransactionRepository.TypeTotal row : rows) {
            if (row.getType() == CategoryType.INCOME) {
                income = row.getTotal();
            } else if (row.getType() == CategoryType.EXPENSE) {
                expense = row.getTotal();
            }
        }
        return new SummaryResponse(income, expense, income.subtract(expense));
    }

    @Transactional(readOnly = true)
    public List<CategoryBreakdownResponse> byCategory(UUID userId, CategoryType type,
                                                      LocalDate from, LocalDate to, Scope scope) {
        List<TransactionRepository.CategoryTotal> totals;
        if (scope == Scope.FAMILY) {
            HouseholdContext ctx = householdContext.membershipOrNull(userId);
            if (ctx == null) {
                return List.of();
            }
            totals = transactionRepository.sumByCategoryFamily(ctx.householdId(), type, from, to);
        } else {
            totals = transactionRepository.sumByCategory(userId, type, from, to);
        }
        if (totals.isEmpty()) {
            return List.of();
        }
        BigDecimal grand = totals.stream()
                .map(TransactionRepository.CategoryTotal::getTotal)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        Map<UUID, Category> categories = categoryRepository.findByIdIn(
                        totals.stream().map(TransactionRepository.CategoryTotal::getCategoryId).toList())
                .stream().collect(Collectors.toMap(Category::getId, Function.identity()));

        return totals.stream().map(t -> {
            Category c = categories.get(t.getCategoryId());
            double percentage = grand.signum() == 0 ? 0.0
                    : t.getTotal().multiply(BigDecimal.valueOf(100))
                        .divide(grand, 1, RoundingMode.HALF_UP).doubleValue();
            return new CategoryBreakdownResponse(
                    t.getCategoryId(),
                    c == null ? "—" : c.getName(),
                    c == null ? null : c.getColor(),
                    t.getTotal(),
                    percentage);
        }).toList();
    }

    @Transactional(readOnly = true)
    public List<TrendPointResponse> trend(UUID userId, LocalDate from, LocalDate to, Scope scope) {
        List<TransactionRepository.TrendRow> rows;
        if (scope == Scope.FAMILY) {
            HouseholdContext ctx = householdContext.membershipOrNull(userId);
            if (ctx == null) {
                return List.of();
            }
            rows = transactionRepository.trendFamily(ctx.householdId(), from, to);
        } else {
            rows = transactionRepository.trend(userId, from, to);
        }
        return rows.stream()
                .map(r -> new TrendPointResponse(r.getMonth(), r.getIncome(), r.getExpense()))
                .toList();
    }

    @Transactional(readOnly = true)
    public List<MemberBreakdownResponse> byMember(UUID userId) {
        HouseholdContext ctx = householdContext.membershipOrNull(userId);
        if (ctx == null) {
            return List.of();
        }
        Map<UUID, String> names = userRepository.findByHouseholdId(ctx.householdId())
                .stream().collect(Collectors.toMap(u -> u.getId(), u -> u.getFullName()));
        return transactionRepository.sumByMember(ctx.householdId()).stream()
                .map(m -> new MemberBreakdownResponse(
                        m.getUserId(),
                        names.getOrDefault(m.getUserId(), "—"),
                        m.getIncome(), m.getExpense()))
                .toList();
    }
}
