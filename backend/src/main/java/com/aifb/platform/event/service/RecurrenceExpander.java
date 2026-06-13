package com.aifb.platform.event.service;

import com.aifb.platform.event.domain.RecurFreq;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

/**
 * Раскрывает правило повторения события в конкретные даты внутри [from, to].
 * Чистая логика без зависимостей — тестируется изолированно.
 */
@Component
public class RecurrenceExpander {

    private static final int MAX_OCCURRENCES = 400;
    private static final int FAST_FORWARD_GUARD = 100_000;

    public List<LocalDate> occurrences(LocalDate start, RecurFreq freq, int interval,
                                       LocalDate until, LocalDate from, LocalDate to) {
        List<LocalDate> out = new ArrayList<>();
        if (start == null || from == null || to == null || to.isBefore(from)) {
            return out;
        }
        if (freq == null || freq == RecurFreq.NONE) {
            if (!start.isBefore(from) && !start.isAfter(to)) {
                out.add(start);
            }
            return out;
        }
        LocalDate end = (until != null && until.isBefore(to)) ? until : to;
        int step = Math.max(1, interval);

        // Перемотка к первому вхождению >= from (без накопления вне диапазона).
        LocalDate d = start;
        int guard = 0;
        while (d.isBefore(from) && !d.isAfter(end) && guard < FAST_FORWARD_GUARD) {
            d = advance(d, freq, step);
            guard++;
        }
        // Выдача вхождений в [from, end].
        int count = 0;
        while (!d.isAfter(end) && count < MAX_OCCURRENCES) {
            if (!d.isBefore(from)) {
                out.add(d);
            }
            d = advance(d, freq, step);
            count++;
        }
        return out;
    }

    private LocalDate advance(LocalDate d, RecurFreq freq, int step) {
        return switch (freq) {
            case DAILY -> d.plusDays(step);
            case WEEKLY -> d.plusWeeks(step);
            case MONTHLY -> d.plusMonths(step);
            case YEARLY -> d.plusYears(step);
            case NONE -> d;
        };
    }
}
