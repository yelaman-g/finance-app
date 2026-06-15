package com.aifb.platform.auth.api;

import com.aifb.platform.auth.api.dto.UpdateCurrencyRequest;
import com.aifb.platform.auth.api.dto.UpdateThemeRequest;
import com.aifb.platform.auth.api.dto.UserSettingsResponse;
import com.aifb.platform.auth.domain.User;
import com.aifb.platform.auth.repository.UserRepository;
import com.aifb.platform.auth.service.UserSettingsService;
import com.aifb.platform.common.api.ApiResponse;
import com.aifb.platform.common.exception.NotFoundException;
import com.aifb.platform.common.security.AuthPrincipal;
import com.aifb.platform.common.security.CurrentUser;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/settings")
public class UserSettingsController {

    private final UserSettingsService service;
    private final UserRepository userRepository;

    public UserSettingsController(UserSettingsService service, UserRepository userRepository) {
        this.service = service;
        this.userRepository = userRepository;
    }

    @GetMapping
    public ApiResponse<UserSettingsResponse> get(@CurrentUser AuthPrincipal principal) {
        return ApiResponse.ok(service.get(loadUser(principal)));
    }

    @PutMapping("/currency")
    public ApiResponse<UserSettingsResponse> updateCurrency(
            @CurrentUser AuthPrincipal principal,
            @Valid @RequestBody UpdateCurrencyRequest request) {
        return ApiResponse.ok(service.updateCurrency(loadUser(principal), request.currency()));
    }

    @PutMapping("/theme")
    public ApiResponse<UserSettingsResponse> updateTheme(
            @CurrentUser AuthPrincipal principal,
            @Valid @RequestBody UpdateThemeRequest request) {
        return ApiResponse.ok(service.updateTheme(loadUser(principal), request.theme()));
    }

    private User loadUser(AuthPrincipal principal) {
        return userRepository.findById(principal.userId())
                .orElseThrow(() -> new NotFoundException("Пользователь не найден"));
    }
}
