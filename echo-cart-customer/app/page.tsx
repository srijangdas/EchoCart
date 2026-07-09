"use client";

import React, { useState, useEffect, useRef } from "react";
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

  const [messages, setMessages] = useState<Message[]>(defaultMessages);

  const [cart, setCart] = useState<CartState>(defaultCart);

  const [activeOrder, setActiveOrder] = useState(defaultActiveOrder);

  const chatEndRef = useRef<HTMLDivElement>(null);
  const lastAnnouncedStatusRef = useRef<string | null>(null);

  useEffect(() => {
    if (typeof window === "undefined") return;

    try {
      const stored = window.localStorage.getItem(STORAGE_KEY);
      if (!stored) return;

      const parsed = JSON.parse(stored) as PersistedHomeState;
      if (parsed.messages?.length) {
        setMessages(parsed.messages);
      }
      if (parsed.cart) {
        setCart(parsed.cart);
      }
      if (parsed.activeOrder) {
        setActiveOrder(parsed.activeOrder);
      }
    } catch (error) {
      console.error("Failed to restore saved EchoCart state:", error);
    }
  }, []);

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
    chatEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  const getDriverDetails = (payload: any) => {
    const driver =
      payload?.driver ||
      payload?.deliveryPerson ||
      payload?.deliveryMan ||
      payload?.courier ||
      {};
    const deliveryPersonName =
      payload?.deliveryPersonName ||
      payload?.deliveryManName ||
      payload?.driverName ||
      driver?.name ||
      driver?.fullName ||
      null;
    const deliveryPersonMobile =
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

  const pollOrderStatus = async () => {
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
        handleNewSystemMessage(message);
        lastAnnouncedStatusRef.current = nextStatus;
      }
    } catch (error) {
      console.error("Order status polling failed:", error);
    }
  };

  useEffect(() => {
    if (!activeOrder.id) {
      lastAnnouncedStatusRef.current = null;
      return;
    }

    void pollOrderStatus();
    const intervalId = window.setInterval(() => {
      void pollOrderStatus();
    }, 10000);

    return () => window.clearInterval(intervalId);
  }, [activeOrder.id]);

  const handleNewUserMessage = (text: string) => {
    setMessages((prev) => [
      ...prev,
      { id: Date.now().toString(), role: "user", text },
    ]);
  };

  const handleNewSystemMessage = (text: string) => {
    setMessages((prev) => [
      ...prev,
      { id: (Date.now() + 1).toString(), role: "ai", text },
    ]);
    announce(text);
  };

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
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
    <div className="bg-brand-bg">
      5
      <div className="flex flex-col h-screen max-w-md mx-auto border-x border-brand-border bg-brand-bg text-white overflow-hidden">
        {/* Header */}
        <header
          className="p-6 border-b border-brand-border bg-brand-surface flex justify-between items-center z-10"
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
          className="grow p-6 overflow-y-auto space-y-6"
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
          <div ref={chatEndRef} />
        </main>

        {/* Sticky Bottom Action Panel */}
        <div className="mt-auto border-t border-brand-border bg-brand-bg z-10">
          <footer>
            <VoiceInterface
              currentCart={cart}
              activeOrder={activeOrder}
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
