package icu.telepathystudios.echocart.model;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import lombok.Data;

@Entity
@Data
public class DeliveryPartner {
    @Id
    private String id;
}
