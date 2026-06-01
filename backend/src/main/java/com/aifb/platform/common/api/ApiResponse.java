package com.aifb.platform.common.api;

import com.fasterxml.jackson.annotation.JsonInclude;

import java.time.Instant;
import java.util.UUID;

/**
 * Unified response envelope for all REST endpoints.
 *
 * Shape: {@code { data, error, meta }}. Exactly one of {@code data} / {@code error}
 * is non-null on any given response.
 */
@JsonInclude(JsonInclude.Include.ALWAYS)
public record ApiResponse<T>(T data, ApiError error, ApiMeta meta) {

    public static <T> ApiResponse<T> ok(T data) {
        return new ApiResponse<>(data, null, ApiMeta.now());
    }

    public static <T> ApiResponse<T> ok(T data, ApiMeta meta) {
        return new ApiResponse<>(data, null, meta);
    }

    public static ApiResponse<Void> error(ApiError error) {
        return new ApiResponse<>(null, error, ApiMeta.now());
    }

    public record ApiMeta(String requestId, Instant ts) {
        public static ApiMeta now() {
            return new ApiMeta(UUID.randomUUID().toString(), Instant.now());
        }
    }
}
