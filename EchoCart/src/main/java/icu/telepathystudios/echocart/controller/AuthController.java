package icu.telepathystudios.echocart.controller;

import icu.telepathystudios.echocart.dto.auth.LoginRequest;
import icu.telepathystudios.echocart.dto.auth.LoginResponse;
import icu.telepathystudios.echocart.dto.auth.RegisterRequest;
import icu.telepathystudios.echocart.dto.auth.RegisterResponse;
import icu.telepathystudios.echocart.service.AuthService;
import jakarta.validation.Valid;
import lombok.AllArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Map;


@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*")
@AllArgsConstructor
public class AuthController {
    private final AuthService authService;

    @PostMapping("/register/user")
    public RegisterResponse registerUser(@Valid @RequestBody RegisterRequest request){
        return authService.register(request, "USER");
    }

    @PostMapping("/register/delivery")
    public RegisterResponse registerDelivery(@Valid @RequestBody RegisterRequest request){
        return authService.register(request, "DELIVERY");
    }

    @PostMapping("/login/user")
    public LoginResponse loginUser(@Valid @RequestBody LoginRequest request, @RequestHeader("DeviceId") String deviceId){
        return authService.login(request, "USER", deviceId);
    }

    @PostMapping("/login/delivery")
    public LoginResponse loginDelivery(@Valid @RequestBody LoginRequest request, @RequestHeader("DeviceId") String deviceId){
        return authService.login(request, "DELIVERY", deviceId);
    }

    @PostMapping("/login/refresh")
    public LoginResponse loginRefresh(@RequestBody Map<String, String> body, @RequestHeader("DeviceId") String deviceId){
        return authService.refreshLogin(body.get("refreshToken"), deviceId);
    }

    //Write logout endpoint later
}
