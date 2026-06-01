package com.aifb.platform.finance.statistics.service;

import com.aifb.platform.finance.category.domain.Category;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.category.repository.CategoryRepository;
import com.aifb.platform.finance.statistics.api.dto.CategoryBreakdownResponse;
import com.aifb.platform.finance.statistics.api.dto.SummaryResponse;
import com.aifb.platform.finance.statistics.api.dto.TrendPointResponse;
import com.aifb.platform.finance.transaction.repository.TransactionRepository;
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

    public StatisticsService(TransactionRepository transactionRepository,
                             CategoryRepository categoryRepository) {
        this.transactionRepository = transactionRepository;
        this.categoryRepository = categoryRepository;
    }

    @Transactional(readOnly = true)
    public SummaryResponse summary(UUID userId, LocalDate from, LocalDate to) {
        BigDecimal income = BigDecimal.ZERO;
        BigDecimal expense = BigDecimal.ZERO;
        for (TransactionRepository.TypeTotal row : transactionRepository.sumByType(userId, from, to)) {
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
                                                      LocalDate from, LocalDate to) {
        List<TransactionRepository.CategoryTotal> totals =
                transactionRepository.sumByCategory(userId, type, from, to);
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
    public List<TrendPointResponse> trend(UUID userId, LocalDate from, LocalDate to) {
        return transactionRepository.trend(userId, from, to).stream()
                .map(r -> new TrendPointResponse(r.getMonth(), r.getIncome(), r.getExpense()))
                .toList();
    }
}
