package com.aifb.platform.finance.transaction.api.dto;

import com.aifb.platform.finance.category.domain.CategoryType;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PastOrPresent;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.UUID;

public record CreateTransactionRequest(
        @NotNull UUID categoryId,
        @NotNull CategoryType type,
        @NotNull @DecimalMin(value = "0.01") @Digits(integer = 13, fraction = 2) BigDecimal amount,
        @Size(max = 255) String note,
        @NotNull @PastOrPresent LocalDate occurredOn,
        boolean shared) {
}
