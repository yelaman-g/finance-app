package com.aifb.platform.notification.service;

import com.aifb.platform.ai.domain.AiReminder;
import com.aifb.platform.ai.repository.AiReminderRepository;
import com.aifb.platform.event.domain.Event;
import com.aifb.platform.event.repository.EventRepository;
import com.aifb.platform.event.service.RecurrenceExpander;
import com.aifb.platform.notification.domain.NotificationSource;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.Clock;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.Collections;
import java.util.List;

@Component
public class NotificationScheduler {

    private static final Logger log = LoggerFactory.getLogger(NotificationScheduler.class);

    private final AiReminderRepository reminders;
    private final EventRepository events;
    private final RecurrenceExpander expander;
    private final NotificationService notifications;
    private final Clock clock;

    public NotificationScheduler(AiReminderRepository reminders, EventRepository events,
                                 RecurrenceExpander expander, NotificationService notifications,
                                 Clock clock) {
        this.reminders = reminders;
        this.events = events;
        this.expander = expander;
        this.notifications = notifications;
        this.clock = clock;
    }

    @Scheduled(cron = "${aifb.fcm.cron:0 0 9 * * *}", zone = "${aifb.fcm.zone:Asia/Almaty}")
    public void scheduled() {
        scanAndSend(LocalDate.now(clock));
    }

    /** Публичный для тестов и ручного вызова: сканирует оба источника на дату today. */
    public void scanAndSend(LocalDate today) {
        int count = 0;
        for (AiReminder r : reminders.findByActiveTrue()) {
            long daysUntil = ChronoUnit.DAYS.between(today, r.getEventDate());
            if (daysUntil < 0) continue;
            if (r.getNotifyDaysBefore().contains((int) daysUntil)) {
                notifications.deliver(new NotificationCandidate(
                        NotificationSource.REMINDER, r.getId(), r.getUserId(), r.getHouseholdId(),
                        r.getEventDate(), (int) daysUntil,
                        "Скоро: " + r.getEventName(), "До события " + daysUntil + " дн."));
                count++;
            }
        }
        for (Event e : events.findAll()) {
            if (e.getAiReminderId() != null) continue;  // покрыто связанным напоминанием
            List<Integer> thresholds = e.getNotifyDaysBefore();
            if (thresholds.isEmpty()) continue;
            int maxThreshold = Collections.max(thresholds);
            List<LocalDate> occ = expander.occurrences(e.getStartDate(), e.getRecurFreq(),
                    e.getRecurInterval(), e.getRecurUntil(), today, today.plusDays(maxThreshold));
            if (occ.isEmpty()) continue;
            LocalDate next = occ.get(0);
            int daysUntil = (int) ChronoUnit.DAYS.between(today, next);
            if (thresholds.contains(daysUntil)) {
                String body = daysUntil == 0 ? "Сегодня" : "Через " + daysUntil + " дн.";
                notifications.deliver(new NotificationCandidate(
                        NotificationSource.EVENT, e.getId(), e.getUserId(), e.getHouseholdId(),
                        next, daysUntil, e.getTitle(), body));
                count++;
            }
        }
        log.info("[FCM] scanAndSend({}) — кандидатов отправлено: {}", today, count);
    }
}
