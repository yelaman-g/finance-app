package com.aifb.platform.ai.api.dto;
import com.aifb.platform.common.domain.Scope;
import java.time.LocalDate;
public record AnalyzeBudgetRequest(LocalDate from, LocalDate to, Scope scope) {}
