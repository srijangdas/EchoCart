package icu.telepathystudios.echocart.repo;

import icu.telepathystudios.echocart.model.profile.PartnerProfile;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface PartnerProfileRepo extends JpaRepository<PartnerProfile, UUID> {
}
