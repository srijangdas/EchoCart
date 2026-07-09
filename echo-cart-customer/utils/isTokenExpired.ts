import { jwtDecode } from "jwt-decode";

interface JwtPayload {
  exp: number; // Expiration timestamp in seconds
}

export function isTokenExpired(token: string | null): boolean {
  if (!token) return true;

  try {
    const decoded = jwtDecode<JwtPayload>(token);
    const currentTime = Date.now() / 1000; // Convert milliseconds to seconds

    // If current time is greater than exp time, it's expired
    return decoded.exp < currentTime;
  } catch (error) {
    // If decoding fails, treat it as an invalid/expired token
    return true;
  }
}
