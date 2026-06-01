package com.aifb.platform.common.exception;

public class NotFoundException extends DomainException {
    public NotFoundException(String message) {
        super(ErrorCode.NOT_FOUND, message);
    }
}
