package icu.telepathystudios.echocart.service;

import icu.telepathystudios.echocart.dto.profile.CustomerProfileResponse;
import icu.telepathystudios.echocart.dto.profile.PartnerProfileRequest;
import icu.telepathystudios.echocart.dto.profile.PartnerProfileResponse;
import icu.telepathystudios.echocart.dto.profile.CustomerProfileRequest;
import icu.telepathystudios.echocart.model.User;
import icu.telepathystudios.echocart.model.profile.CustomerProfile;
import icu.telepathystudios.echocart.model.profile.PartnerProfile;
import icu.telepathystudios.echocart.repo.CustomerProfileRepo;
import icu.telepathystudios.echocart.repo.PartnerProfileRepo;
import icu.telepathystudios.echocart.repo.UserRepo;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Service;


@Service
@RequiredArgsConstructor
public class ProfileService {

    private final UserRepo userRepo;
    private final CustomerProfileRepo customerProfileRepo;
    private final PartnerProfileRepo partnerProfileRepo;

    public CustomerProfileResponse setUser(CustomerProfileRequest request) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();

        String phoneNo = auth.getName();

        User user = userRepo.findByPhoneNo(phoneNo).orElseThrow(
                ()->
                        new RuntimeException("User not found")
        );

        if(!user.getRole().equals("USER")){
            throw new RuntimeException("Customer Allowed Only!");
        }

        if (customerProfileRepo
                .existsById(user.getId())) {

            throw new RuntimeException(
                    "Profile already exists"
            );
        }

        CustomerProfile profile =
                new CustomerProfile();

        profile.setUserId(user.getId());

        profile.setName(request.getName());
        profile.setAddress(request.getAddress());
        profile.setCity(request.getCity());
        profile.setState(request.getState());
        profile.setPincode(request.getPincode());

        profile.setProfilePictureUrl(
                request.getProfilePictureUrl()
        );
                customerProfileRepo.save(profile);

        return new CustomerProfileResponse(
                        profile.getName(),
                        profile.getAddress(),
                        profile.getCity(),
                        profile.getState(),
                        profile.getPincode(),
                        profile.getProfilePictureUrl(),
                        user.getEnabled()
                );

    }

    public CustomerProfileResponse getUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();

        String phoneNo = auth.getName();

        User user = userRepo.findByPhoneNo(phoneNo).orElseThrow(
                ()->
                        new RuntimeException("User not found")
        );
        if(!user.getRole().equals("USER")){
            throw new RuntimeException("Customer Allowed Only!");
        }

        CustomerProfile profile =customerProfileRepo.findById(user.getId())
                .orElseThrow(()-> new RuntimeException("User not found"));

        return new CustomerProfileResponse(
                profile.getName(),
                profile.getAddress(),
                profile.getCity(),
                profile.getState(),
                profile.getPincode(),
                profile.getProfilePictureUrl(),
                user.getEnabled()
        );
    }

    public PartnerProfileResponse setDelivery(PartnerProfileRequest request) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();

        String phoneNo = auth.getName();

        User user = userRepo.findByPhoneNo(phoneNo).orElseThrow(
                ()->
                    new RuntimeException("User not found")
        );

        if(!user.getRole().equals("DELIVERY")){
            throw new RuntimeException("Delivery Partner Allowed Only!");
        }

        if (customerProfileRepo
                .existsById(user.getId())) {

            throw new RuntimeException(
                    "Profile already exists"
            );
        }

        PartnerProfile profile =
                new PartnerProfile();

        profile.setUserId(user.getId());

        profile.setName(request.getName());
        profile.setAddress(request.getAddress());
        profile.setCity(request.getCity());

        profile.setAadhaarNumber(
                request.getAadhaarNumber());

        profile.setPanNumber(
                request.getPanNumber());

        profile.setLicenseNumber(
                request.getLicenseNumber());

        profile.setVehicleNumber(
                request.getVehicleNumber());

        profile.setBankAccountNumber(
                request.getBankAccountNumber());

        profile.setProfilePicture(
                request.getProfilePicture());

        partnerProfileRepo.save(profile);

        return
                new PartnerProfileResponse(
                        profile.getName(),
                        profile.getAddress(),
                        profile.getCity(),
                        profile.getVehicleNumber(),
                        profile.getProfilePicture(),
                        user.getEnabled()
                );
    }

    public PartnerProfileResponse getDelivery() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();

        String phoneNo = auth.getName();

        User user = userRepo.findByPhoneNo(phoneNo).orElseThrow(
                ()->
                        new RuntimeException("User not found")
        );
        if(!user.getRole().equals("DELIVERY")){
            throw new RuntimeException("Delivery Partner Allowed Only!");
        }

        PartnerProfile profile =
                partnerProfileRepo
                        .findById(user.getId())
                        .orElseThrow(() ->
                                new RuntimeException(
                                        "Profile not found"
                                ));

        return new PartnerProfileResponse(
                profile.getName(),
                profile.getAddress(),
                profile.getCity(),
                profile.getVehicleNumber(),
                profile.getProfilePicture(),
                user.getEnabled()
        );


    }

    public CustomerProfileResponse updateProfile(CustomerProfileRequest request) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();

        String phoneNo = auth.getName();

        User user = userRepo.findByPhoneNo(phoneNo).orElseThrow(
                ()->
                        new RuntimeException("User not found")
        );

        if(!user.getRole().equals("USER")){
            throw new RuntimeException("Customer Allowed Only!");
        }

        CustomerProfile profile = customerProfileRepo.findById(user.getId())
                .orElseThrow(() -> new RuntimeException("Profile does not exist"));

        profile.setName(request.getName());
        profile.setAddress(request.getAddress());
        profile.setCity(request.getCity());
        profile.setState(request.getState());
        profile.setPincode(request.getPincode());

        profile.setProfilePictureUrl(
                request.getProfilePictureUrl()
        );
        customerProfileRepo.save(profile);

        return new CustomerProfileResponse(
                profile.getName(),
                profile.getAddress(),
                profile.getCity(),
                profile.getState(),
                profile.getPincode(),
                profile.getProfilePictureUrl(),
                user.getEnabled()
        );

    }

    public void updateLocation(String coordinates) {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();

        String phoneNo = auth.getName();

        User user = userRepo.findByPhoneNo(phoneNo).orElseThrow(
                ()->
                        new RuntimeException("User not found")
        );

        if(!user.getRole().equals("USER")){
            throw new RuntimeException("Customer Allowed Only!");
        }

        CustomerProfile profile = customerProfileRepo.findById(user.getId())
                .orElseThrow(() -> new RuntimeException("Profile does not exist"));

        profile.setCoordinates(coordinates);

        customerProfileRepo.save(profile);
    }
}
