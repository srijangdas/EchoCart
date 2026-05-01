package icu.telepathystudios.echocart.dto;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class RegisterRequest {
    @NotBlank(message = "Email Required")
    @Email(message = "Invalid email format")
    private String email;

    @NotBlank(message = "Password is Required")
    @Size(min=6, message = "Passwords should be at least 6 characters long.")
    private String password;
}
