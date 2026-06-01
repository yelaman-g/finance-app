package com.aifb.platform.finance.budget.repository;

import com.aifb.platform.finance.budget.domain.BudgetLimit;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface BudgetLimitRepository extends JpaRepository<BudgetLimit, UUID> {
    List<BudgetLimit> findByUserIdAndHouseholdIdIsNull(UUID userId);
    List<BudgetLimit> findByHouseholdId(UUID householdId);

    // Scoped duplicate-check: personal budget (no household)
    Optional<BudgetLimit> findByCategoryIdAndUserIdAndHouseholdIdIsNull(UUID categoryId, UUID userId);
    Optional<BudgetLimit> findByGroupIdAndUserIdAndHouseholdIdIsNull(UUID groupId, UUID userId);

    // Scoped duplicate-check: household budget
    Optional<BudgetLimit> findByCategoryIdAndHouseholdId(UUID categoryId, UUID householdId);
    Optional<BudgetLimit> findByGroupIdAndHouseholdId(UUID groupId, UUID householdId);

    // Lookup by target for warnings (no scope filter — caller filters by scope)
    Optional<BudgetLimit> findByCategoryId(UUID categoryId);
    Optional<BudgetLimit> findByGroupId(UUID groupId);
}
