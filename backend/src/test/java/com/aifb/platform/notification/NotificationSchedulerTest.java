package com.aifb.platform.notification;

import com.aifb.platform.ai.domain.AiReminder;
import com.aifb.platform.ai.repository.AiReminderRepository;
import com.aifb.platform.event.domain.Event;
import com.aifb.platform.event.domain.EventType;
import com.aifb.platform.event.domain.RecurFreq;
import com.aifb.platform.event.repository.EventRepository;
import com.aifb.platform.event.service.RecurrenceExpander;
import com.aifb.platform.notification.domain.NotificationSource;
import com.aifb.platform.notification.service.NotificationCandidate;
import com.aifb.platform.notification.service.NotificationScheduler;
import com.aifb.platform.notification.service.NotificationService;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.math.BigDecimal;
import java.time.Clock;
import java.time.LocalDate;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

class NotificationSchedulerTest {

    private final AiReminderRepository reminders = mock(AiReminderRepository.class);
    private final EventRepository events = mock(EventRepository.class);
    private final NotificationService notifications = mock(NotificationService.class);
    private final RecurrenceExpander expander = new RecurrenceExpander();
    private final Clock clock = Clock.systemDefaultZone();
    private final NotificationScheduler scheduler =
            new NotificationScheduler(reminders, events, expander, notifications, clock);

    @Test
    void reminderFiresOnMatchingThreshold() {
        LocalDate today = LocalDate.parse("2026-07-01");
        AiReminder r = new AiReminder(java.util.UUID.randomUUID(), "ДР", today.plusDays(7),
                BigDecimal.TEN, BigDecimal.ZERO, List.of(7, 1));
        when(reminders.findByActiveTrue()).thenReturn(List.of(r));
        when(events.findAll()).thenReturn(List.of());

        scheduler.scanAndSend(today);

        ArgumentCaptor<NotificationCandidate> cap = ArgumentCaptor.forClass(NotificationCandidate.class);
        verify(notifications, times(1)).deliver(cap.capture());
        assertThat(cap.getValue().sourceType()).isEqualTo(NotificationSource.REMINDER);
        assertThat(cap.getValue().thresholdDay()).isEqualTo(7);
    }

    @Test
    void reminderDoesNotFireOffThreshold() {
        LocalDate today = LocalDate.parse("2026-07-01");
        AiReminder r = new AiReminder(java.util.UUID.randomUUID(), "ДР", today.plusDays(5),
                BigDecimal.TEN, BigDecimal.ZERO, List.of(7, 1));
        when(reminders.findByActiveTrue()).thenReturn(List.of(r));
        when(events.findAll()).thenReturn(List.of());

        scheduler.scanAndSend(today);

        verify(notifications, never()).deliver(any());
    }

    @Test
    void eventWithLinkedReminderIsSkipped() {
        LocalDate today = LocalDate.parse("2026-07-01");
        when(reminders.findByActiveTrue()).thenReturn(List.of());
        Event e = new Event(java.util.UUID.randomUUID(), "Покупка", null, today.plusDays(1),
                null, true, EventType.OTHER, RecurFreq.NONE, 1, null, List.of(1, 0));
        e.setAiReminderId(java.util.UUID.randomUUID());  // связан → пропуск
        when(events.findAll()).thenReturn(List.of(e));

        scheduler.scanAndSend(today);

        verify(notifications, never()).deliver(any());
    }

    @Test
    void recurringEventFiresOnNearestOccurrence() {
        LocalDate today = LocalDate.parse("2026-07-01");
        when(reminders.findByActiveTrue()).thenReturn(List.of());
        // еженедельное событие со стартом сегодня+1 → ближайшее вхождение через 1 день, порог 1
        Event e = new Event(java.util.UUID.randomUUID(), "Тренировка", null, today.plusDays(1),
                null, true, EventType.OTHER, RecurFreq.WEEKLY, 1, null, List.of(1));
        when(events.findAll()).thenReturn(List.of(e));

        scheduler.scanAndSend(today);

        ArgumentCaptor<NotificationCandidate> cap = ArgumentCaptor.forClass(NotificationCandidate.class);
        verify(notifications, times(1)).deliver(cap.capture());
        assertThat(cap.getValue().sourceType()).isEqualTo(NotificationSource.EVENT);
        assertThat(cap.getValue().thresholdDay()).isEqualTo(1);
    }
}
