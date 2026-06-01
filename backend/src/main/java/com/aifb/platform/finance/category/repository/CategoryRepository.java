package com.aifb.platform.finance.category.repository;

import com.aifb.platform.finance.category.domain.Category;
import com.aifb.platform.finance.category.domain.CategoryType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface CategoryRepository extends JpaRepository<Category, UUID> {

    @Query("""
            select c from Category c
            where c.deletedAt is null
              and (c.userId is null or c.userId = :userId)
              and (:type is null or c.type = :type)
            order by c.system desc, c.name asc
            """)
    List<Category> findVisible(@Param("userId") UUID userId,
                               @Param("type") CategoryType type);

    @Query("""
            select c from Category c
            where c.id = :id
              and c.deletedAt is null
              and (c.userId is null or c.userId = :userId)
            """)
    Optional<Category> findVisibleByIdForUser(@Param("id") UUID id,
                                              @Param("userId") UUID userId);

    boolean existsByUserIdAndTypeAndNameIgnoreCaseAndDeletedAtIsNull(
            UUID userId, CategoryType type, String name);

    List<Category> findByIdInAndDeletedAtIsNull(Collection<UUID> ids);

    List<Category> findByIdIn(Collection<UUID> ids);

    @Query("""
            select c from Category c
            where c.deletedAt is null
              and (c.userId is null or (c.userId = :userId and c.householdId is null))
              and (:type is null or c.type = :type)
            order by c.system desc, c.name asc
            """)
    List<Category> findVisiblePersonal(@Param("userId") UUID userId,
                                       @Param("type") CategoryType type);

    @Query("""
            select c from Category c
            where c.deletedAt is null
              and (c.userId is null or c.householdId = :householdId)
              and (:type is null or c.type = :type)
            order by c.system desc, c.name asc
            """)
    List<Category> findVisibleFamily(@Param("householdId") UUID householdId,
                                     @Param("type") CategoryType type);

    @Query("""
            select c from Category c
            where c.id = :id and c.deletedAt is null
              and (c.userId is null or (c.userId = :userId and c.householdId is null))
            """)
    Optional<Category> findVisibleByIdPersonal(@Param("id") UUID id,
                                               @Param("userId") UUID userId);

    @Query("""
            select c from Category c
            where c.id = :id and c.deletedAt is null
              and (c.userId is null or c.householdId = :householdId)
            """)
    Optional<Category> findVisibleByIdFamily(@Param("id") UUID id,
                                             @Param("householdId") UUID householdId);

    boolean existsByHouseholdIdAndTypeAndNameIgnoreCaseAndDeletedAtIsNull(
            UUID householdId, CategoryType type, String name);
}
