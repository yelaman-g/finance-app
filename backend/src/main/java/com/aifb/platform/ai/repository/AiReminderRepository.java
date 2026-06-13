package com.aifb.platform.ai.repository;

import com.aifb.platform.ai.domain.AiReminder;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface AiReminderRepository extends JpaRepository<AiReminder, UUID> {
    List<AiReminder> findByUserIdAndHouseholdIdIsNullOrderByEventDateAsc(UUID userId);
    List<AiReminder> findByHouseholdIdOrderByEventDateAsc(UUID householdId);
    java.util.List<AiReminder> findByActiveTrue();
}
