package icu.telepathystudios.echocart.service;

import icu.telepathystudios.echocart.dto.auth.LoginRequest;
import icu.telepathystudios.echocart.dto.auth.LoginResponse;
import icu.telepathystudios.echocart.dto.auth.RegisterRequest;
import icu.telepathystudios.echocart.dto.auth.RegisterResponse;
import icu.telepathystudios.echocart.model.auth.RefreshToken;
import icu.telepathystudios.echocart.model.User;
import icu.telepathystudios.echocart.repo.RefreshTokenRepo;
import icu.telepathystudios.echocart.repo.UserRepo;
import icu.telepathystudios.echocart.util.JwtUtil;
import org.springframework.transaction.annotation.Transactional;
import lombok.RequiredArgsConstructor;
import org.apache.commons.codec.digest.DigestUtils;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.Date;
import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AuthService {
    private final UserRepo userRepo;
    private final JwtUtil jwtUtil;
    private final PasswordEncoder passwordEncoder;
    private final RefreshTokenRepo refreshTokenRepo;

    @Transactional
    public RegisterResponse register(RegisterRequest registerRequest, String role, String deviceId)
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

        String refreshToken = refreshTokenCreate(user, deviceId);

        return new RegisterResponse(
                token, refreshToken
        );
    }

    @Transactional
    public LoginResponse login(LoginRequest loginRequest, String role, String deviceId){
        User user = userRepo.findByPhoneNo(loginRequest.getPhoneNo())
                .orElseThrow(() -> new RuntimeException("Phone Number doesn't exist, register"));

        String userRole = user.getRole();

        if(!passwordEncoder.matches(loginRequest.getPassword(), user.getPassword())){
            throw new RuntimeException("Password doesn't match");
        }

        if(!userRole.equals(role)){
            throw new RuntimeException("Invalid Login, account exists as: "+ userRole);
        }

        String token = jwtUtil.generateToken(loginRequest.getPhoneNo(), role);

        String refreshToken = refreshTokenCreate(user, deviceId);

        return new LoginResponse(
            token, refreshToken
       );
    }

    @Transactional
    public LoginResponse refreshLogin(
            String refreshToken,
            String deviceId
    ) {

        String hash = hashToken(refreshToken);

        RefreshToken rt = refreshTokenRepo.findByTokenHash(hash)
                        .orElseThrow(() -> new RuntimeException("Refresh token doesn't exist"));

        if (rt.getExpiresAt().before(new Date())) {
            throw new RuntimeException("Refresh token expired");
        }

        User user = userRepo.findById(rt.getUserId()).orElseThrow(() ->
                        new RuntimeException("Internal Error with token"));

        String finalRefreshToken = refreshToken;

        Date newExpiry =
                new Date(System.currentTimeMillis()
                        + 30L * 24 * 60 * 60 * 1000);

        if (shouldRefreshToken(rt.getExpiresAt())) {

            finalRefreshToken = jwtUtil.generateRefreshToken();

            rt.setTokenHash(hashToken(finalRefreshToken));
        }

        rt.setExpiresAt(newExpiry);

        refreshTokenRepo.save(rt);

        String newAccess = jwtUtil.generateToken(user.getPhoneNo(), user.getRole());

        return new LoginResponse(
                newAccess,
                finalRefreshToken
        );
    }

    @Transactional
    public String refreshTokenCreate(User user, String deviceId){

        String refreshToken = jwtUtil.generateRefreshToken();

        String hash = hashToken(refreshToken);

        Date expiry = new Date(System.currentTimeMillis()
                        + 30L * 24 * 60 * 60 * 1000);

        Optional<RefreshToken> existing = refreshTokenRepo.findByUserIdAndDeviceId(
                                user.getId(),
                                deviceId);

        RefreshToken rt = existing.orElse(new RefreshToken());

        rt.setUserId(user.getId());
        rt.setDeviceId(deviceId);
        rt.setTokenHash(hash);
        rt.setExpiresAt(expiry);

        refreshTokenRepo.save(rt);

        return refreshToken;
    }

    //Change it later
    public void logout(UUID userId, String deviceId){
        refreshTokenRepo.deleteByUserIdAndDeviceId(userId, deviceId);
    }

    public boolean shouldRefreshToken(Date expiresAt){
        long sevenDaysMillis = 7L * 24 * 60 * 60 * 1000;

        long timeLeft =  expiresAt.getTime() - System.currentTimeMillis();

        //true if >>7 days left
        return timeLeft <= sevenDaysMillis;
    }

    public String hashToken(String token) {
        return  DigestUtils.sha256Hex(token);
    }
}
