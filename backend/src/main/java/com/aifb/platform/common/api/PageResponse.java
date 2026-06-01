package com.aifb.platform.common.api;

import org.springframework.data.domain.Page;

import java.util.List;

/**
 * Cursor-style page envelope used inside {@link ApiResponse#data()} for list endpoints.
 * Even when backed by Spring Data {@link Page}, expose only stable fields the
 * client needs — never leak {@code Pageable} internals.
 */
public record PageResponse<T>(
        List<T> items,
        int page,
        int size,
        long total,
        boolean hasNext) {

    public static <T> PageResponse<T> from(Page<T> page) {
        return new PageResponse<>(
                page.getContent(),
                page.getNumber(),
                page.getSize(),
                page.getTotalElements(),
                page.hasNext());
    }
}
