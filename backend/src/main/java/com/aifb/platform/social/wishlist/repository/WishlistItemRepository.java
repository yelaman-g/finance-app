package com.aifb.platform.social.wishlist.repository;

import com.aifb.platform.social.wishlist.domain.WishlistItem;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface WishlistItemRepository extends JpaRepository<WishlistItem, UUID> {

    List<WishlistItem> findByHouseholdIdOrderByCreatedAtDesc(UUID householdId);
}
