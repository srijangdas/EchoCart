package icu.telepathystudios.echocart.controller;

import icu.telepathystudios.echocart.dto.profile.CustomerProfileResponse;
import icu.telepathystudios.echocart.dto.profile.PartnerProfileRequest;
import icu.telepathystudios.echocart.dto.profile.PartnerProfileResponse;
import icu.telepathystudios.echocart.dto.profile.CustomerProfileRequest;
import icu.telepathystudios.echocart.service.ProfileService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("api/profile")
@CrossOrigin("*")
@RequiredArgsConstructor
public class ProfileController {
    private final ProfileService profileService;

    @PostMapping("/customer")
    public CustomerProfileResponse setUser(@RequestBody CustomerProfileRequest request){
        return profileService.setUser(request);
    }

    @GetMapping("/customer")
    public CustomerProfileResponse getUser(){
        return profileService.getUser();
    }

    @PostMapping("/delivery")
    public PartnerProfileResponse setDelivery(@RequestBody PartnerProfileRequest request){
        return profileService.setDelivery(request);
    }

    @GetMapping("/delivery")
    public PartnerProfileResponse getDelivery(){
        return profileService.getDelivery();
    }
}
