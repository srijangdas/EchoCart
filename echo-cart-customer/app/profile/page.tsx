'use client';

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { getTokens, clearAuth } from '@/utils/api'; 
import Link from 'next/link';

export default function Profile() {
  const router = useRouter();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  
  const [formData, setFormData] = useState({
    name: '', address: '', city: '', state: '', pincode: '', profilePictureUrl: 'default.jpg', coordinates: '0,0'
  });

  useEffect(() => {
    const fetchProfile = async () => {
      const { token } = getTokens();
      if (!token) {
        router.push('/login');
        return;
      }

      try {
        // Updated endpoint to /user
        const response = await fetch('https://api.echocart.in/api/profile/customer', {
          method: 'GET',
          headers: {
            'Authorization': `Bearer ${token}`
          }
        });

        if (response.ok) {
          const data = await response.json();
          // Only update if data actually exists (prevents crashing on empty profiles)
          if (data && Object.keys(data).length > 0) {
            setFormData({
              name: data.name || '',
              address: data.address || '',
              city: data.city || '',
              state: data.state || '',
              pincode: data.pincode || '',
              profilePictureUrl: data.profilePictureUrl || 'default.jpg',
              coordinates: data.coordinates || '0,0'
            });
          }
        } else {
          console.warn("Profile not found or unauthorized. Status:", response.status);
        }
      } catch (error) {
        console.error("Failed to fetch profile:", error);
      } finally {
        setLoading(false);
      }
    };

    fetchProfile();
  }, [router]);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleSave = async (e: React.SyntheticEvent<HTMLFormElement>) => {
    e.preventDefault();
    setSaving(true);
    const { token } = getTokens();

    try {
      // Updated endpoint to /user
      const response = await fetch('https://api.echocart.in/api/profile/customer', {
        method: 'POST', 
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify(formData)
      });

      let data;
      try { data = await response.json(); } catch(e) {}

      if (response.ok) {
        alert("Profile updated successfully!");
      } else {
        const errorText = data?.message || data?.error || "Unknown server error";
        alert(`Failed to update profile: ${errorText}`);
      }
    } catch (err) {
      alert("Network error.");
    } finally {
      setSaving(false);
    }
  };

  const handleLogout = () => {
    clearAuth();
    router.push('/login');
  };

  if (loading) {
    return <div className="min-h-screen bg-black text-white flex items-center justify-center">Loading...</div>;
  }

  return (
    <div className="min-h-screen bg-black text-white p-6 flex flex-col items-center">
      <div className="w-full max-w-md bg-zinc-900 p-8 rounded-xl border border-zinc-800 shadow-2xl relative">
        
        {/* Navigation / Header */}
        <div className="flex justify-between items-center mb-6">
          <Link href="/" className="text-zinc-400 hover:text-white transition-colors">
            &larr; Back to App
          </Link>
          <button 
            onClick={handleLogout}
            className="px-4 py-2 bg-zinc-800 text-rose-400 font-semibold rounded hover:bg-zinc-700 transition-colors"
          >
            Log Out
          </button>
        </div>

        <h1 className="text-3xl font-bold mb-6 text-rose-500">Account Details</h1>

        <form onSubmit={handleSave} className="space-y-5">
          <div>
            <label className="block text-sm font-medium mb-1">Full Name</label>
            <input type="text" name="name" value={formData.name} onChange={handleChange} className="w-full p-3 bg-black border border-zinc-700 rounded focus:border-rose-500 outline-none" required />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">Street Address</label>
            <input type="text" name="address" value={formData.address} onChange={handleChange} className="w-full p-3 bg-black border border-zinc-700 rounded focus:border-rose-500 outline-none" required />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium mb-1">City</label>
              <input type="text" name="city" value={formData.city} onChange={handleChange} className="w-full p-3 bg-black border border-zinc-700 rounded focus:border-rose-500 outline-none" required />
            </div>
            <div>
              <label className="block text-sm font-medium mb-1">State</label>
              <input type="text" name="state" value={formData.state} onChange={handleChange} className="w-full p-3 bg-black border border-zinc-700 rounded focus:border-rose-500 outline-none" required />
            </div>
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">Pincode</label>
            <input type="text" name="pincode" value={formData.pincode} onChange={handleChange} className="w-full p-3 bg-black border border-zinc-700 rounded focus:border-rose-500 outline-none" required />
          </div>

          <button type="submit" disabled={saving} className="w-full mt-6 py-4 bg-rose-600 text-white font-bold rounded hover:bg-rose-500 disabled:opacity-50 transition-colors">
            {saving ? 'Saving...' : 'Update Profile'}
          </button>
        </form>
      </div>
    </div>
  );
}