package com.aifb.platform.social.poll.repository;

import com.aifb.platform.social.poll.domain.Poll;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface PollRepository extends JpaRepository<Poll, UUID> {

    List<Poll> findByHouseholdIdOrderByCreatedAtDesc(UUID householdId);
}
