package icu.telepathystudios.echocart.dto.auth;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import lombok.Data;
import org.hibernate.validator.constraints.Length;

@Data
public class LoginRequest {
    @NotBlank(message = "Phone Number Required")
    @Length(min = 10, max = 13)
    private String phoneNo;

    @NotBlank(message = "Password is empty")
    private String password;
}
