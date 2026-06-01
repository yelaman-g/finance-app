package com.aifb.platform.finance.transaction.repository;

import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.transaction.domain.Transaction;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface TransactionRepository extends JpaRepository<Transaction, UUID> {

    @Query("""
            select t from Transaction t
            where t.userId = :userId and t.householdId is null
              and (:from is null or t.occurredOn >= :from)
              and (:to is null or t.occurredOn <= :to)
              and (:type is null or t.type = :type)
              and (:categoryId is null or t.categoryId = :categoryId)
            """)
    Page<Transaction> search(@Param("userId") UUID userId,
                             @Param("from") LocalDate from,
                             @Param("to") LocalDate to,
                             @Param("type") CategoryType type,
                             @Param("categoryId") UUID categoryId,
                             Pageable pageable);

    @Query("""
            select t from Transaction t
            where t.householdId = :householdId
              and (:from is null or t.occurredOn >= :from)
              and (:to is null or t.occurredOn <= :to)
              and (:type is null or t.type = :type)
              and (:categoryId is null or t.categoryId = :categoryId)
            """)
    Page<Transaction> searchFamily(@Param("householdId") UUID householdId,
                                   @Param("from") LocalDate from,
                                   @Param("to") LocalDate to,
                                   @Param("type") CategoryType type,
                                   @Param("categoryId") UUID categoryId,
                                   Pageable pageable);

    Optional<Transaction> findByIdAndUserId(UUID id, UUID userId);

    boolean existsByCategoryId(UUID categoryId);

    interface TypeTotal {
        CategoryType getType();
        BigDecimal getTotal();
    }

    interface CategoryTotal {
        UUID getCategoryId();
        BigDecimal getTotal();
    }

    interface TrendRow {
        String getMonth();
        BigDecimal getIncome();
        BigDecimal getExpense();
    }

    @Query("""
            select t.type as type, coalesce(sum(t.amount), 0) as total
            from Transaction t
            where t.userId = :userId
              and t.householdId is null
              and (:from is null or t.occurredOn >= :from)
              and (:to is null or t.occurredOn <= :to)
            group by t.type
            """)
    List<TypeTotal> sumByType(@Param("userId") UUID userId,
                              @Param("from") LocalDate from,
                              @Param("to") LocalDate to);

    @Query("""
            select t.categoryId as categoryId, coalesce(sum(t.amount), 0) as total
            from Transaction t
            where t.userId = :userId
              and t.householdId is null
              and t.type = :type
              and (:from is null or t.occurredOn >= :from)
              and (:to is null or t.occurredOn <= :to)
            group by t.categoryId
            order by total desc
            """)
    List<CategoryTotal> sumByCategory(@Param("userId") UUID userId,
                                      @Param("type") CategoryType type,
                                      @Param("from") LocalDate from,
                                      @Param("to") LocalDate to);

    @Query(value = """
            select to_char(occurred_on, 'YYYY-MM') as month,
                   coalesce(sum(amount) filter (where type = 'INCOME'), 0) as income,
                   coalesce(sum(amount) filter (where type = 'EXPENSE'), 0) as expense
            from transactions
            where user_id = :userId
              and household_id is null
              and (cast(:from as date) is null or occurred_on >= :from)
              and (cast(:to as date) is null or occurred_on <= :to)
            group by 1
            order by 1
            """, nativeQuery = true)
    List<TrendRow> trend(@Param("userId") UUID userId,
                         @Param("from") LocalDate from,
                         @Param("to") LocalDate to);

    @Query("""
            select t.type as type, coalesce(sum(t.amount), 0) as total
            from Transaction t
            where t.householdId = :householdId
              and (:from is null or t.occurredOn >= :from)
              and (:to is null or t.occurredOn <= :to)
            group by t.type
            """)
    List<TypeTotal> sumByTypeFamily(@Param("householdId") UUID householdId,
                                    @Param("from") LocalDate from, @Param("to") LocalDate to);

    @Query("""
            select t.categoryId as categoryId, coalesce(sum(t.amount), 0) as total
            from Transaction t
            where t.householdId = :householdId and t.type = :type
              and (:from is null or t.occurredOn >= :from)
              and (:to is null or t.occurredOn <= :to)
            group by t.categoryId order by total desc
            """)
    List<CategoryTotal> sumByCategoryFamily(@Param("householdId") UUID householdId,
                                            @Param("type") CategoryType type,
                                            @Param("from") LocalDate from, @Param("to") LocalDate to);

    @Query(value = """
            select to_char(occurred_on, 'YYYY-MM') as month,
                   coalesce(sum(amount) filter (where type = 'INCOME'), 0) as income,
                   coalesce(sum(amount) filter (where type = 'EXPENSE'), 0) as expense
            from transactions
            where household_id = :householdId
              and (cast(:from as date) is null or occurred_on >= :from)
              and (cast(:to as date) is null or occurred_on <= :to)
            group by 1 order by 1
            """, nativeQuery = true)
    List<TrendRow> trendFamily(@Param("householdId") UUID householdId,
                               @Param("from") LocalDate from, @Param("to") LocalDate to);

    interface MemberTotal {
        UUID getUserId();
        BigDecimal getIncome();
        BigDecimal getExpense();
    }

    @Query("""
            select t.userId as userId,
                   coalesce(sum(case when t.type = com.aifb.platform.finance.category.domain.CategoryType.INCOME then t.amount else 0 end), 0) as income,
                   coalesce(sum(case when t.type = com.aifb.platform.finance.category.domain.CategoryType.EXPENSE then t.amount else 0 end), 0) as expense
            from Transaction t
            where t.householdId = :householdId
            group by t.userId
            """)
    List<MemberTotal> sumByMember(@Param("householdId") UUID householdId);
}
