package com.aifb.platform.event.api;

import com.aifb.platform.common.api.ApiResponse;
import com.aifb.platform.common.domain.Scope;
import com.aifb.platform.common.security.AuthPrincipal;
import com.aifb.platform.common.security.CurrentUser;
import com.aifb.platform.event.api.dto.CreateEventRequest;
import com.aifb.platform.event.api.dto.EventOccurrenceResponse;
import com.aifb.platform.event.api.dto.EventResponse;
import com.aifb.platform.event.api.dto.UpdateEventRequest;
import com.aifb.platform.event.service.EventService;
import jakarta.validation.Valid;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/events")
public class EventController {

    private final EventService service;

    public EventController(EventService service) {
        this.service = service;
    }

    @GetMapping
    public ApiResponse<List<EventOccurrenceResponse>> list(
            @CurrentUser AuthPrincipal principal,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            @RequestParam(defaultValue = "PERSONAL") Scope scope) {
        return ApiResponse.ok(service.list(principal.userId(), from, to, scope));
    }

    @PostMapping
    public ApiResponse<EventResponse> create(@CurrentUser AuthPrincipal principal,
                                             @Valid @RequestBody CreateEventRequest request) {
        return ApiResponse.ok(service.create(principal.userId(), request));
    }

    @PutMapping("/{id}")
    public ApiResponse<EventResponse> update(@CurrentUser AuthPrincipal principal,
                                             @PathVariable UUID id,
                                             @Valid @RequestBody UpdateEventRequest request) {
        return ApiResponse.ok(service.update(principal.userId(), id, request));
    }

    @DeleteMapping("/{id}")
    public ApiResponse<Void> delete(@CurrentUser AuthPrincipal principal, @PathVariable UUID id) {
        service.delete(principal.userId(), id);
        return ApiResponse.ok(null);
    }
}
