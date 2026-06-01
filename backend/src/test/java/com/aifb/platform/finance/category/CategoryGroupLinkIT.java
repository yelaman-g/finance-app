package com.aifb.platform.finance.category;

import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.common.exception.DomainException;
import com.aifb.platform.finance.category.api.dto.CategoryResponse;
import com.aifb.platform.finance.category.api.dto.CreateCategoryRequest;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.category.service.CategoryService;
import com.aifb.platform.finance.group.api.dto.CreateGroupRequest;
import com.aifb.platform.finance.group.api.dto.GroupResponse;
import com.aifb.platform.finance.group.service.CategoryGroupService;
import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class CategoryGroupLinkIT extends AbstractIntegrationTest {

    @Autowired CategoryService categoryService;
    @Autowired CategoryGroupService groupService;
    @Autowired TestAuth testAuth;

    @Test
    void categoryWithMatchingGroupIsLinked() {
        UUID userId = testAuth.createUser().id();
        GroupResponse group = groupService.create(userId,
                new CreateGroupRequest("Коммунальные", CategoryType.EXPENSE, null, null, false));
        CategoryResponse cat = categoryService.create(userId,
                new CreateCategoryRequest("Свет", CategoryType.EXPENSE, null, null, false, group.id()));
        assertThat(cat.groupId()).isEqualTo(group.id());
    }

    @Test
    void groupTypeMismatchRejected() {
        UUID userId = testAuth.createUser().id();
        GroupResponse incomeGroup = groupService.create(userId,
                new CreateGroupRequest("Доходы", CategoryType.INCOME, null, null, false));
        assertThatThrownBy(() -> categoryService.create(userId,
                new CreateCategoryRequest("Свет", CategoryType.EXPENSE, null, null, false, incomeGroup.id())))
                .isInstanceOf(DomainException.class);
    }

    @Test
    void othersGroupRejected() {
        UUID owner = testAuth.createUser().id();
        UUID other = testAuth.createUser().id();
        GroupResponse group = groupService.create(owner,
                new CreateGroupRequest("Чужая", CategoryType.EXPENSE, null, null, false));
        assertThatThrownBy(() -> categoryService.create(other,
                new CreateCategoryRequest("Свет", CategoryType.EXPENSE, null, null, false, group.id())))
                .isInstanceOf(DomainException.class);
    }

    @Test
    void deletingGroupUngroupsCategory() {
        UUID userId = testAuth.createUser().id();
        GroupResponse group = groupService.create(userId,
                new CreateGroupRequest("Коммунальные", CategoryType.EXPENSE, null, null, false));
        CategoryResponse cat = categoryService.create(userId,
                new CreateCategoryRequest("Свет", CategoryType.EXPENSE, null, null, false, group.id()));
        groupService.delete(userId, group.id());
        assertThat(categoryService.list(userId, CategoryType.EXPENSE, Scope.PERSONAL))
                .filteredOn(c -> c.id().equals(cat.id()))
                .singleElement()
                .satisfies(c -> assertThat(c.groupId()).isNull());
    }
}
