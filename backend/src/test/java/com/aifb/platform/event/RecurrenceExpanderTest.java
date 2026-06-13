package com.aifb.platform.event;

import com.aifb.platform.event.domain.RecurFreq;
import com.aifb.platform.event.service.RecurrenceExpander;
import org.junit.jupiter.api.Test;

import java.time.LocalDate;

import static org.assertj.core.api.Assertions.assertThat;

class RecurrenceExpanderTest {

    private final RecurrenceExpander expander = new RecurrenceExpander();

    @Test
    void noneInsideRange() {
        var occ = expander.occurrences(LocalDate.of(2026, 6, 10), RecurFreq.NONE, 1, null,
                LocalDate.of(2026, 6, 1), LocalDate.of(2026, 6, 30));
        assertThat(occ).containsExactly(LocalDate.of(2026, 6, 10));
    }

    @Test
    void noneOutsideRangeEmpty() {
        var occ = expander.occurrences(LocalDate.of(2026, 5, 10), RecurFreq.NONE, 1, null,
                LocalDate.of(2026, 6, 1), LocalDate.of(2026, 6, 30));
        assertThat(occ).isEmpty();
    }

    @Test
    void weeklyExpandsWithinMonth() {
        var occ = expander.occurrences(LocalDate.of(2026, 6, 1), RecurFreq.WEEKLY, 1, null,
                LocalDate.of(2026, 6, 1), LocalDate.of(2026, 6, 30));
        assertThat(occ).containsExactly(
                LocalDate.of(2026, 6, 1), LocalDate.of(2026, 6, 8), LocalDate.of(2026, 6, 15),
                LocalDate.of(2026, 6, 22), LocalDate.of(2026, 6, 29));
    }

    @Test
    void yearlyBirthdayShowsOnceInQueriedMonth() {
        var occ = expander.occurrences(LocalDate.of(2000, 3, 15), RecurFreq.YEARLY, 1, null,
                LocalDate.of(2026, 3, 1), LocalDate.of(2026, 3, 31));
        assertThat(occ).containsExactly(LocalDate.of(2026, 3, 15));
    }

    @Test
    void monthlyFastForwardsFromFarPastStart() {
        var occ = expander.occurrences(LocalDate.of(2024, 1, 31), RecurFreq.MONTHLY, 1, null,
                LocalDate.of(2026, 6, 1), LocalDate.of(2026, 6, 30));
        assertThat(occ).hasSize(1);
        assertThat(occ.get(0).getMonthValue()).isEqualTo(6);
    }

    @Test
    void untilBoundStopsExpansion() {
        var occ = expander.occurrences(LocalDate.of(2026, 6, 1), RecurFreq.WEEKLY, 1,
                LocalDate.of(2026, 6, 10),
                LocalDate.of(2026, 6, 1), LocalDate.of(2026, 6, 30));
        assertThat(occ).containsExactly(LocalDate.of(2026, 6, 1), LocalDate.of(2026, 6, 8));
    }
}
