package com.aifb.platform.support;

import com.aifb.platform.auth.domain.Role;
import com.aifb.platform.auth.domain.User;
import com.aifb.platform.auth.repository.UserRepository;
import com.aifb.platform.common.security.jwt.JwtService;
import org.springframework.stereotype.Component;

import java.util.Set;
import java.util.UUID;

@Component
public class TestAuth {

    private final UserRepository userRepository;
    private final JwtService jwtService;

    public TestAuth(UserRepository userRepository, JwtService jwtService) {
        this.userRepository = userRepository;
        this.jwtService = jwtService;
    }

    public record AuthedUser(UUID id, String email, String bearer) {}

    public AuthedUser createUser() {
        String email = "user-" + UUID.randomUUID() + "@example.com";
        User user = new User(email, "Test User", "x", Set.of(Role.USER));
        userRepository.saveAndFlush(user);
        String token = jwtService.issueAccessToken(
                user.getId(), email, Set.of("USER"), 0);
        return new AuthedUser(user.getId(), email, "Bearer " + token);
    }
}
