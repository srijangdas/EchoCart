package icu.telepathystudios.echocart.dto.auth;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class LoginRequest {
    @NotBlank(message = "Email Required")
    @Email(message = "Invalid email format")
    private String email;

    @NotBlank(message = "Password is empty")
    private String password;
}
