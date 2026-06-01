package com.aifb.platform.finance.statistics;

import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.category.service.CategoryService;
import com.aifb.platform.finance.statistics.api.dto.MemberBreakdownResponse;
import com.aifb.platform.finance.statistics.api.dto.SummaryResponse;
import com.aifb.platform.finance.statistics.service.StatisticsService;
import com.aifb.platform.finance.transaction.api.dto.CreateTransactionRequest;
import com.aifb.platform.finance.transaction.service.TransactionService;
import com.aifb.platform.household.api.dto.CreateHouseholdRequest;
import com.aifb.platform.household.api.dto.JoinHouseholdRequest;
import com.aifb.platform.household.service.HouseholdService;
import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;

class StatisticsScopeIT extends AbstractIntegrationTest {

    @Autowired StatisticsService service;
    @Autowired TransactionService txService;
    @Autowired CategoryService categoryService;
    @Autowired HouseholdService householdService;
    @Autowired TestAuth testAuth;

    @Test
    void familySummaryAndByMember() {
        UUID owner = testAuth.createUser().id();
        UUID member = testAuth.createUser().id();
        String code = householdService.create(owner, new CreateHouseholdRequest("С")).inviteCode();
        householdService.join(member, new JoinHouseholdRequest(code));
        UUID cat = categoryService.list(owner, CategoryType.EXPENSE, Scope.FAMILY).get(0).id();

        txService.create(owner, new CreateTransactionRequest(
                cat, CategoryType.EXPENSE, new BigDecimal("300.00"), null, LocalDate.now(), true));
        txService.create(member, new CreateTransactionRequest(
                cat, CategoryType.EXPENSE, new BigDecimal("200.00"), null, LocalDate.now(), true));

        SummaryResponse fam = service.summary(owner, null, null, Scope.FAMILY);
        assertThat(fam.expense()).isEqualByComparingTo("500.00");

        List<MemberBreakdownResponse> byMember = service.byMember(owner);
        assertThat(byMember).hasSize(2);
        assertThat(byMember).allSatisfy(m -> assertThat(m.fullName()).isNotBlank());
    }

    @Test
    void personalSummaryExcludesFamily() {
        UUID owner = testAuth.createUser().id();
        householdService.create(owner, new CreateHouseholdRequest("С"));
        UUID famCat = categoryService.list(owner, CategoryType.EXPENSE, Scope.FAMILY).get(0).id();
        txService.create(owner, new CreateTransactionRequest(
                famCat, CategoryType.EXPENSE, new BigDecimal("300.00"), null, LocalDate.now(), true));
        SummaryResponse personal = service.summary(owner, null, null, Scope.PERSONAL);
        assertThat(personal.expense()).isEqualByComparingTo("0");
    }
}
