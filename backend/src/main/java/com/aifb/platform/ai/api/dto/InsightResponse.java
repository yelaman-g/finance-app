package com.aifb.platform.ai.api.dto;
import java.math.BigDecimal;
public record InsightResponse(String id, String title, String description, String type,
                              BigDecimal impactValue, String impactLabel) {}
