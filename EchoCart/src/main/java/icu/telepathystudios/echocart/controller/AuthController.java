package icu.telepathystudios.echocart.controller;

import icu.telepathystudios.echocart.dto.auth.LoginRequest;
import icu.telepathystudios.echocart.dto.auth.LoginResponse;
import icu.telepathystudios.echocart.dto.auth.RegisterRequest;
import icu.telepathystudios.echocart.dto.auth.RegisterResponse;
import icu.telepathystudios.echocart.service.AuthService;
import jakarta.validation.Valid;
import lombok.AllArgsConstructor;
import org.springframework.web.bind.annotation.*;


@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*")
@AllArgsConstructor
public class AuthController {
    private final AuthService authService;

    @PostMapping("/register/d")
    public String test() {
        System.out.println("Here");
        return "HIT";
    }
    @PostMapping("/register/user")
    public RegisterResponse registerUser(@Valid @RequestBody RegisterRequest request){
        return authService.register(request, "USER");
    }

    @PostMapping("/register/delivery")
    public RegisterResponse registerDelivery(@Valid @RequestBody RegisterRequest request){
        return authService.register(request, "DELIVERY");
    }

    @PostMapping("/login/user")
    public LoginResponse loginUser(@Valid @RequestBody LoginRequest request){
        return authService.login(request, "USER");
    }

    @PostMapping("/login/delivery")
    public LoginResponse loginDelivery(@Valid @RequestBody LoginRequest request){
        return authService.login(request, "DELIVERY");
    }
}
