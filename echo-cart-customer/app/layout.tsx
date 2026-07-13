import type { Metadata, Viewport } from "next";
import { AccessibilityProvider } from "../context/AccessibilityContext";
import "./globals.css";

export const metadata: Metadata = {
  title: "EchoCart",
  description: "Accessible shopping assistant for voice-first ordering.",
  manifest: "/manifest.webmanifest",
  icons: {
    icon: "/icons/icon-192x192.svg",
    shortcut: "/icons/icon-192x192.svg",
    apple: "/icons/icon-192x192.svg",
  },
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  maximumScale: 1,
  themeColor: "#0c1116",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body>
        <AccessibilityProvider>{children}</AccessibilityProvider>
      </body>
    </html>
  );
}
