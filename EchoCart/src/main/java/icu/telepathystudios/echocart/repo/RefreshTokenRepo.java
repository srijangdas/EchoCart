package icu.telepathystudios.echocart.repo;

import icu.telepathystudios.echocart.model.RefreshToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;
import java.util.UUID;

public interface RefreshTokenRepo extends JpaRepository<RefreshToken, Long> {
    Optional<RefreshToken> findByTokenHash(String tokenHash);
    @Modifying
    @Query("DELETE FROM RefreshToken rt WHERE rt.userId = :userId AND rt.deviceId = :deviceId")
    void deleteByUserIdAndDeviceId(@Param("userId") UUID userId,
                                   @Param("deviceId") String deviceId);
}
