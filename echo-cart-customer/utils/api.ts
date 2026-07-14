// utils/api.ts

const BASE_URL = "https://api.echocart.in";
const TOKEN_COOKIE = "token";
const REFRESH_TOKEN_COOKIE = "refreshToken";
const DEVICE_ID_COOKIE = "X-Device-Id";

const readCookie = (name: string): string | null => {
  if (typeof document === "undefined") return null;
  const match = document.cookie.match(new RegExp(`(?:^|; )${name}=([^;]*)`));
  return match ? decodeURIComponent(match[1]) : null;
};

const writeCookie = (name: string, value: string) => {
  if (typeof document === "undefined") return;
  document.cookie = `${name}=${encodeURIComponent(value)}; path=/; SameSite=Lax; max-age=${60 * 60 * 24 * 7}`;
};

const eraseCookie = (name: string) => {
  if (typeof document === "undefined") return;
  document.cookie = `${name}=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT`;
};

export const getDeviceId = () => {
  if (typeof window === "undefined") return "";

  let deviceId = localStorage.getItem(DEVICE_ID_COOKIE);
  if (!deviceId) {
    deviceId = crypto.randomUUID();
    localStorage.setItem(DEVICE_ID_COOKIE, deviceId);
    writeCookie(DEVICE_ID_COOKIE, deviceId);
  }
  return deviceId;
};

export const getTokens = () => {
  if (typeof window === "undefined") {
    return { token: null, refreshToken: null };
  }

  const token = localStorage.getItem(TOKEN_COOKIE) || readCookie(TOKEN_COOKIE);
  const refreshToken =
    localStorage.getItem(REFRESH_TOKEN_COOKIE) ||
    readCookie(REFRESH_TOKEN_COOKIE);

  return { token, refreshToken };
};

export const setTokens = (token: string, refreshToken: string) => {
  if (typeof window === "undefined") return;

  localStorage.setItem(TOKEN_COOKIE, token);
  localStorage.setItem(REFRESH_TOKEN_COOKIE, refreshToken);
  writeCookie(TOKEN_COOKIE, token);
  writeCookie(REFRESH_TOKEN_COOKIE, refreshToken);
};

export const checkCustomerProfile = async (token: string | null) => {
  if (typeof window === "undefined" || !token) {
    return { exists: false, data: null };
  }

  try {
    const response = await fetch(`${BASE_URL}/api/profile/customer`, {
      method: "GET",
      headers: {
        Authorization: `Bearer ${token}`,
      },
    });

    if (!response.ok) {
      return { exists: false, data: null };
    }

    const data = await response.json().catch(() => null);
    const exists = Boolean(
      data && typeof data === "object" && Object.keys(data).length > 0,
    );

    return { exists, data };
  } catch (error) {
    console.error("Failed to check customer profile:", error);
    return { exists: false, data: null };
  }
};

export const clearAuth = () => {
  if (typeof window === "undefined") return;

  localStorage.clear();
  sessionStorage.clear();
  eraseCookie(TOKEN_COOKIE);
  eraseCookie(REFRESH_TOKEN_COOKIE);
  eraseCookie(DEVICE_ID_COOKIE);
};
