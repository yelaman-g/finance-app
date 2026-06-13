package com.aifb.platform.ai.service;

import com.aifb.platform.ai.api.dto.CreateReminderRequest;
import com.aifb.platform.ai.api.dto.ReminderResponse;
import com.aifb.platform.ai.domain.AiReminder;
import com.aifb.platform.ai.repository.AiReminderRepository;
import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.common.exception.ForbiddenException;
import com.aifb.platform.common.exception.NotFoundException;
import com.aifb.platform.household.service.HouseholdContextService;
import com.aifb.platform.household.service.HouseholdContextService.HouseholdContext;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.UUID;

@Service
public class ReminderService {

    private final AiReminderRepository repository;
    private final HouseholdContextService householdContext;

    public ReminderService(AiReminderRepository repository, HouseholdContextService householdContext) {
        this.repository = repository;
        this.householdContext = householdContext;
    }

    @Transactional(readOnly = true)
    public List<ReminderResponse> list(UUID userId, Scope scope) {
        List<AiReminder> reminders;
        if (scope == Scope.FAMILY) {
            HouseholdContext ctx = householdContext.membershipOrNull(userId);
            reminders = ctx == null ? List.of()
                    : repository.findByHouseholdIdOrderByEventDateAsc(ctx.householdId());
        } else {
            reminders = repository.findByUserIdAndHouseholdIdIsNullOrderByEventDateAsc(userId);
        }
        return reminders.stream().map(this::toResponse).toList();
    }

    @Transactional
    public ReminderResponse create(UUID userId, CreateReminderRequest req) {
        AiReminder reminder = new AiReminder(userId, req.eventName(), req.eventDate(),
                req.targetAmount(), req.savedAmount(), req.notifyDaysBefore());
        if (req.shared()) {
            HouseholdContext ctx = householdContext.requireManageSharedContent(userId);
            reminder.assignHousehold(ctx.householdId());
        }
        return toResponse(repository.save(reminder));
    }

    @Transactional
    public void delete(UUID userId, UUID id) {
        AiReminder reminder = repository.findById(id)
                .orElseThrow(() -> new NotFoundException("Напоминание не найдено"));
        if (reminder.isShared()) {
            HouseholdContext ctx = householdContext.membershipOrNull(userId);
            if (ctx == null || !ctx.householdId().equals(reminder.getHouseholdId())) {
                throw new NotFoundException("Напоминание не найдено");
            }
            if (!ctx.canManageSharedContent()) {
                throw new ForbiddenException("Недостаточно прав");
            }
        } else if (!userId.equals(reminder.getUserId())) {
            throw new NotFoundException("Напоминание не найдено");
        }
        repository.delete(reminder);
    }

    private ReminderResponse toResponse(AiReminder r) {
        long days = Math.max(0, ChronoUnit.DAYS.between(LocalDate.now(), r.getEventDate()));
        int months = (int) Math.max(1, Math.ceil(days / 30.0));
        BigDecimal target = r.getTargetAmount();
        BigDecimal monthlyNeeded = BigDecimal.ZERO;
        double progress = 0.0;
        if (target != null && target.signum() > 0) {
            BigDecimal remaining = target.subtract(r.getSavedAmount()).max(BigDecimal.ZERO);
            monthlyNeeded = remaining.divide(BigDecimal.valueOf(months), 2, RoundingMode.HALF_UP);
            progress = Math.min(100.0, r.getSavedAmount().multiply(BigDecimal.valueOf(100))
                    .divide(target, 1, RoundingMode.HALF_UP).doubleValue());
        }
        return new ReminderResponse(r.getId(), r.getEventName(), r.getEventDate(),
                target, r.getSavedAmount(), r.getNotifyDaysBefore(), r.isActive(), r.isShared(),
                days, months, monthlyNeeded, progress);
    }
}
