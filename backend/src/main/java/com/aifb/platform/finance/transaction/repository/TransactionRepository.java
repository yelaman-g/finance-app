package com.aifb.platform.finance.transaction.repository;

import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.transaction.domain.Transaction;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.Optional;
import java.util.UUID;

public interface TransactionRepository extends JpaRepository<Transaction, UUID> {

    @Query("""
            select t from Transaction t
            where t.userId = :userId
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

    Optional<Transaction> findByIdAndUserId(UUID id, UUID userId);

    boolean existsByCategoryId(UUID categoryId);
}
