package com.aifb.platform.social.capsule.repository;

import com.aifb.platform.social.capsule.domain.TimeCapsule;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface TimeCapsuleRepository extends JpaRepository<TimeCapsule, UUID> {

    List<TimeCapsule> findByHouseholdIdOrderByOpenDateAsc(UUID householdId);
}
