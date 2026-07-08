package icu.telepathystudios.echocart.model.profile;

import jakarta.persistence.*;
import lombok.Data;

import java.util.UUID;

@Entity
@Table(name="partner_profile")
@Data
public class PartnerProfile {
    @Id
    private UUID userId;

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
