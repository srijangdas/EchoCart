package icu.telepathystudios.echocart.service;

import icu.telepathystudios.echocart.dto.RegisterRequest;
import icu.telepathystudios.echocart.dto.RegisterResponse;
import icu.telepathystudios.echocart.model.User;
import icu.telepathystudios.echocart.repo.UserRepo;
import icu.telepathystudios.echocart.util.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthService {
    private final UserRepo userRepo;
    private final JwtUtil jwtUtil;
    private final PasswordEncoder passwordEncoder;

    public RegisterResponse register(RegisterRequest registerRequest, String role)
    {
        if(userRepo.findByEmail(registerRequest.getEmail()).isPresent()){
            throw new RuntimeException("Email already exists");
        }

        User user = new User();
        user.setEmail(registerRequest.getEmail());
        user.setPassword(passwordEncoder.encode(registerRequest.getPassword()));
        user.setRole(role);

        userRepo.save(user);

        String token = jwtUtil.generateToken(user.getEmail(), role);

        return new RegisterResponse(
                user.getId(),
                user.getEmail(),
                user.getRole(),
                token
        );
    }
}
