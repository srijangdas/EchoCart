package icu.telepathystudios.echocart.controller;

import icu.telepathystudios.echocart.dto.RegisterRequest;
import icu.telepathystudios.echocart.dto.RegisterResponse;
import icu.telepathystudios.echocart.service.AuthService;
import icu.telepathystudios.echocart.util.JwtUtil;
import jakarta.validation.Valid;
import lombok.AllArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;


@RestController
@RequestMapping("/auth")
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
}
