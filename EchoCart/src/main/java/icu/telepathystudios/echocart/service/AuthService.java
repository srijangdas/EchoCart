package icu.telepathystudios.echocart.service;

import icu.telepathystudios.echocart.dto.auth.LoginRequest;
import icu.telepathystudios.echocart.dto.auth.LoginResponse;
import icu.telepathystudios.echocart.dto.auth.RegisterRequest;
import icu.telepathystudios.echocart.dto.auth.RegisterResponse;
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
            throw new RuntimeException("Email already exists with role: "+ userRepo.findByEmail(registerRequest.getEmail()).get().getRole());
        }

        User user = new User();
        user.setEmail(registerRequest.getEmail());
        user.setPassword(passwordEncoder.encode(registerRequest.getPassword()));
        user.setRole(role);

        userRepo.save(user);

        String token = jwtUtil.generateToken(user.getEmail(), role);

        return new RegisterResponse(
                token
        );
    }

    public LoginResponse login(LoginRequest loginRequest, String role){
        if(userRepo.findByEmail(loginRequest.getEmail()).isEmpty()){
            throw new RuntimeException("Email doesn't exist, register");
        }

        String userRole = userRepo.findByEmail(loginRequest.getEmail()).get().getRole();

        if(!passwordEncoder.matches(loginRequest.getPassword(), userRepo.findByEmail(loginRequest.getEmail()).get().getPassword())){
            throw new RuntimeException("Password doesn't match");
        }

        if(!userRole.equals(role)){
            throw new RuntimeException("Invalid Login, account exists as: "+ userRole);
        }

        String token = jwtUtil.generateToken(loginRequest.getEmail(), role);

        return new LoginResponse(
            token
       );
    }
}
