package com.aifb.platform.finance.budget.repository;

import com.aifb.platform.finance.budget.domain.BudgetLimit;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface BudgetLimitRepository extends JpaRepository<BudgetLimit, UUID> {
    List<BudgetLimit> findByUserIdAndHouseholdIdIsNull(UUID userId);
    List<BudgetLimit> findByHouseholdId(UUID householdId);
    Optional<BudgetLimit> findByCategoryId(UUID categoryId);
    Optional<BudgetLimit> findByGroupId(UUID groupId);
}
