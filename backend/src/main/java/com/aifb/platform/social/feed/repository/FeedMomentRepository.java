package com.aifb.platform.social.feed.repository;

import com.aifb.platform.social.feed.domain.FeedMoment;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface FeedMomentRepository extends JpaRepository<FeedMoment, UUID> {

    List<FeedMoment> findByHouseholdIdOrderByCreatedAtDesc(UUID householdId);
}
