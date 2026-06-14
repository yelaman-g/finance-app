package com.aifb.platform.household.service;

import com.aifb.platform.auth.domain.User;
import com.aifb.platform.auth.repository.UserRepository;
import com.aifb.platform.common.exception.ConflictException;
import com.aifb.platform.common.exception.ForbiddenException;
import com.aifb.platform.common.exception.NotFoundException;
import com.aifb.platform.household.domain.HouseholdRole;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
public class HouseholdContextService {

    private final UserRepository userRepository;

    public HouseholdContextService(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    public record HouseholdContext(UUID householdId, HouseholdRole role) {
        public boolean canManageSharedContent() {
            return role == HouseholdRole.OWNER || role == HouseholdRole.ADULT;
        }

        public boolean canContribute() {
            return role != HouseholdRole.GUEST;
        }
    }

    @Transactional(readOnly = true)
    public HouseholdContext membershipOrNull(UUID userId) {
        User user = loadUser(userId);
        if (!user.isInHousehold()) {
            return null;
        }
        return new HouseholdContext(user.getHouseholdId(), user.getHouseholdRole());
    }

    @Transactional(readOnly = true)
    public HouseholdContext requireMembership(UUID userId) {
        HouseholdContext ctx = membershipOrNull(userId);
        if (ctx == null) {
            throw new ConflictException("Вы не состоите в семье");
        }
        return ctx;
    }

    @Transactional(readOnly = true)
    public HouseholdContext requireManageSharedContent(UUID userId) {
        HouseholdContext ctx = requireMembership(userId);
        if (!ctx.canManageSharedContent()) {
            throw new ForbiddenException("Недостаточно прав для семейного контента");
        }
        return ctx;
    }

    @Transactional(readOnly = true)
    public HouseholdContext requireContribute(UUID userId) {
        HouseholdContext ctx = requireMembership(userId);
        if (!ctx.canContribute()) {
            throw new ForbiddenException("Гость не может добавлять семейный контент");
        }
        return ctx;
    }

    private User loadUser(UUID userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new NotFoundException("Пользователь не найден"));
    }
}
