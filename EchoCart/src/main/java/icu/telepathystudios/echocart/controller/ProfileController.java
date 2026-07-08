package icu.telepathystudios.echocart.controller;

import icu.telepathystudios.echocart.dto.profile.CustomerProfileResponse;
import icu.telepathystudios.echocart.dto.profile.PartnerProfileRequest;
import icu.telepathystudios.echocart.dto.profile.PartnerProfileResponse;
import icu.telepathystudios.echocart.dto.profile.CustomerProfileRequest;
import icu.telepathystudios.echocart.service.ProfileService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.enums.ParameterIn;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@Tag(name="Profile")
@RestController
@RequestMapping("api/profile")
@CrossOrigin("*")
@RequiredArgsConstructor
public class ProfileController {
    private final ProfileService profileService;

    @Operation(summary = "Add customer profile details")
    @Parameter(name="token", in = ParameterIn.HEADER, required = true)
    @PostMapping("/customer")
    public CustomerProfileResponse setUser(@RequestBody CustomerProfileRequest request){
        return profileService.setUser(request);
    }

    @Operation(summary = "Get customer profile details")
    @Parameter(name="token", in = ParameterIn.HEADER, required = true)
    @GetMapping("/customer")
    public CustomerProfileResponse getUser(){
        return profileService.getUser();
    }

    @Operation(summary = "Add Delivery Partner profile details")
    @Parameter(name="token", in = ParameterIn.HEADER, required = true)
    @PostMapping("/delivery")
    public PartnerProfileResponse setDelivery(@RequestBody PartnerProfileRequest request){
        return profileService.setDelivery(request);
    }

    @Operation(summary = "Get Delivery Partner profile details")
    @Parameter(name="token", in = ParameterIn.HEADER, required = true)
    @GetMapping("/delivery")
    public PartnerProfileResponse getDelivery(){
        return profileService.getDelivery();
    }
}
