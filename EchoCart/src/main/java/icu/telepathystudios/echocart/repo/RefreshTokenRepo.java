package icu.telepathystudios.echocart.repo;

import icu.telepathystudios.echocart.model.auth.RefreshToken;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Date;
import java.util.Optional;
import java.util.UUID;

public interface RefreshTokenRepo extends JpaRepository<RefreshToken, Long> {
    Optional<RefreshToken> findByTokenHash(String tokenHash);
    @Modifying
    @Query("DELETE FROM RefreshToken rt WHERE rt.userId = :userId AND rt.deviceId = :deviceId")
    void deleteByUserIdAndDeviceId(@Param("userId") UUID userId,
                                   @Param("deviceId") String deviceId);

    Optional<RefreshToken> findByUserIdAndDeviceId(
            UUID userId,
            String deviceId
    );

    @Modifying
    @Query("""
    UPDATE RefreshToken rt
    SET rt.tokenHash = :tokenHash,
        rt.expiresAt = :expiresAt
    WHERE rt.userId = :userId
      AND rt.deviceId = :deviceId
""")
    void updateRefreshToken(
            @Param("userId") UUID userId,
            @Param("deviceId") String deviceId,
            @Param("tokenHash") String tokenHash,
            @Param("expiresAt") Date expiresAt
    );
}
