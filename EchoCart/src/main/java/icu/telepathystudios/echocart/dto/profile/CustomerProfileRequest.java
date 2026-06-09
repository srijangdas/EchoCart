package icu.telepathystudios.echocart.dto.profile;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class CustomerProfileRequest {

    @NotBlank
    private String name;

    private String address;

    private String city;

    private String state;

    private String pincode;

    private String profilePictureUrl;
}
