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
        if(userRepo.findByPhoneNo(registerRequest.getPhoneNo()).isPresent()){
            throw new RuntimeException("Phone Number already exists with role: "+ userRepo.findByPhoneNo(registerRequest.getPhoneNo()).get().getRole());
        }

        User user = new User();
        user.setPhoneNo(registerRequest.getPhoneNo());
        user.setPassword(passwordEncoder.encode(registerRequest.getPassword()));
        user.setRole(role);

        userRepo.save(user);

        String token = jwtUtil.generateToken(user.getPhoneNo(), role);

        return new RegisterResponse(
                token
        );
    }

    public LoginResponse login(LoginRequest loginRequest, String role){
        if(userRepo.findByPhoneNo(loginRequest.getPhoneNo()).isEmpty()){
            throw new RuntimeException("Phone Number doesn't exist, register");
        }

        String userRole = userRepo.findByPhoneNo(loginRequest.getPhoneNo()).get().getRole();

        if(!passwordEncoder.matches(loginRequest.getPassword(), userRepo.findByPhoneNo(loginRequest.getPhoneNo()).get().getPassword())){
            throw new RuntimeException("Password doesn't match");
        }

        if(!userRole.equals(role)){
            throw new RuntimeException("Invalid Login, account exists as: "+ userRole);
        }

        String token = jwtUtil.generateToken(loginRequest.getPhoneNo(), role);

        return new LoginResponse(
            token
       );
    }
}
