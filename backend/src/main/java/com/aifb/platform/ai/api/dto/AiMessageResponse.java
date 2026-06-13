package com.aifb.platform.ai.api.dto;
import java.util.List;
public record AiMessageResponse(String role, String content, List<String> suggestedActions) {}
