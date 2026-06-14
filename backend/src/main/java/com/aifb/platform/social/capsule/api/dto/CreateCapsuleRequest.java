package com.aifb.platform.social.capsule.api.dto;

import jakarta.validation.constraints.Future;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;

public record CreateCapsuleRequest(
        @NotBlank @Size(max = 200) String title,
        @NotBlank @Size(max = 4000) String message,
        @NotNull @Future LocalDate openDate
) {}
