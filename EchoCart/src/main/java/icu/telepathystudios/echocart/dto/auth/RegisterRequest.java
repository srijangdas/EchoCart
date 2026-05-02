package icu.telepathystudios.echocart.dto.auth;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;
import org.hibernate.validator.constraints.Length;

@Data
public class RegisterRequest {
    @NotBlank(message = "Phone Number Required")
    @Length(min = 10, max = 13)
    private String phoneNo;

    @NotBlank(message = "Password is Required")
    @Size(min=6, message = "Passwords should be at least 6 characters long.")
    private String password;
}
