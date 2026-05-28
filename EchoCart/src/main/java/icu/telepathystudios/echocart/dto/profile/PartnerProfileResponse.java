package icu.telepathystudios.echocart.dto.profile;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class PartnerProfileResponse {
    private String name;
    private String address;
    private String city;

    private String vehicleNumber;
    private String profilePictureUrl;

    private boolean profileCompleted;
}
