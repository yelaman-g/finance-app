package com.aifb.platform.common.domain;

import java.math.BigDecimal;
import java.util.Map;

public final class ExchangeRate {

    private ExchangeRate() {}

    private static final Map<Currency, BigDecimal> RATES = Map.of(
            Currency.KZT, BigDecimal.ONE,
            Currency.RUB, new BigDecimal("0.21"),
            Currency.USD, new BigDecimal("470.0"),
            Currency.AED, new BigDecimal("128.0"),
            Currency.CNY, new BigDecimal("65.0")
    );

    public static BigDecimal convert(BigDecimal amount, Currency from, Currency to) {
        if (from == to) return amount;
        BigDecimal kzt = amount.multiply(RATES.get(from));
        return kzt.divide(RATES.get(to), 2, java.math.RoundingMode.HALF_UP);
    }

    public static BigDecimal convert(long amount, Currency from, Currency to) {
        return convert(BigDecimal.valueOf(amount), from, to);
    }

    public static String symbol(Currency currency) {
        return switch (currency) {
            case KZT -> "₸";
            case RUB -> "₽";
            case USD -> "$";
            case AED -> "د.إ";
            case CNY -> "¥";
        };
    }
}
