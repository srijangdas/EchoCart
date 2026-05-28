package icu.telepathystudios.echocart.dto.profile;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class CustomerProfileResponse {
    private String name;

    private String address;

    private String city;

    private String state;

    private String pincode;

    private String profilePictureUrl;

    private boolean profileCompleted;
}
