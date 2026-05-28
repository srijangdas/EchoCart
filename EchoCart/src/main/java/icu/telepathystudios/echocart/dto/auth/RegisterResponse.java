package icu.telepathystudios.echocart.dto.auth;

import lombok.AllArgsConstructor;
import lombok.Data;


@Data
@AllArgsConstructor
public class RegisterResponse {
    private String token;
    private String refreshToken;
}
