package com.aifb.platform.shopping.repository;

import com.aifb.platform.shopping.domain.ShoppingItem;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface ShoppingItemRepository extends JpaRepository<ShoppingItem, UUID> {

    List<ShoppingItem> findByHouseholdIdOrderByCheckedAscUpdatedAtDesc(UUID householdId);
}
