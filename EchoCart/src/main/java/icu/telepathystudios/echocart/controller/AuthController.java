package icu.telepathystudios.echocart.controller;

import icu.telepathystudios.echocart.dto.auth.*;
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

    @PostMapping("/register/{role}")
    public RegisterResponse register(
            @PathVariable String role,
            @Valid @RequestBody RegisterRequest request,
            @RequestHeader("X-Device-Id") String deviceId
    ) {

        role = role.toUpperCase();

        validateRole(role);

        return authService.register(request, role, deviceId);
    }

    @PostMapping("/login/{role}")
    public LoginResponse login(
            @PathVariable String role,
            @Valid @RequestBody LoginRequest request,
            @RequestHeader("X-Device-Id") String deviceId
    ) {

        role = role.toUpperCase();

        validateRole(role);

        return authService.login(request, role, deviceId);
    }

    @PostMapping("/login/refresh")
    public LoginResponse refresh(
            @RequestBody RefreshRequest request,
            @RequestHeader("X-Device-Id") String deviceId
    ) {
        return authService.refreshLogin(
                request.getRefreshToken(),
                deviceId
        );
    }

    private void validateRole(String role) {
        if (!role.equals("USER")
                && !role.equals("DELIVERY")) {
            throw new RuntimeException("Invalid role");
        }
    }

    //Write logout endpoint later
}
