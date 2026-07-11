/* eslint-disable @typescript-eslint/no-explicit-any */
"use client";

import React, { useState, useEffect, useRef, useCallback } from "react";
import { useRouter } from "next/navigation";
import { getTokens } from "@/utils/api";
import Link from "next/link";
import VoiceInterface from "../components/VoiceInterface";
import { useAccessibility } from "../context/AccessibilityContext";
import { isTokenExpired } from "@/utils/isTokenExpired";

type Message = {
  id: string;
  role: "user" | "ai";
  text: string;
};

type CartState = {
  orderJson: {
    itemList: Array<{ name: string; price: number; quantity: number }>;
  };
  estimatedPrice: number;
  checkoutRequested?: boolean;
};

type PersistedHomeState = {
  messages: Message[];
  cart: CartState;
  activeOrder: {
    id: string | null;
    status: string | null;
    deliveryPersonName: string | null;
    deliveryPersonMobile: string | null;
  };
};

const STORAGE_KEY = "echo-cart-home-state";
const defaultMessages: Message[] = [
  {
    id: "1",
    role: "ai",
    text: "EchoCart active. Hold the button below and tell me what you need to add to your order.",
  },
];

const defaultCart: CartState = {
  orderJson: { itemList: [] },
  estimatedPrice: 0,
};

const defaultActiveOrder = {
  id: null as string | null,
  status: null as string | null,
  deliveryPersonName: null as string | null,
  deliveryPersonMobile: null as string | null,
};

const getDriverDetails = (payload: any) => {
  const driver =
    payload?.driver ||
    payload?.deliveryPerson ||
    payload?.deliveryMan ||
    payload?.courier ||
    {};
  const deliveryPersonName =
    payload?.deliverName ||
    payload?.deliveryName ||
    payload?.deliveryPersonName ||
    payload?.deliveryManName ||
    payload?.driverName ||
    driver?.name ||
    driver?.fullName ||
    null;
  const deliveryPersonMobile =
    payload?.deliveryPhoneNo ||
    payload?.deliveryPersonMobile ||
    payload?.deliveryManMobile ||
    payload?.driverMobile ||
    driver?.mobile ||
    driver?.phone ||
    driver?.phoneNumber ||
    null;

  return { deliveryPersonName, deliveryPersonMobile };
};

const getStatusMessage = (status: string | null, mobile: string | null) => {
  const normalized = (status || "PENDING").toUpperCase();

  switch (normalized) {
    case "ACCEPTED":
      return "Your order has been accepted and is being prepared.";
    case "SHOPPING":
      return mobile
        ? `Your delivery person is shopping for your order. You can call them at ${mobile}.`
        : "Your delivery person is shopping for your order.";
    case "IN_TRANSIT":
      return mobile
        ? `Your order is on the way. You can call your delivery person at ${mobile}.`
        : "Your order is on the way.";
    case "DELIVERED":
      return "Your order has been delivered. Order update mode is now closed.";
    case "CANCELLED":
      return "Your order was cancelled. You can place a new order whenever you are ready.";
    default:
      return "Your order is still pending. We are waiting for confirmation.";
  }
};

