import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";
import { isTokenExpired } from "./utils/isTokenExpired";

export const runtime = "experimental-edge";

const PUBLIC_PATHS = ["/login", "/register"];
const AUTH_COOKIE = "token";
const REFRESH_COOKIE = "refreshToken";
const DEVICE_ID_COOKIE = "X-Device-Id";

const cookieOptions = {
  path: "/",
  sameSite: "lax" as const,
  httpOnly: false,
  secure: false,
};

export async function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  if (
    pathname.startsWith("/_next") ||
    pathname.startsWith("/api") ||
    pathname.startsWith("/favicon.ico") ||
    pathname.includes(".") ||
    PUBLIC_PATHS.includes(pathname)
  ) {
    return NextResponse.next();
  }

  const accessToken = request.cookies.get(AUTH_COOKIE)?.value ?? null;
  const refreshToken = request.cookies.get(REFRESH_COOKIE)?.value ?? null;
  const deviceId = request.cookies.get(DEVICE_ID_COOKIE)?.value ?? null;

  try {
    if (!accessToken || isTokenExpired(accessToken)) {
      if (refreshToken) {
        try {
          const refreshResponse = await fetch(
            "https://api.echocart.in/api/auth/login/refresh",
            {
              method: "POST",
              headers: {
                "Content-Type": "application/json",
                "X-Device-Id": deviceId || "unknown-device",
              },
              body: JSON.stringify({
                refreshToken,
                deviceId: deviceId || "unknown-device",
              }),
            },
          );

          if (!refreshResponse.ok) {
            throw new Error(`Refresh failed: ${refreshResponse.status}`);
          }

          const data = await refreshResponse.json();

          if (data?.token) {
            const response = NextResponse.next();
            response.cookies.set(AUTH_COOKIE, data.token, cookieOptions);
            response.cookies.set(
              REFRESH_COOKIE,
              data.refreshToken || refreshToken,
              cookieOptions,
            );
            if (deviceId) {
              response.cookies.set(DEVICE_ID_COOKIE, deviceId, cookieOptions);
            }
            return response;
          }
        } catch (error) {
          console.error("Token refresh failed in middleware:", error);
        }
      }

      const loginUrl = request.nextUrl.clone();
      loginUrl.pathname = "/login";
      loginUrl.searchParams.set("redirect", pathname);

      const response = NextResponse.redirect(loginUrl);
      response.cookies.delete(AUTH_COOKIE);
      response.cookies.delete(REFRESH_COOKIE);
      return response;
    }

    return NextResponse.next();
  } catch (error) {
    // Edge Runtime compatibility error - allow request to proceed
    console.error("Middleware error:", error);
    return NextResponse.next();
  }
}

export const config = {
  matcher: [
    "/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp|ico|css|js|map)$).*)",
  ],
};
