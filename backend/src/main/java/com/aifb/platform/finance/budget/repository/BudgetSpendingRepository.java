package com.aifb.platform.finance.budget.repository;

import com.aifb.platform.finance.transaction.domain.Transaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

public interface BudgetSpendingRepository extends JpaRepository<Transaction, UUID> {

    @Query("""
            select coalesce(sum(t.amount), 0) from Transaction t
            where t.categoryId = :categoryId
              and t.type = com.aifb.platform.finance.category.domain.CategoryType.EXPENSE
              and ((:householdId is null and t.userId = :userId and t.householdId is null)
                   or (:householdId is not null and t.householdId = :householdId))
              and t.occurredOn between :from and :to
            """)
    BigDecimal sumExpenseForCategory(@Param("userId") UUID userId,
                                     @Param("householdId") UUID householdId,
                                     @Param("categoryId") UUID categoryId,
                                     @Param("from") LocalDate from,
                                     @Param("to") LocalDate to);

    @Query("""
            select coalesce(sum(t.amount), 0)
            from Transaction t, com.aifb.platform.finance.category.domain.Category c
            where t.categoryId = c.id and c.groupId = :groupId
              and t.type = com.aifb.platform.finance.category.domain.CategoryType.EXPENSE
              and ((:householdId is null and t.userId = :userId and t.householdId is null)
                   or (:householdId is not null and t.householdId = :householdId))
              and t.occurredOn between :from and :to
            """)
    BigDecimal sumExpenseForGroup(@Param("userId") UUID userId,
                                  @Param("householdId") UUID householdId,
                                  @Param("groupId") UUID groupId,
                                  @Param("from") LocalDate from,
                                  @Param("to") LocalDate to);
}
