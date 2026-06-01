package com.aifb.platform.common.exception;

import java.util.Map;

/**
 * Base exception for all expected business errors. Translated to the
 * uniform error envelope by {@link GlobalExceptionHandler}.
 */
public class DomainException extends RuntimeException {

    private final ErrorCode errorCode;
    private final Map<String, String> fields;

    public DomainException(ErrorCode errorCode, String message) {
        this(errorCode, message, null);
    }

    public DomainException(ErrorCode errorCode, String message, Map<String, String> fields) {
        super(message);
        this.errorCode = errorCode;
        this.fields = fields;
    }

    public ErrorCode errorCode() { return errorCode; }
    public Map<String, String> fields() { return fields; }
}
