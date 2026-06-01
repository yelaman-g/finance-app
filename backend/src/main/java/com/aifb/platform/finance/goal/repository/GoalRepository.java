package com.aifb.platform.finance.goal.repository;

import com.aifb.platform.finance.goal.domain.Goal;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface GoalRepository extends JpaRepository<Goal, UUID> {
    List<Goal> findByUserIdOrderByCreatedAtDesc(UUID userId);
    Optional<Goal> findByIdAndUserId(UUID id, UUID userId);
}
