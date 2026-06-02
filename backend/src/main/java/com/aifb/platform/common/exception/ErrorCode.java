package com.aifb.platform.common.exception;

import org.springframework.http.HttpStatus;

/**
 * Stable, machine-readable error codes. Clients switch on {@link #code()},
 * never on free-text messages.
 */
public enum ErrorCode {
    // Generic
    VALIDATION_FAILED("VALIDATION_FAILED", HttpStatus.BAD_REQUEST),
    NOT_FOUND("NOT_FOUND", HttpStatus.NOT_FOUND),
    CONFLICT("CONFLICT", HttpStatus.CONFLICT),
    FORBIDDEN("FORBIDDEN", HttpStatus.FORBIDDEN),
    UNAUTHORIZED("UNAUTHORIZED", HttpStatus.UNAUTHORIZED),
    INTERNAL_ERROR("INTERNAL_ERROR", HttpStatus.INTERNAL_SERVER_ERROR),
    BAD_REQUEST("BAD_REQUEST", HttpStatus.BAD_REQUEST),

    // Auth
    AUTH_INVALID_CREDENTIALS("AUTH_INVALID_CREDENTIALS", HttpStatus.UNAUTHORIZED),
    AUTH_EMAIL_TAKEN("AUTH_EMAIL_TAKEN", HttpStatus.CONFLICT),
    AUTH_TOKEN_INVALID("AUTH_TOKEN_INVALID", HttpStatus.UNAUTHORIZED),
    AUTH_TOKEN_EXPIRED("AUTH_TOKEN_EXPIRED", HttpStatus.UNAUTHORIZED),
    AUTH_REFRESH_INVALID("AUTH_REFRESH_INVALID", HttpStatus.UNAUTHORIZED),
    AUTH_REFRESH_REUSE_DETECTED("AUTH_REFRESH_REUSE_DETECTED", HttpStatus.UNAUTHORIZED),
    AUTH_USER_BLOCKED("AUTH_USER_BLOCKED", HttpStatus.FORBIDDEN),
    AUTH_RESET_CODE_INVALID("AUTH_RESET_CODE_INVALID", HttpStatus.BAD_REQUEST);

    private final String code;
    private final HttpStatus status;

    ErrorCode(String code, HttpStatus status) {
        this.code = code;
        this.status = status;
    }

    public String code() { return code; }
    public HttpStatus status() { return status; }
}
