package com.aifb.platform.event.repository;

import com.aifb.platform.event.domain.Event;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface EventRepository extends JpaRepository<Event, UUID> {
    List<Event> findByUserIdAndHouseholdIdIsNull(UUID userId);
    List<Event> findByHouseholdId(UUID householdId);
}
