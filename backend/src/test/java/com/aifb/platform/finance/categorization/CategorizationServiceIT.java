package com.aifb.platform.finance.categorization;

import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.common.exception.ConflictException;
import com.aifb.platform.common.exception.NotFoundException;
import com.aifb.platform.finance.categorization.api.dto.CreateRuleRequest;
import com.aifb.platform.finance.categorization.api.dto.RuleResponse;
import com.aifb.platform.finance.categorization.service.CategorizationService;
import com.aifb.platform.finance.category.api.dto.CategoryResponse;
import com.aifb.platform.finance.category.api.dto.CreateCategoryRequest;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.category.service.CategoryService;
import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class CategorizationServiceIT extends AbstractIntegrationTest {

    @Autowired CategorizationService service;
    @Autowired CategoryService categoryService;
    @Autowired TestAuth testAuth;

    private List<CategoryResponse> expenseCats(UUID userId) {
        return categoryService.list(userId, CategoryType.EXPENSE, Scope.PERSONAL);
    }

    @Test
    void createRuleAndList() {
        UUID userId = testAuth.createUser().id();
        UUID cat = expenseCats(userId).get(0).id();
        RuleResponse r = service.create(userId, new CreateRuleRequest("magnum", cat));
        assertThat(r.keyword()).isEqualTo("magnum");
        assertThat(r.categoryName()).isNotBlank();
        assertThat(service.list(userId)).anyMatch(x -> x.id().equals(r.id()));
    }

    @Test
    void duplicateKeywordConflicts() {
        UUID userId = testAuth.createUser().id();
        UUID cat = expenseCats(userId).get(0).id();
        service.create(userId, new CreateRuleRequest("Magnum", cat));
        assertThatThrownBy(() -> service.create(userId, new CreateRuleRequest("magnum", cat)))
                .isInstanceOf(ConflictException.class);
    }

    @Test
    void ruleWithForeignCategoryRejected() {
        UUID owner = testAuth.createUser().id();
        UUID other = testAuth.createUser().id();
        CategoryResponse ownCat = categoryService.create(owner,
                new CreateCategoryRequest("Личная", CategoryType.EXPENSE, null, null, false, null));
        assertThatThrownBy(() -> service.create(other, new CreateRuleRequest("x", ownCat.id())))
                .isInstanceOf(NotFoundException.class);
    }

    @Test
    void resolveMatchesSubstringCaseInsensitive() {
        UUID userId = testAuth.createUser().id();
        UUID cat = expenseCats(userId).get(0).id();
        service.create(userId, new CreateRuleRequest("magnum", cat));
        assertThat(service.resolve(userId, "Покупка в MAGNUM на Абая", CategoryType.EXPENSE))
                .contains(cat);
        assertThat(service.resolve(userId, "Такси", CategoryType.EXPENSE)).isEmpty();
    }

    @Test
    void resolveLongestKeywordWins() {
        UUID userId = testAuth.createUser().id();
        List<CategoryResponse> cats = expenseCats(userId);
        UUID food = cats.get(0).id();
        UUID transport = cats.get(1).id();
        service.create(userId, new CreateRuleRequest("market", food));
        service.create(userId, new CreateRuleRequest("super market", transport));
        assertThat(service.resolve(userId, "оплата super market", CategoryType.EXPENSE))
                .contains(transport);
    }

    @Test
    void resolveFiltersByType() {
        UUID userId = testAuth.createUser().id();
        UUID expenseCat = expenseCats(userId).get(0).id();
        service.create(userId, new CreateRuleRequest("salary", expenseCat));
        assertThat(service.resolve(userId, "salary", CategoryType.INCOME)).isEmpty();
    }
}
