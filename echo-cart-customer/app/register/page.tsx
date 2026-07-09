"use client";

import React, { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { getTokens } from "@/utils/api"; // Or '../utils/api'

export default function Register() {
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [coordinates, setCoordinates] = useState("");

  const [formData, setFormData] = useState({
    name: "",
    address: "",
    city: "",
    state: "",
    pincode: "",
    profilePictureUrl: "default.jpg",
  });

  // Silently grab exact GPS coordinates when page loads for the delivery partner app
  useEffect(() => {
    if ("geolocation" in navigator) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          setCoordinates(
            `${position.coords.latitude},${position.coords.longitude}`,
          );
        },
        (error) => console.log("Geolocation denied or unavailable", error),
      );
    }
  }, []);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleSubmit = async (e: React.SyntheticEvent<HTMLFormElement>) => {
    e.preventDefault();
    setLoading(true);

    const { token } = getTokens();
    if (!token) {
      router.push("/login");
      return;
    }

    // Combine form data with the requested coordinate schema
    const payload = {
      ...formData,
      coordinates: coordinates || "0,0", // Fallback if they denied GPS permissions
    };

    try {
      // Updated endpoint to /user
      const response = await fetch(
        "https://api.echocart.in/api/profile/customer",
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify(payload),
        },
      );

      let data;
      try {
        data = await response.json();
      } catch (e) {
        data = { message: "Server returned non-JSON response." };
      }

      if (response.ok) {
        router.push("/");
      } else {
        // Show exact error in an alert so we can debug it
        const errorText = data.message || data.error || JSON.stringify(data);
        alert(`Backend Error: ${errorText}`);
      }
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : String(err);
      alert("Network error while saving profile: " + errorMessage);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-brand-bg text-white p-6 flex flex-col justify-center items-center">
      <div className="w-full max-w-md bg-brand-surface p-8 rounded-xl border border-brand-border shadow-2xl">
        <h1 className="text-3xl font-bold mb-2 text-brand-primary">
          Setup Profile
        </h1>
        <p className="text-brand-text-muted mb-8">
          Enter the delivery details for the primary user.
        </p>

        <form onSubmit={handleSubmit} className="space-y-5">
          {/* Include all the standard inputs (name, address, city, state, pincode) here... */}
          <div>
            <label className="block text-sm font-medium mb-1">Full Name</label>
            <input
              type="text"
              name="name"
              onChange={handleChange}
              className="w-full p-3 bg-brand-bg border border-brand-border rounded focus:border-brand-primary outline-none"
              required
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">
              Street Address
            </label>
            <input
              type="text"
              name="address"
              onChange={handleChange}
              className="w-full p-3 bg-brand-bg border border-brand-border rounded focus:border-brand-primary outline-none"
              required
            />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium mb-1">City</label>
              <input
                type="text"
                name="city"
                onChange={handleChange}
                className="w-full p-3 bg-brand-bg border border-brand-border rounded focus:border-brand-primary outline-none"
                required
              />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1">State</label>
              <input
                type="text"
                name="state"
                onChange={handleChange}
                className="w-full p-3 bg-brand-bg border border-brand-border rounded focus:border-brand-primary outline-none"
                required
              />
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">Pincode</label>
            <input
              type="text"
              name="pincode"
              onChange={handleChange}
              className="w-full p-3 bg-brand-bg border border-brand-border rounded focus:border-brand-primary outline-none"
              required
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full mt-6 py-4 bg-brand-primary text-white font-bold rounded hover:bg-brand-primary-hover"
          >
            {loading ? "Saving..." : "Complete Setup"}
          </button>
        </form>
      </div>
    </div>
  );
}
