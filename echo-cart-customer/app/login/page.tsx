"use client";

import React, { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { getDeviceId, setTokens, getTokens, clearAuth } from "@/utils/api"; // Using standard relative paths if @ fails: '../utils/api'

export default function Login() {
  const router = useRouter();
  const [isRegistering, setIsRegistering] = useState(false);
  const [loading, setLoading] = useState(false);
  const [checkingSession, setCheckingSession] = useState(true);
  const [errorMsg, setErrorMsg] = useState("");
  const [formData, setFormData] = useState({ phoneNo: "", password: "" });

  // Auto-Login Check via Refresh Token
  useEffect(() => {
    const checkAuth = async () => {
      const { refreshToken } = getTokens();
      if (!refreshToken) {
        setCheckingSession(false);
        return;
      }

      try {
        const res = await fetch(
          "https://api.echocart.in/api/auth/login/refresh",
          {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              "X-Device-Id": getDeviceId(),
            },
            body: JSON.stringify({ refreshToken, deviceId: getDeviceId() }),
          },
        );
        const data = await res.json();
        if (data.token) {
          setTokens(data.token, data.refreshToken);
          router.push("/");
        } else {
          clearAuth();
        }
      } catch (err) {
        clearAuth();
        console.log("Refresh failed, user must log in manually.");
      } finally {
        setCheckingSession(false);
      }
    };

    checkAuth();
  }, [router]);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleSubmit = async (e: React.SyntheticEvent<HTMLFormElement>) => {
    e.preventDefault();
    setLoading(true);
    setErrorMsg("");

    const endpoint = isRegistering
      ? "https://api.echocart.in/api/auth/register/user"
      : "https://api.echocart.in/api/auth/login/user";

    try {
      const response = await fetch(endpoint, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-Device-Id": getDeviceId(),
        },
        body: JSON.stringify(formData),
      });

      const data = await response.json();

      if (response.ok && data.token) {
        setTokens(data.token, data.refreshToken);
        // If registering, force them to setup profile. If logging in, go to app.
        router.push(isRegistering ? "/register" : "/");
      } else {
        setErrorMsg(data.message || "Authentication failed. Please try again.");
      }
    } catch (err) {
      setErrorMsg("Network error. Is the server running?");
    } finally {
      setLoading(false);
    }
  };

  if (checkingSession) {
    return (
      <div className="min-h-screen bg-brand-bg text-white flex items-center justify-center">
        <div className="text-center">
          <div className="mx-auto mb-4 h-10 w-10 animate-spin rounded-full border-4 border-brand-primary border-t-transparent" />
          <p className="text-brand-text-muted">Checking your session...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-brand-bg text-white p-6 flex flex-col justify-center items-center">
      <div className="w-full max-w-md bg-brand-surface p-8 rounded-xl border border-brand-border shadow-2xl">
        <h1 className="text-3xl font-bold mb-2 text-brand-primary">
          {isRegistering ? "Create Account" : "Welcome Back"}
        </h1>
        <p className="text-brand-text-muted mb-6">
          {isRegistering
            ? "Set up an account to manage deliveries."
            : "Log in to your account."}
        </p>

        {errorMsg && (
          <div className="mb-4 p-3 bg-red-900/50 border border-red-500 text-red-200 rounded">
            {errorMsg}
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-6">
          <div>
            <label className="block text-sm font-medium mb-1">
              Phone Number
            </label>
            <input
              type="tel"
              name="phoneNo"
              value={formData.phoneNo}
              onChange={handleChange}
              className="w-full p-3 bg-brand-bg border border-brand-border rounded focus:border-brand-primary outline-none"
              required
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">Password</label>
            <input
              type="password"
              name="password"
              value={formData.password}
              onChange={handleChange}
              className="w-full p-3 bg-brand-bg border border-brand-border rounded focus:border-brand-primary outline-none"
              required
            />
          </div>
          <button
            type="submit"
            disabled={loading}
            className="w-full py-4 bg-brand-primary text-white font-bold rounded hover:bg-brand-primary-hover disabled:opacity-50"
          >
            {loading ? "Processing..." : isRegistering ? "Sign Up" : "Log In"}
          </button>
        </form>

        <div className="mt-6 text-center border-t border-brand-border pt-6">
          <button
            onClick={() => setIsRegistering(!isRegistering)}
            className="text-brand-text-muted hover:text-white"
          >
            {isRegistering
              ? "Already have an account? Log in"
              : "Don't have an account? Sign up"}
          </button>
        </div>
      </div>
    </div>
  );
}
