// utils/api.ts

const BASE_URL = 'https://api.echocart.in';

export const getDeviceId = () => {
  let deviceId = localStorage.getItem('X-Device-Id');
  if (!deviceId) {
    // Generate a standard UUID for the device if it doesn't exist
    deviceId = crypto.randomUUID();
    localStorage.setItem('X-Device-Id', deviceId);
  }
  return deviceId;
};

export const getTokens = () => {
  return {
    token: localStorage.getItem('token'),
    refreshToken: localStorage.getItem('refreshToken')
  };
};

export const setTokens = (token: string, refreshToken: string) => {
  localStorage.setItem('token', token);
  localStorage.setItem('refreshToken', refreshToken);
};

export const clearAuth = () => {
  localStorage.removeItem('token');
  localStorage.removeItem('refreshToken');
};