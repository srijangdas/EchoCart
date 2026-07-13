"use client";

import React, { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { getTokens, clearAuth } from "@/utils/api";
import Link from "next/link";

type TabOption = "profile" | "orders";

type OrderItem = {
  name: string;
  price: number;
  quantity: number;
};

type OrderRecord = {
  id: string;
  status: string;
  totalAmount: number;
  itemCount: number;
  items: OrderItem[];
};

const formatCurrency = (value: number) =>
  new Intl.NumberFormat("en-IN", {
    style: "currency",
    currency: "INR",
    maximumFractionDigits: 0,
  }).format(value || 0);

const extractItems = (order: Record<string, unknown>): OrderItem[] => {
  const candidates = [
    (order?.orderJson as Record<string, unknown> | undefined)?.itemList,
    order?.itemList,
    order?.items,
  ];

  for (const candidate of candidates) {
    if (Array.isArray(candidate)) {
      return candidate
        .map((item) => {
          const normalizedItem = item as Record<string, unknown>;
          return {
            name: String(normalizedItem?.name || "Item"),
            price: Number(normalizedItem?.price || 0),
            quantity: Number(normalizedItem?.quantity || 1),
          };
        })
        .filter((item) => item.name);
    }
  }

  return [];
};

const normalizeOrder = (order: Record<string, unknown>): OrderRecord | null => {
  const rawOrder = (order?.order as Record<string, unknown> | undefined) || order;
  const id =
    String(rawOrder?.id || rawOrder?.orderId || rawOrder?.order_id || "") || "";

  if (!id) {
    return null;
  }

  const status = String(
    rawOrder?.status || rawOrder?.orderStatus || rawOrder?.state || "PENDING",
  ).toUpperCase();
  const totalAmount = Number(
    rawOrder?.totalAmount ||
      rawOrder?.estimatedPrice ||
      rawOrder?.amount ||
      rawOrder?.grandTotal ||
      rawOrder?.total ||
      0,
  );
  const items = extractItems(rawOrder);

  return {
    id,
    status,
    totalAmount,
    itemCount: items.length,
    items,
  };
};

export default function Profile() {
  const router = useRouter();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [activeTab, setActiveTab] = useState<TabOption>("profile");
  const [orders, setOrders] = useState<OrderRecord[]>([]);
  const [ordersLoading, setOrdersLoading] = useState(false);

  const [formData, setFormData] = useState({
    name: "",
    address: "",
    city: "",
    state: "",
    pincode: "",
    profilePictureUrl: "default.jpg",
    coordinates: "0,0",
  });

  useEffect(() => {
    const fetchProfile = async () => {
      const { token } = getTokens();
      if (!token) {
        router.push("/login");
        return;
      }

      try {
        const response = await fetch(
          "https://api.echocart.in/api/profile/customer",
          {
            method: "GET",
            headers: {
              Authorization: `Bearer ${token}`,
            },
          },
        );

        if (response.ok) {
          const data = await response.json();
          if (data && Object.keys(data).length > 0) {
            setFormData({
              name: data.name || "",
              address: data.address || "",
              city: data.city || "",
              state: data.state || "",
              pincode: data.pincode || "",
              profilePictureUrl: data.profilePictureUrl || "default.jpg",
              coordinates: data.coordinates || "0,0",
            });
          }
        } else {
          console.warn(
            "Profile not found or unauthorized. Status:",
            response.status,
          );
        }
      } catch (error) {
        console.error("Failed to fetch profile:", error);
      } finally {
        setLoading(false);
      }
    };

    fetchProfile();
  }, [router]);

  useEffect(() => {
    if (activeTab !== "orders") {
      return;
    }

    let ignore = false;

    const fetchOrders = async () => {
      const { token } = getTokens();
      if (!token) {
        router.push("/login");
        return;
      }

      setOrdersLoading(true);

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

        if (!response.ok) {
          throw new Error(`Orders request failed: ${response.status}`);
        }

        const payload = await response.json().catch(() => null);
        const candidates: Record<string, unknown>[] = [];

        if (Array.isArray(payload)) {
          candidates.push(...(payload as Record<string, unknown>[]));
        } else if (payload && typeof payload === "object") {
          const payloadObject = payload as Record<string, unknown>;
          const dataObject = payloadObject.data as Record<string, unknown> | undefined;

          if (Array.isArray(payloadObject.orders)) {
            candidates.push(...(payloadObject.orders as Record<string, unknown>[]));
          } else if (payloadObject.order) {
            candidates.push(payloadObject.order as Record<string, unknown>);
          } else if (dataObject && Array.isArray(dataObject.orders)) {
            candidates.push(...(dataObject.orders as Record<string, unknown>[]));
          } else if (dataObject?.order) {
            candidates.push(dataObject.order as Record<string, unknown>);
          } else {
            candidates.push(payloadObject);
          }
        }

        const normalizedOrders = candidates
          .map((entry) => normalizeOrder(entry))
          .filter((entry): entry is OrderRecord => Boolean(entry));

        if (!ignore) {
          setOrders(normalizedOrders);
        }
      } catch (error) {
        console.error("Failed to fetch order history:", error);
        if (!ignore) {
          setOrders([]);
        }
      } finally {
        if (!ignore) {
          setOrdersLoading(false);
        }
      }
    };

    void fetchOrders();

    return () => {
      ignore = true;
    };
  }, [activeTab, router]);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleSave = async (e: React.SyntheticEvent<HTMLFormElement>) => {
    e.preventDefault();
    setSaving(true);
    const { token } = getTokens();

    try {
      const response = await fetch(
        "https://api.echocart.in/api/profile/customer",
        {
          method: "PUT",
          headers: {
            "Content-Type": "application/json",
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify(formData),
        },
      );

      let data;
      try {
        data = await response.json();
      } catch (e) {}

      if (response.ok) {
        alert("Profile updated successfully!");
      } else {
        const errorText =
          data?.message || data?.error || "Unknown server error";
        alert(`Failed to update profile: ${errorText}`);
      }
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
    } catch (err: any) {
      const errorText = err?.message || err?.error || "Unknown server error";
      alert(`Failed to update profile: ${errorText}`);
    } finally {
      setSaving(false);
    }
  };

  const handleLogout = () => {
    clearAuth();
    router.push("/login");
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-brand-bg text-white flex items-center justify-center">
        Loading...
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-brand-bg text-white p-6 flex flex-col items-center">
      <div className="w-full max-w-md bg-brand-surface p-8 rounded-xl border border-brand-border shadow-2xl relative">
        <div className="flex justify-between items-center mb-6">
          <Link
            href="/"
            className="text-brand-text-muted hover:text-white transition-colors"
          >
            &larr; Back to App
          </Link>
          <button
            onClick={handleLogout}
            className="px-4 py-2 bg-brand-border text-rose-400 font-semibold rounded hover:bg-brand-border transition-colors"
          >
            Log Out
          </button>
        </div>

        <div className="mb-6 flex rounded-full bg-brand-bg p-1">
          <button
            type="button"
            onClick={() => setActiveTab("profile")}
            className={`flex-1 rounded-full px-4 py-2 text-sm font-semibold transition-colors ${
              activeTab === "profile"
                ? "bg-brand-primary text-white"
                : "text-brand-text-muted hover:text-white"
            }`}
          >
            Profile
          </button>
          <button
            type="button"
            onClick={() => setActiveTab("orders")}
            className={`flex-1 rounded-full px-4 py-2 text-sm font-semibold transition-colors ${
              activeTab === "orders"
                ? "bg-brand-primary text-white"
                : "text-brand-text-muted hover:text-white"
            }`}
          >
            Order History
          </button>
        </div>

        {activeTab === "orders" ? (
          <div className="flex h-[60vh] flex-col">
            <div className="mb-4 flex items-center justify-between">
              <h1 className="text-2xl font-bold text-brand-primary">
                Past Orders
              </h1>
              <span className="text-sm text-brand-text-muted">
                {orders.length} total
              </span>
            </div>

            <div className="flex-1 space-y-4 overflow-y-auto pr-1">
              {ordersLoading ? (
                <div className="rounded-lg border border-brand-border bg-brand-bg p-4 text-sm text-brand-text-muted">
                  Loading your order history...
                </div>
              ) : orders.length === 0 ? (
                <div className="rounded-lg border border-brand-border bg-brand-bg p-4 text-sm text-brand-text-muted">
                  You do not have any past orders yet.
                </div>
              ) : (
                orders.map((order) => (
                  <div
                    key={order.id}
                    className="rounded-lg border border-brand-border bg-brand-bg p-4"
                  >
                    <div className="flex items-start justify-between gap-3">
                      <div>
                        <p className="text-sm font-semibold text-white">#{order.id}</p>
                        <p className="mt-1 text-sm text-brand-text-muted">
                          {order.itemCount} item{order.itemCount === 1 ? "" : "s"}
                        </p>
                      </div>
                      <span className="rounded-full bg-brand-surface px-3 py-1 text-xs font-semibold uppercase tracking-wide text-brand-primary">
                        {order.status}
                      </span>
                    </div>

                    <div className="mt-3 space-y-2">
                      <div className="flex items-center justify-between text-sm text-brand-text-muted">
                        <span>Items</span>
                        <span className="font-semibold text-white">
                          {formatCurrency(order.totalAmount)}
                        </span>
                      </div>
                      <ul className="space-y-1 text-sm text-white">
                        {order.items.length > 0 ? (
                          order.items.map((item, index) => (
                            <li key={`${order.id}-${item.name}-${index}`} className="flex items-center justify-between gap-3 rounded bg-brand-surface/70 px-3 py-2">
                              <span>{item.name}</span>
                              <span className="text-brand-text-muted">
                                {item.quantity} × {formatCurrency(item.price)}
                              </span>
                            </li>
                          ))
                        ) : (
                          <li className="rounded bg-brand-surface/70 px-3 py-2 text-brand-text-muted">
                            No items listed
                          </li>
                        )}
                      </ul>
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>
        ) : (
          <>
            <h1 className="text-3xl font-bold mb-6 text-brand-primary">
              Account Details
            </h1>

            <form onSubmit={handleSave} className="space-y-5">
              <div>
                <label className="block text-sm font-medium mb-1">Full Name</label>
                <input
                  type="text"
                  name="name"
                  value={formData.name}
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
                  value={formData.address}
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
                    value={formData.city}
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
                    value={formData.state}
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
                  value={formData.pincode}
                  onChange={handleChange}
                  className="w-full p-3 bg-brand-bg border border-brand-border rounded focus:border-brand-primary outline-none"
                  required
                />
              </div>

              <button
                type="submit"
                disabled={saving}
                className="w-full mt-6 py-4 bg-brand-primary text-white font-bold rounded hover:bg-brand-primary-hover disabled:opacity-50 transition-colors"
              >
                {saving ? "Saving..." : "Update Profile"}
              </button>
            </form>
          </>
        )}
      </div>
    </div>
  );
}
