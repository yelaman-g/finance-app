package com.aifb.platform.finance.categorization.repository;

import com.aifb.platform.finance.categorization.domain.CategorizationRule;
import com.aifb.platform.finance.category.domain.CategoryType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface CategorizationRuleRepository extends JpaRepository<CategorizationRule, UUID> {

    List<CategorizationRule> findByUserIdOrderByCreatedAtDesc(UUID userId);

    Optional<CategorizationRule> findByIdAndUserId(UUID id, UUID userId);

    boolean existsByUserIdAndKeywordIgnoreCase(UUID userId, String keyword);

    @Query("""
            select r from CategorizationRule r, com.aifb.platform.finance.category.domain.Category c
            where r.categoryId = c.id and r.userId = :userId and c.type = :type
            order by length(r.keyword) desc, r.createdAt desc
            """)
    List<CategorizationRule> findForMatching(@Param("userId") UUID userId,
                                             @Param("type") CategoryType type);
}
