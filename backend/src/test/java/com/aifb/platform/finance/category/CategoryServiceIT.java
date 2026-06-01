package com.aifb.platform.finance.category;

import com.aifb.platform.common.exception.ConflictException;
import com.aifb.platform.common.exception.ForbiddenException;
import com.aifb.platform.common.exception.NotFoundException;
import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.finance.category.api.dto.CategoryResponse;
import com.aifb.platform.finance.category.api.dto.CreateCategoryRequest;
import com.aifb.platform.finance.category.api.dto.UpdateCategoryRequest;
import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.category.repository.CategoryRepository;
import com.aifb.platform.finance.category.service.CategoryService;
import com.aifb.platform.support.AbstractIntegrationTest;
import com.aifb.platform.support.TestAuth;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;

import java.util.List;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class CategoryServiceIT extends AbstractIntegrationTest {

    @Autowired CategoryService service;
    @Autowired CategoryRepository repository;
    @Autowired TestAuth testAuth;

    @Test
    void listReturnsSystemCategoriesForNewUser() {
        UUID userId = testAuth.createUser().id();
        List<CategoryResponse> expense = service.list(userId, CategoryType.EXPENSE, Scope.PERSONAL);
        assertThat(expense).isNotEmpty();
        assertThat(expense).allMatch(c -> c.type().equals("EXPENSE"));
        assertThat(expense).anyMatch(CategoryResponse::system);
    }

    @Test
    void createAddsUserCategoryVisibleOnlyToOwner() {
        UUID owner = testAuth.createUser().id();
        UUID other = testAuth.createUser().id();

        CategoryResponse created = service.create(owner,
                new CreateCategoryRequest("Кафе", CategoryType.EXPENSE, "coffee", "#FFAA00", false));

        assertThat(created.system()).isFalse();
        assertThat(service.list(owner, CategoryType.EXPENSE, Scope.PERSONAL))
                .anyMatch(c -> c.id().equals(created.id()));
        assertThat(service.list(other, CategoryType.EXPENSE, Scope.PERSONAL))
                .noneMatch(c -> c.id().equals(created.id()));
    }

    @Test
    void createRejectsDuplicateActiveName() {
        UUID owner = testAuth.createUser().id();
        service.create(owner, new CreateCategoryRequest("Кафе", CategoryType.EXPENSE, null, null, false));
        assertThatThrownBy(() -> service.create(owner,
                new CreateCategoryRequest("кафе", CategoryType.EXPENSE, null, null, false)))
                .isInstanceOf(ConflictException.class);
    }

    @Test
    void updateChangesOwnedCategory() {
        UUID owner = testAuth.createUser().id();
        CategoryResponse created = service.create(owner,
                new CreateCategoryRequest("Кафе", CategoryType.EXPENSE, null, null, false));
        CategoryResponse updated = service.update(owner, created.id(),
                new UpdateCategoryRequest("Кофейни", "coffee", "#112233"));
        assertThat(updated.name()).isEqualTo("Кофейни");
        assertThat(updated.icon()).isEqualTo("coffee");
    }

    @Test
    void updateSystemCategoryForbidden() {
        UUID owner = testAuth.createUser().id();
        UUID systemId = repository.findVisible(owner, CategoryType.EXPENSE).stream()
                .filter(c -> c.isSystem()).findFirst().orElseThrow().getId();
        assertThatThrownBy(() -> service.update(owner, systemId,
                new UpdateCategoryRequest("Hacked", null, null)))
                .isInstanceOf(ForbiddenException.class);
    }

    @Test
    void deleteSoftDeletesAndHidesFromList() {
        UUID owner = testAuth.createUser().id();
        CategoryResponse created = service.create(owner,
                new CreateCategoryRequest("Кафе", CategoryType.EXPENSE, null, null, false));
        service.delete(owner, created.id());

        assertThat(service.list(owner, CategoryType.EXPENSE, Scope.PERSONAL))
                .noneMatch(c -> c.id().equals(created.id()));
        assertThat(repository.findById(created.id()).orElseThrow().isDeleted()).isTrue();
        assertThat(service.create(owner,
                new CreateCategoryRequest("Кафе", CategoryType.EXPENSE, null, null, false)).id())
                .isNotNull();
    }

    @Test
    void updateOtherUsersCategoryNotFound() {
        UUID owner = testAuth.createUser().id();
        UUID other = testAuth.createUser().id();
        CategoryResponse created = service.create(owner,
                new CreateCategoryRequest("Кафе", CategoryType.EXPENSE, null, null, false));
        assertThatThrownBy(() -> service.update(other, created.id(),
                new UpdateCategoryRequest("X", null, null)))
                .isInstanceOf(NotFoundException.class);
    }
}
