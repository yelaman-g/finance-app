package com.aifb.platform.auth.api;

import com.aifb.platform.auth.api.dto.AuthResponse;
import com.aifb.platform.auth.api.dto.ForgotPasswordRequest;
import com.aifb.platform.auth.api.dto.ForgotPasswordResponse;
import com.aifb.platform.auth.api.dto.LoginRequest;
import com.aifb.platform.auth.api.dto.LogoutRequest;
import com.aifb.platform.auth.api.dto.RefreshTokenRequest;
import com.aifb.platform.auth.api.dto.RegisterRequest;
import com.aifb.platform.auth.api.dto.ResetPasswordRequest;
import com.aifb.platform.auth.api.dto.UserResponse;
import com.aifb.platform.auth.service.AuthService;
import com.aifb.platform.auth.service.PasswordResetService;
import com.aifb.platform.common.api.ApiResponse;
import com.aifb.platform.common.security.AuthPrincipal;
import com.aifb.platform.common.security.CurrentUser;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/auth")
@Validated
public class AuthController {

    private final AuthService authService;
    private final PasswordResetService passwordResetService;

    public AuthController(AuthService authService, PasswordResetService passwordResetService) {
        this.authService = authService;
        this.passwordResetService = passwordResetService;
    }

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<AuthResponse>> register(@Valid @RequestBody RegisterRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(authService.register(request)));
    }

    @PostMapping("/login")
    public ApiResponse<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        return ApiResponse.ok(authService.login(request));
    }

    @PostMapping("/refresh")
    public ApiResponse<AuthResponse> refresh(@Valid @RequestBody RefreshTokenRequest request) {
        return ApiResponse.ok(authService.refresh(request.refreshToken()));
    }

    @PostMapping("/logout")
    public ApiResponse<Void> logout(@Valid @RequestBody LogoutRequest request) {
        authService.logout(request.refreshToken());
        return ApiResponse.ok(null);
    }

    @PostMapping("/logout-all")
    public ApiResponse<Void> logoutAll(@CurrentUser AuthPrincipal principal) {
        authService.logoutAll(principal.userId());
        return ApiResponse.ok(null);
    }

    @PostMapping("/forgot-password")
    public ApiResponse<ForgotPasswordResponse> forgotPassword(
            @Valid @RequestBody ForgotPasswordRequest request) {
        return ApiResponse.ok(passwordResetService.forgotPassword(request.email()));
    }

    @PostMapping("/reset-password")
    public ApiResponse<Void> resetPassword(@Valid @RequestBody ResetPasswordRequest request) {
        passwordResetService.reset(request.email(), request.code(), request.newPassword());
        return ApiResponse.ok(null);
    }

    @GetMapping("/me")
    public ApiResponse<UserResponse> me(@CurrentUser AuthPrincipal principal) {
        return ApiResponse.ok(authService.me(principal.userId()));
    }
}
