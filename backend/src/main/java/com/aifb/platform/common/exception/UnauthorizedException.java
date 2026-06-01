package com.aifb.platform.common.exception;

public class UnauthorizedException extends DomainException {
    public UnauthorizedException(ErrorCode code, String message) {
        super(code, message);
    }
}
