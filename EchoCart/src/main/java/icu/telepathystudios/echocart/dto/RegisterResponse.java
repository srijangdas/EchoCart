package icu.telepathystudios.echocart.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

import java.util.UUID;

@Data
@AllArgsConstructor
public class RegisterResponse {
    private UUID userId;
    private String email;
    private String role;
    private String token;
}
