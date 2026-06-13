package com.aifb.platform.ai;

import com.aifb.platform.ai.advisor.FinanceContext;
import com.aifb.platform.ai.advisor.FinanceContextBuilder;
import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import static org.assertj.core.api.Assertions.assertThat;

class AiContextBuilderIT extends AbstractIntegrationTest {

    @Autowired TestAuth testAuth;
    @Autowired FinanceContextBuilder builder;

    @Test
    void buildsContextForNewUserWithoutHousehold() {
        TestAuth.AuthedUser user = testAuth.createUser();
        FinanceContext ctx = builder.build(user.id(), null);

        assertThat(ctx).isNotNull();
        assertThat(ctx.scope()).isEqualTo(Scope.PERSONAL);
        assertThat(ctx.currency()).isNotNull();
        assertThat(ctx.currentMonth()).isNotNull();
        assertThat(ctx.previousMonth()).isNotNull();
        assertThat(ctx.topExpenseCategories()).isNotNull();
        assertThat(ctx.trend()).isNotNull();
    }
}
