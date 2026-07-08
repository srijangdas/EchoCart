package icu.telepathystudios.echocart.model.profile;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Entity
@Table(name = "customer_profile")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CustomerProfile {

    @Id
    private UUID userId;

    private String name;

    private String address;

    private String city;

    private String state;

    private String pincode;

    @Column(columnDefinition = "TEXT")
    private String profilePictureUrl;
}
