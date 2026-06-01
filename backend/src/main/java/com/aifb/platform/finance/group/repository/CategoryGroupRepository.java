package com.aifb.platform.finance.group.repository;

import com.aifb.platform.finance.category.domain.CategoryType;
import com.aifb.platform.finance.group.domain.CategoryGroup;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface CategoryGroupRepository extends JpaRepository<CategoryGroup, UUID> {

    @Query("""
            select g from CategoryGroup g
            where g.userId = :userId and g.householdId is null
              and (:type is null or g.type = :type)
            order by g.name asc
            """)
    List<CategoryGroup> findVisiblePersonal(@Param("userId") UUID userId,
                                            @Param("type") CategoryType type);

    @Query("""
            select g from CategoryGroup g
            where g.householdId = :householdId
              and (:type is null or g.type = :type)
            order by g.name asc
            """)
    List<CategoryGroup> findVisibleFamily(@Param("householdId") UUID householdId,
                                          @Param("type") CategoryType type);

    Optional<CategoryGroup> findByIdAndUserIdAndHouseholdIdIsNull(UUID id, UUID userId);

    Optional<CategoryGroup> findByIdAndHouseholdId(UUID id, UUID householdId);
}
