package com.aifb.platform.common.exception;

public class ConflictException extends DomainException {
    public ConflictException(ErrorCode code, String message) {
        super(code, message);
    }

    public ConflictException(String message) {
        super(ErrorCode.CONFLICT, message);
    }
}