export default function Home() {
  const router = useRouter();
  const { announce } = useAccessibility();

  // Authentication check
  useEffect(() => {
    const { token } = getTokens();
    if (!token || isTokenExpired(token)) {
      router.push("/login");
    }
  }, [router]);

  // Initial load announcement
  useEffect(() => {
    announce("EchoCart AI is ready. Hold the bottom button to speak.");
  }, [announce]);

  const requestLocationPermission = useCallback(async () => {
    if (typeof window === "undefined" || !navigator.geolocation) return;

    try {
      const permissionStatus = await navigator.permissions?.query({
        name: "geolocation" as PermissionName,
      });

      if (permissionStatus?.state === "denied") return;

      const position = await new Promise<GeolocationPosition>(
        (resolve, reject) => {
          navigator.geolocation.getCurrentPosition(resolve, reject, {
            enableHighAccuracy: true,
            timeout: 10000,
            maximumAge: 0,
          });
        },
      );

      const coordinates = `${position.coords.latitude},${position.coords.longitude}`;
      const { token } = getTokens();

      if (token) {
        await fetch("https://api.echocart.in/api/profile/customer/location", {
          method: "PUT",
          headers: {
            "Content-Type": "text/plain",
            Authorization: `Bearer ${token}`,
          },
          body: coordinates,
        });
      }
    } catch (error) {
      console.error("Location permission or update failed:", error);
    }
  }, []);

  useEffect(() => {
    void requestLocationPermission();
  }, [requestLocationPermission]);

  const [messages, setMessages] = useState<Message[]>(() => {
    if (typeof window === "undefined") return defaultMessages;

    try {
      const stored = window.localStorage.getItem(STORAGE_KEY);
      if (!stored) return defaultMessages;

      const parsed = JSON.parse(stored) as PersistedHomeState;
      return parsed.messages?.length ? parsed.messages : defaultMessages;
    } catch (error) {
      console.error("Failed to restore saved messages:", error);
      return defaultMessages;
    }
  });

  const [cart, setCart] = useState<CartState>(() => {
    if (typeof window === "undefined") return defaultCart;

    try {
      const stored = window.localStorage.getItem(STORAGE_KEY);
      if (!stored) return defaultCart;

      const parsed = JSON.parse(stored) as PersistedHomeState;
      return parsed.cart || defaultCart;
    } catch (error) {
      console.error("Failed to restore saved cart:", error);
      return defaultCart;
    }
  });

  const [activeOrder, setActiveOrder] = useState(() => {
    if (typeof window === "undefined") return defaultActiveOrder;

    try {
      const stored = window.localStorage.getItem(STORAGE_KEY);
      if (!stored) return defaultActiveOrder;

      const parsed = JSON.parse(stored) as PersistedHomeState;
      return parsed.activeOrder || defaultActiveOrder;
    } catch (error) {
      console.error("Failed to restore saved active order:", error);
      return defaultActiveOrder;
    }
  });

  const chatEndRef = useRef<HTMLDivElement>(null);
  const lastAnnouncedStatusRef = useRef<string | null>(null);
  const lastAnnouncementKeyRef = useRef<string | null>(null);

  const handleNewSystemMessage = useCallback(
    (text: string) => {
      setMessages((prev) => [
        ...prev,
        { id: (Date.now() + 1).toString(), role: "ai", text },
      ]);
      announce(text);
    },
    [announce],
  );

  const parseCustomerOrder = (data: any) => {
    const order =
      data?.order ||
      data?.orders?.[0] ||
      data?.data?.order ||
      data?.data?.orders?.[0] ||
      data?.latestOrder ||
      data;

    if (!order) return null;

    const status = (
      order.status ||
      order.orderStatus ||
      order.state ||
      "PENDING"
    ).toUpperCase();
    const orderId = order.id || order.orderId || order.order_id || null;
    if (!orderId) return null;

    const driverDetails = getDriverDetails(order);

    return {
      id: orderId,
      status,
      deliveryPersonName: driverDetails.deliveryPersonName,
      deliveryPersonMobile: driverDetails.deliveryPersonMobile,
    };
  };

  const restoreActiveOrderFromServer = useCallback(async () => {
    if (typeof window === "undefined") return;

    const { token } = getTokens();
    if (!token) return;
    if (activeOrder.id) return;

    try {
      const response = await fetch(
        "https://api.echocart.in/api/orders/customer",
        {
          method: "GET",
          headers: {
            Authorization: `Bearer ${token}`,
          },
        },
      );

      if (!response.ok) return;

      const payload = await response.json().catch(() => null);
      const activeStatuses = ["PENDING", "ACCEPTED", "SHOPPING", "IN_TRANSIT"];

      const candidates: any[] = [];
      if (Array.isArray(payload)) {
        candidates.push(...payload);
      } else if (payload && typeof payload === "object") {
        if (Array.isArray(payload.orders)) {
          candidates.push(...payload.orders);
        } else if (payload.order) {
          candidates.push(payload.order);
        } else if (payload.data && Array.isArray(payload.data.orders)) {
          candidates.push(...payload.data.orders);
        } else if (payload.data?.order) {
          candidates.push(payload.data.order);
        } else {
          candidates.push(payload);
        }
      }

      const activeRawOrder = candidates.find((order) => {
        const normalizedStatus = (
          order?.status ||
          order?.orderStatus ||
          ""
        ).toUpperCase();
        return activeStatuses.includes(normalizedStatus);
      });

      if (!activeRawOrder) return;

      const restoredOrder = parseCustomerOrder(activeRawOrder);
      if (!restoredOrder) return;

      setActiveOrder(restoredOrder);
      handleNewSystemMessage(
        `Resuming your active order ${restoredOrder.id} with status ${restoredOrder.status}.`,
      );
    } catch (error) {
      console.error("Failed to restore active order from server:", error);
    }
  }, [activeOrder.id, handleNewSystemMessage]);

  useEffect(() => {
    const timeoutId = window.setTimeout(() => {
      void restoreActiveOrderFromServer();
    }, 0);

    return () => window.clearTimeout(timeoutId);
  }, [restoreActiveOrderFromServer]);

  useEffect(() => {
    if (typeof window === "undefined") return;

    const payload: PersistedHomeState = {
      messages,
      cart,
      activeOrder,
    };

    window.localStorage.setItem(STORAGE_KEY, JSON.stringify(payload));
  }, [messages, cart, activeOrder]);

  useEffect(() => {
    chatEndRef.current?.scrollIntoView({
      behavior: "smooth",
      block: "nearest",
    });
  }, [messages]);

  const pollOrderStatus = useCallback(async () => {
    if (!activeOrder.id) return;

    const { token } = getTokens();
    if (!token) return;

    try {
      const response = await fetch(
        `https://api.echocart.in/api/orders/${activeOrder.id}/status`,
        {
          method: "GET",
          headers: {
            Authorization: `Bearer ${token}`,
          },
        },
      );

      if (!response.ok) return;

      const payload = await response.json().catch(() => null);
      const nextStatus = (
        payload?.status ||
        activeOrder.status ||
        "PENDING"
      ).toUpperCase();
      const driverDetails = getDriverDetails(payload);

      setActiveOrder((prev) => {
        const updated = {
          ...prev,
          id: prev.id,
          status: nextStatus,
          deliveryPersonName:
            driverDetails.deliveryPersonName || prev.deliveryPersonName,
          deliveryPersonMobile:
            driverDetails.deliveryPersonMobile || prev.deliveryPersonMobile,
        };

        if (nextStatus === "DELIVERED" || nextStatus === "CANCELLED") {
          return {
            id: null,
            status: null,
            deliveryPersonName: null,
            deliveryPersonMobile: null,
          };
        }

        return updated;
      });

      if (nextStatus !== lastAnnouncedStatusRef.current) {
        const message = getStatusMessage(
          nextStatus,
          driverDetails.deliveryPersonMobile ||
            activeOrder.deliveryPersonMobile,
        );
        const announcementKey = `${activeOrder.id}:${nextStatus}:${driverDetails.deliveryPersonMobile || activeOrder.deliveryPersonMobile || ""}`;
        if (announcementKey !== lastAnnouncementKeyRef.current) {
          handleNewSystemMessage(message);
          lastAnnouncementKeyRef.current = announcementKey;
        }
        lastAnnouncedStatusRef.current = nextStatus;
      }
    } catch (error) {
      console.error("Order status polling failed:", error);
    }
  }, [
    activeOrder.id,
    activeOrder.status,
    activeOrder.deliveryPersonMobile,
    handleNewSystemMessage,
  ]);

  useEffect(() => {
    if (!activeOrder.id) {
      lastAnnouncedStatusRef.current = null;
      lastAnnouncementKeyRef.current = null;
      return;
    }

    const timeoutId = window.setTimeout(() => {
      void pollOrderStatus();
    }, 0);

    const intervalId = window.setInterval(() => {
      void pollOrderStatus();
    }, 10000);

    return () => {
      window.clearTimeout(timeoutId);
      window.clearInterval(intervalId);
    };
  }, [activeOrder.id, pollOrderStatus]);

  const handleNewUserMessage = (text: string) => {
    setMessages((prev) => [
      ...prev,
      { id: Date.now().toString(), role: "user", text },
    ]);
  };

  const handleCartUpdate = (updatedCart: any) => {
    // Update the visual cart first
    setCart(updatedCart);

    // If the AI detected a checkout command, automatically fire the checkout sequence
    if (updatedCart.checkoutRequested) {
      handleCheckout();
    }
  };

  const handleCheckout = async () => {
    try {
      // Announce to screen readers that processing has started
      announce("Sending order to server...");

      await requestLocationPermission();

      const { token } = getTokens();

      const response = await fetch("https://api.echocart.in/api/orders", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${token}`, // The exact header your friend's schema requires
        },
        body: JSON.stringify(cart),
      });

      if (!response.ok) {
        throw new Error(`Server responded with status: ${response.status}`);
      }

      const payload = await response.json().catch(() => null);
      const orderId =
        payload?.id ||
        payload?.orderId ||
        payload?.order?.id ||
        payload?.data?.id ||
        payload?.data?.orderId ||
        null;
      const status =
        payload?.status ||
        payload?.order?.status ||
        payload?.data?.status ||
        "PENDING";

      // Success handling
      handleNewSystemMessage("Your order has been placed successfully!");
      const driverDetails = getDriverDetails(payload);
      setActiveOrder({
        id: orderId,
        status,
        deliveryPersonName: driverDetails.deliveryPersonName,
        deliveryPersonMobile: driverDetails.deliveryPersonMobile,
      });

      // Clear the cart back to empty after a successful checkout
      setCart({ orderJson: { itemList: [] }, estimatedPrice: 0 });
    } catch (error) {
      console.error("Checkout Error:", error);
      handleNewSystemMessage(
        "There was an issue connecting to the server to place your order.",
      );
    }
  };

  return (
    // 1. Strictly lock the outermost wrapper to the exact device height
    <div className="min-h-screen max-h-screen w-full bg-brand-bg overflow-hidden flex justify-center">
      {/* 2. Inner wrapper stays pinned to the viewport and lets the chat area scroll independently */}
      <div className="flex flex-col h-screen w-full max-w-md lg:max-w-lg xl:max-w-xl border-x border-brand-border bg-brand-bg text-white overflow-hidden">
        {/* Header */}
        <header
          className="p-6 border-b border-brand-border bg-brand-surface flex justify-between items-center z-10 shrink-0"
          role="banner"
        >
          <div>
            <h1 className="text-3xl font-extrabold tracking-wide text-brand-primary">
              EchoCart
            </h1>
            <p
              className="text-sm text-brand-text-muted mt-1 font-medium"
              aria-live="polite"
            >
              Cart Total: ₹{cart.estimatedPrice} | Items:{" "}
              {cart.orderJson.itemList.length}
            </p>
          </div>

          <Link
            href="/profile"
            className="p-3 border-2 border-brand-border rounded-full hover:border-brand-primary hover:bg-brand-surface text-brand-text-muted transition-colors"
            aria-label="Open Account Profile and Settings"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              className="h-6 w-6"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
              strokeWidth={2}
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
              />
            </svg>
          </Link>
        </header>

        {/* Main Chat Area */}
        <main
          className="flex-1 min-h-0 p-6 pb-2 overflow-y-auto flex flex-col gap-6"
          role="log"
          aria-live="polite"
        >
          {messages.map((msg) => (
            <div
              key={msg.id}
              className={`p-4 rounded-2xl max-w-[85%] shadow-lg ${
                msg.role === "user"
                  ? "bg-brand-primary text-brand-text-on-primary ml-auto rounded-br-sm"
                  : "bg-brand-surface border border-brand-border text-white mr-auto rounded-bl-sm"
              }`}
            >
              <span className="sr-only">
                {msg.role === "user" ? "You said:" : "EchoCart said:"}
              </span>
              <p className="text-lg leading-relaxed">{msg.text}</p>
            </div>
          ))}
          {activeOrder.id && (
            <div className="p-4 rounded-2xl border border-brand-primary/40 bg-brand-surface/80 text-sm text-brand-text-muted">
              <p className="text-xs uppercase tracking-[0.2em] text-brand-primary mb-1">
                Order update mode
              </p>
              <p className="font-semibold text-white">
                Status: {activeOrder.status || "Checking..."}
              </p>
              {activeOrder.deliveryPersonName && (
                <p className="mt-1">Driver: {activeOrder.deliveryPersonName}</p>
              )}
              {activeOrder.deliveryPersonMobile && (
                <a
                  href={`tel:${activeOrder.deliveryPersonMobile}`}
                  className="inline-flex mt-3 px-3 py-2 rounded-lg bg-brand-primary text-brand-text-on-primary font-medium"
                >
                  Call driver
                </a>
              )}
            </div>
          )}

          {/* 3. The ref div doesn't need to be fully visible, but it needs to exist. */}
          <div ref={chatEndRef} className="h-0 w-0" />
        </main>

        {/* Sticky Bottom Action Panel */}
        {/* 4. Removed mt-auto; flex-1 on main already pushes this to the absolute bottom */}
        <div className="border-t border-brand-border bg-brand-bg z-10 shrink-0">
          <footer>
            <VoiceInterface
              currentCart={cart}
              activeOrder={activeOrder}
              conversationHistory={messages.slice(-8)}
              onCartUpdate={handleCartUpdate}
              onOrderStateChange={setActiveOrder}
              onNewUserMessage={handleNewUserMessage}
              onNewSystemMessage={handleNewSystemMessage}
            />
          </footer>
        </div>
      </div>
    </div>
  );
}
