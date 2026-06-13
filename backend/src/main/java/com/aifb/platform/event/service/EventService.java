package com.aifb.platform.event.service;

import com.aifb.platform.ai.api.dto.CreateReminderRequest;
import com.aifb.platform.ai.api.dto.ReminderResponse;
import com.aifb.platform.ai.service.ReminderService;
import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.common.exception.DomainException;
import com.aifb.platform.common.exception.ErrorCode;
import com.aifb.platform.common.exception.ForbiddenException;
import com.aifb.platform.common.exception.NotFoundException;
import com.aifb.platform.event.api.dto.CreateEventRequest;
import com.aifb.platform.event.api.dto.EventOccurrenceResponse;
import com.aifb.platform.event.api.dto.EventResponse;
import com.aifb.platform.event.api.dto.UpdateEventRequest;
import com.aifb.platform.event.domain.Event;
import com.aifb.platform.event.domain.EventType;
import com.aifb.platform.event.domain.RecurFreq;
import com.aifb.platform.event.repository.EventRepository;
import com.aifb.platform.household.service.HouseholdContextService;
import com.aifb.platform.household.service.HouseholdContextService.HouseholdContext;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;

@Service
public class EventService {

    private final EventRepository repository;
    private final HouseholdContextService householdContext;
    private final RecurrenceExpander expander;
    private final ReminderService reminderService;

    public EventService(EventRepository repository,
                        HouseholdContextService householdContext,
                        RecurrenceExpander expander,
                        ReminderService reminderService) {
        this.repository = repository;
        this.householdContext = householdContext;
        this.expander = expander;
        this.reminderService = reminderService;
    }

    @Transactional(readOnly = true)
    public List<EventOccurrenceResponse> list(UUID userId, LocalDate from, LocalDate to, Scope scope) {
        List<Event> events;
        if (scope == Scope.FAMILY) {
            HouseholdContext ctx = householdContext.membershipOrNull(userId);
            events = ctx == null ? List.of() : repository.findByHouseholdId(ctx.householdId());
        } else {
            events = repository.findByUserIdAndHouseholdIdIsNull(userId);
        }
        List<EventOccurrenceResponse> out = new ArrayList<>();
        for (Event e : events) {
            for (LocalDate date : expander.occurrences(e.getStartDate(), e.getRecurFreq(),
                    e.getRecurInterval(), e.getRecurUntil(), from, to)) {
                out.add(new EventOccurrenceResponse(e.getId(), e.getTitle(), e.getDescription(),
                        date, e.getStartTime(), e.isAllDay(), e.getType().name(),
                        e.getRecurFreq() != RecurFreq.NONE));
            }
        }
        out.sort(Comparator.comparing(EventOccurrenceResponse::date)
                .thenComparing(o -> o.time() == null, Comparator.reverseOrder())
                .thenComparing(EventOccurrenceResponse::time, Comparator.nullsLast(Comparator.naturalOrder())));
        return out;
    }

    @Transactional
    public EventResponse create(UUID userId, CreateEventRequest req) {
        RecurFreq freq = req.recurFreq() == null ? RecurFreq.NONE : req.recurFreq();
        if (req.budget() != null && freq != RecurFreq.NONE) {
            throw new DomainException(ErrorCode.VALIDATION_FAILED,
                    "Бюджет доступен только для разовых событий");
        }
        Event event = new Event(userId, req.title(), req.description(), req.startDate(),
                req.startTime(), req.allDay(), req.type() == null ? EventType.OTHER : req.type(),
                freq, req.recurInterval() == null ? 1 : req.recurInterval(), req.recurUntil());
        if (req.shared()) {
            HouseholdContext ctx = householdContext.requireManageSharedContent(userId);
            event.assignHousehold(ctx.householdId());
        }
        if (req.budget() != null) {
            ReminderResponse reminder = reminderService.create(userId, new CreateReminderRequest(
                    req.title(), req.startDate(), req.budget(), BigDecimal.ZERO,
                    req.notifyDaysBefore(), req.shared()));
            event.setAiReminderId(reminder.id());
        }
        return EventResponse.from(repository.save(event));
    }

    @Transactional
    public EventResponse update(UUID userId, UUID id, UpdateEventRequest req) {
        Event event = manageable(userId, id);
        event.edit(req.title(), req.description(), req.startDate(), req.startTime(), req.allDay(),
                req.type() == null ? EventType.OTHER : req.type(),
                req.recurFreq() == null ? RecurFreq.NONE : req.recurFreq(),
                req.recurInterval() == null ? 1 : req.recurInterval(), req.recurUntil());
        return EventResponse.from(repository.save(event));
    }

    @Transactional
    public void delete(UUID userId, UUID id) {
        Event event = manageable(userId, id);
        UUID reminderId = event.getAiReminderId();
        repository.delete(event);
        if (reminderId != null) {
            reminderService.delete(userId, reminderId);
        }
    }

    private Event accessible(UUID userId, UUID id) {
        Event event = repository.findById(id)
                .orElseThrow(() -> new NotFoundException("Событие не найдено"));
        if (event.isShared()) {
            HouseholdContext ctx = householdContext.membershipOrNull(userId);
            if (ctx == null || !ctx.householdId().equals(event.getHouseholdId())) {
                throw new NotFoundException("Событие не найдено");
            }
            return event;
        }
        if (!userId.equals(event.getUserId())) {
            throw new NotFoundException("Событие не найдено");
        }
        return event;
    }

    private Event manageable(UUID userId, UUID id) {
        Event event = accessible(userId, id);
        if (event.isShared()) {
            HouseholdContext ctx = householdContext.membershipOrNull(userId);
            if (ctx == null || !ctx.canManageSharedContent()) {
                throw new ForbiddenException("Недостаточно прав для семейного события");
            }
        }
        return event;
    }
}
