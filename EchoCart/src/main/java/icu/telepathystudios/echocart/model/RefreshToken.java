package icu.telepathystudios.echocart.model;

import jakarta.persistence.*;
import lombok.Data;

import java.util.Date;
import java.util.UUID;

@Entity
@Table(name = "refresh_tokens")
@Data
public class RefreshToken {

    @Id @GeneratedValue
    private Long id;

    private UUID userId;
    private String tokenHash;
    private String deviceId;
    private Date expiresAt;
}
