package icu.telepathystudios.echocart.dto.profile;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class PartnerProfileRequest {
    @NotNull
    @NotEmpty
    private String name;
    private String address;
    private String city;
    private String aadhaarNumber;
    private String panNumber;
    private String licenseNumber;
    private String vehicleNumber;
    private String bankAccountNumber;
    private String profilePicture;
}
