package com.aifb.platform.notification.api;

import com.aifb.platform.common.api.ApiResponse;
import com.aifb.platform.common.security.AuthPrincipal;
import com.aifb.platform.common.security.CurrentUser;
import com.aifb.platform.notification.api.dto.RegisterTokenRequest;
import com.aifb.platform.notification.domain.DevicePlatform;
import com.aifb.platform.notification.service.NotificationService;
import com.aifb.platform.notification.service.PushSender;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/v1/push")
public class PushController {

    private final NotificationService service;
    private final PushSender pushSender;
    private final com.aifb.platform.notification.repository.DeviceTokenRepository tokens;

    public PushController(NotificationService service, PushSender pushSender,
                          com.aifb.platform.notification.repository.DeviceTokenRepository tokens) {
        this.service = service;
        this.pushSender = pushSender;
        this.tokens = tokens;
    }

    @PostMapping("/tokens")
    public ApiResponse<Void> register(@CurrentUser AuthPrincipal principal,
                                      @Valid @RequestBody RegisterTokenRequest req) {
        service.registerToken(principal.userId(), req.token(),
                req.platform() == null ? DevicePlatform.ANDROID : req.platform());
        return ApiResponse.ok(null);
    }

    @DeleteMapping("/tokens/{token}")
    public ApiResponse<Void> remove(@CurrentUser AuthPrincipal principal, @PathVariable String token) {
        service.removeToken(principal.userId(), token);
        return ApiResponse.ok(null);
    }

    @PostMapping("/test")
    public ApiResponse<Void> test(@CurrentUser AuthPrincipal principal) {
        tokens.findByUserIdIn(java.util.List.of(principal.userId())).forEach(dt ->
                pushSender.send(dt.getToken(), "Тест", "Проверка push", Map.of("type", "TEST")));
        return ApiResponse.ok(null);
    }
}
