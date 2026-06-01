package com.aifb.platform.finance.goal.repository;

import com.aifb.platform.finance.goal.domain.GoalContribution;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface GoalContributionRepository extends JpaRepository<GoalContribution, UUID> {

    List<GoalContribution> findByGoalIdOrderByContributedOnDesc(UUID goalId);

    Optional<GoalContribution> findByIdAndGoalId(UUID id, UUID goalId);

    @Query("select coalesce(sum(c.amount), 0) from GoalContribution c where c.goalId = :goalId")
    BigDecimal sumByGoalId(@Param("goalId") UUID goalId);

    interface GoalSum {
        UUID getGoalId();
        BigDecimal getTotal();
    }

    @Query("""
            select c.goalId as goalId, coalesce(sum(c.amount), 0) as total
            from GoalContribution c
            where c.goalId in :goalIds
            group by c.goalId
            """)
    List<GoalSum> sumByGoalIds(@Param("goalIds") Collection<UUID> goalIds);
}
