package com.aifb.platform.household.service;

import com.aifb.platform.auth.domain.User;
import com.aifb.platform.auth.repository.UserRepository;
import com.aifb.platform.common.exception.ConflictException;
import com.aifb.platform.common.exception.NotFoundException;
import com.aifb.platform.household.api.dto.CreateHouseholdRequest;
import com.aifb.platform.household.api.dto.HouseholdResponse;
import com.aifb.platform.household.api.dto.JoinHouseholdRequest;
import com.aifb.platform.household.api.dto.MemberResponse;
import com.aifb.platform.household.domain.Household;
import com.aifb.platform.household.domain.HouseholdRole;
import com.aifb.platform.household.repository.HouseholdRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.UUID;

@Service
public class HouseholdService {

    private final HouseholdRepository householdRepository;
    private final UserRepository userRepository;
    private final InviteCodeGenerator codeGenerator;

    public HouseholdService(HouseholdRepository householdRepository,
                            UserRepository userRepository,
                            InviteCodeGenerator codeGenerator) {
        this.householdRepository = householdRepository;
        this.userRepository = userRepository;
        this.codeGenerator = codeGenerator;
    }

    @Transactional
    public HouseholdResponse create(UUID userId, CreateHouseholdRequest req) {
        User user = loadUser(userId);
        if (user.isInHousehold()) {
            throw new ConflictException("Вы уже состоите в семье");
        }
        Household household = new Household(req.name(), userId, uniqueCode());
        householdRepository.save(household);
        user.joinHousehold(household.getId(), HouseholdRole.OWNER);
        userRepository.save(user);
        return toResponse(household, user);
    }

    @Transactional
    public HouseholdResponse join(UUID userId, JoinHouseholdRequest req) {
        User user = loadUser(userId);
        if (user.isInHousehold()) {
            throw new ConflictException("Вы уже состоите в семье");
        }
        Household household = householdRepository.findByInviteCode(req.inviteCode())
                .orElseThrow(() -> new NotFoundException("Семья по коду не найдена"));
        user.joinHousehold(household.getId(), HouseholdRole.ADULT);
        userRepository.save(user);
        return toResponse(household, user);
    }

    @Transactional(readOnly = true)
    public HouseholdResponse getMine(UUID userId) {
        User user = loadUser(userId);
        if (!user.isInHousehold()) {
            throw new NotFoundException("Вы не состоите в семье");
        }
        Household household = householdRepository.findById(user.getHouseholdId())
                .orElseThrow(() -> new NotFoundException("Семья не найдена"));
        return toResponse(household, user);
    }

    private HouseholdResponse toResponse(Household household, User viewer) {
        List<MemberResponse> members = userRepository.findByHouseholdId(household.getId())
                .stream().map(MemberResponse::from).toList();
        boolean isOwner = viewer.getHouseholdRole() == HouseholdRole.OWNER;
        return new HouseholdResponse(
                household.getId(),
                household.getName(),
                isOwner ? household.getInviteCode() : null,
                viewer.getHouseholdRole() == null ? null : viewer.getHouseholdRole().name(),
                members);
    }

    private String uniqueCode() {
        String code;
        do {
            code = codeGenerator.generate();
        } while (householdRepository.existsByInviteCode(code));
        return code;
    }

    User loadUser(UUID userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new NotFoundException("Пользователь не найден"));
    }
}
