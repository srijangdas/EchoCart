// utils/isTokenExpired.ts
export function isTokenExpired(token: string): boolean {
  try {
    const parts = token.split(".");
    if (parts.length !== 3) return true;

    // Decode base64url payload safely in Edge runtime
    const payload = JSON.parse(
      Buffer.from(parts[1], "base64").toString("utf-8"),
    );

    if (!payload.exp) return true;

    // Convert exp (seconds) to milliseconds and compare with current time
    const currentTime = Date.now();
    return currentTime >= payload.exp * 1000;
  } catch (error) {
    return true; // Treat malformed tokens as expired
  }
}
