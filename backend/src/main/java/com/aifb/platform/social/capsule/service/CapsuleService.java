package com.aifb.platform.social.capsule.service;

import com.aifb.platform.common.exception.DomainException;
import com.aifb.platform.common.exception.ErrorCode;
import com.aifb.platform.common.exception.ForbiddenException;
import com.aifb.platform.common.exception.NotFoundException;
import com.aifb.platform.household.service.HouseholdContextService;
import com.aifb.platform.household.service.HouseholdContextService.HouseholdContext;
import com.aifb.platform.social.capsule.api.dto.CapsuleResponse;
import com.aifb.platform.social.capsule.api.dto.CreateCapsuleRequest;
import com.aifb.platform.social.capsule.domain.TimeCapsule;
import com.aifb.platform.social.capsule.repository.TimeCapsuleRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Clock;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@Service
public class CapsuleService {

    private final TimeCapsuleRepository repository;
    private final HouseholdContextService householdContext;
    private final Clock clock;

    public CapsuleService(TimeCapsuleRepository repository,
                          HouseholdContextService householdContext,
                          Clock clock) {
        this.repository = repository;
        this.householdContext = householdContext;
        this.clock = clock;
    }

    @Transactional(readOnly = true)
    public List<CapsuleResponse> list(UUID userId) {
        HouseholdContext ctx = householdContext.membershipOrNull(userId);
        if (ctx == null) {
            return List.of();
        }
        LocalDate today = LocalDate.now(clock);
        return repository.findByHouseholdIdOrderByOpenDateAsc(ctx.householdId())
                .stream()
                .map(c -> toResponse(c, today))
                .toList();
    }

    @Transactional
    public CapsuleResponse create(UUID userId, CreateCapsuleRequest req) {
        HouseholdContext ctx = householdContext.requireContribute(userId);
        // Defensive check in service layer (DTO @Future already validates, but guard in service too)
        if (!req.openDate().isAfter(LocalDate.now(clock))) {
            throw new DomainException(ErrorCode.VALIDATION_FAILED,
                    "open_date должна быть в будущем");
        }
        TimeCapsule capsule = new TimeCapsule(
                ctx.householdId(), userId, req.title(), req.message(), req.openDate());
        repository.save(capsule);
        LocalDate today = LocalDate.now(clock);
        return toResponse(capsule, today);
    }

    @Transactional
    public void delete(UUID userId, UUID capsuleId) {
        HouseholdContext ctx = householdContext.requireMembership(userId);
        TimeCapsule capsule = repository.findById(capsuleId)
                .orElseThrow(() -> new NotFoundException("Капсула не найдена"));
        if (!capsule.getHouseholdId().equals(ctx.householdId())) {
            throw new NotFoundException("Капсула не найдена");
        }
        boolean isCreator = capsule.getCreatedBy().equals(userId);
        boolean canManage = ctx.canManageSharedContent();
        if (!isCreator && !canManage) {
            throw new ForbiddenException("Только создатель или администратор может удалить капсулу");
        }
        repository.delete(capsule);
    }

    private CapsuleResponse toResponse(TimeCapsule capsule, LocalDate today) {
        boolean locked = capsule.getOpenDate().isAfter(today);
        return new CapsuleResponse(
                capsule.getId(),
                capsule.getTitle(),
                capsule.getOpenDate(),
                locked,
                locked ? null : capsule.getMessage(),
                capsule.getCreatedBy()
        );
    }
}
