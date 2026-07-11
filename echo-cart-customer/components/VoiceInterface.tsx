"use react";

import React, { useState, useRef } from "react";
import { getTokens } from "@/utils/api";

interface ActiveOrderState {
  id: string | null;
  status: string | null;
  deliveryPersonName: string | null;
  deliveryPersonMobile: string | null;
}

interface VoiceInterfaceProps {
  currentCart: any;
  activeOrder: ActiveOrderState;
  conversationHistory?: Array<{ role: "user" | "ai"; text: string }>;
  onCartUpdate: (updatedCart: any) => void;
  onOrderStateChange: (order: ActiveOrderState) => void;
  onNewUserMessage: (text: string) => void;
  onNewSystemMessage: (text: string) => void;
}

export default function VoiceInterface({
  currentCart,
  activeOrder,
  conversationHistory = [],
  onCartUpdate,
  onOrderStateChange,
  onNewUserMessage,
  onNewSystemMessage,
}: VoiceInterfaceProps) {
  const [isRecording, setIsRecording] = useState(false);
  const [isLoading, setIsLoading] = useState(false);

  const mediaRecorderRef = useRef<MediaRecorder | null>(null);
  const audioChunksRef = useRef<Blob[]>([]);

  const startRecording = async () => {
    try {
      audioChunksRef.current = [];
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });

      // WebM is widely supported for audio recording in browsers
      const mediaRecorder = new MediaRecorder(stream, {
        mimeType: "audio/webm",
      });
      mediaRecorderRef.current = mediaRecorder;

      mediaRecorder.ondataavailable = (event) => {
        if (event.data.size > 0) {
          audioChunksRef.current.push(event.data);
        }
      };

      mediaRecorder.onstop = async () => {
        // Stop all audio track streams to turn off the hardware microphone light
        stream.getTracks().forEach((track) => track.stop());

        const audioBlob = new Blob(audioChunksRef.current, {
          type: "audio/webm",
        });
        await sendAudioToBackend(audioBlob);
      };

      mediaRecorder.start();
      setIsRecording(true);
    } catch (err) {
      console.error("Microphone access denied or unsupported:", err);
      onNewSystemMessage(
        "Could not access microphone. Please check permissions.",
      );
    }
  };

  const stopRecording = () => {
    if (mediaRecorderRef.current && isRecording) {
      mediaRecorderRef.current.stop();
      setIsRecording(false);
    }
  };

  const sendAudioToBackend = async (audioBlob: Blob) => {
    setIsLoading(true);
    try {
      const formData = new FormData();
      formData.append("audio", audioBlob);
      // Pass the current state of the cart as a clean string stringified JSON
      formData.append("currentCart", JSON.stringify(currentCart));
      formData.append(
        "conversationContext",
        JSON.stringify(conversationHistory.slice(-8)),
      );
      formData.append("activeOrderId", activeOrder.id || "");
      formData.append("activeOrderStatus", activeOrder.status || "");

      const { token } = getTokens();
      if (token) {
        formData.append("authToken", token);
      }

      const response = await fetch("/api/voice-command", {
        method: "POST",
        body: formData,
      });

      if (!response.ok) {
        // Attempt to parse the exact JSON error our backend sent
        const errorData = await response.json().catch(() => ({}));
        console.error("Backend Error Details:", errorData);
        throw new Error(errorData.error || `HTTP ${response.status} Error`);
      }

      const data = await response.json();

      // 1. Post the text version of what the user said to the chat UI
      if (data.transcript) {
        onNewUserMessage(data.transcript);
      }

      if (data.clarification) {
        onNewSystemMessage(data.clarification);
        return;
      }

      if (data.orderUpdate) {
        onNewSystemMessage(data.orderUpdate.message);

        const phoneNumber =
          data.orderUpdate.deliveryPersonMobile ||
          activeOrder.deliveryPersonMobile ||
          null;

        if (data.orderUpdate.shouldOpenDialer && phoneNumber) {
          window.location.href = `tel:${phoneNumber}`;
        }

        if (data.orderUpdate.shouldResetActiveOrder) {
          onOrderStateChange({
            id: null,
            status: null,
            deliveryPersonName: null,
            deliveryPersonMobile: null,
          });
        } else if (data.orderUpdate.orderStatus) {
          onOrderStateChange({
            id: activeOrder.id,
            status: data.orderUpdate.orderStatus,
            deliveryPersonName:
              data.orderUpdate.deliveryPersonName ||
              activeOrder.deliveryPersonName ||
              null,
            deliveryPersonMobile: phoneNumber,
          });
        }
        return;
      }

      // 2. Pass the fresh, LLM-updated cart object back up to the parent layout state
      if (data.updatedCart) {
        onCartUpdate(data.updatedCart);

        if (data.updatedCart.checkoutRequested) {
          onNewSystemMessage("Placing your order now.");
        } else {
          const items = data.updatedCart.orderJson?.itemList || [];
          if (items.length > 0) {
            const itemSummary = items
              .map((i: any) => `${i.quantity} ${i.name}`)
              .join(", ");
            onNewSystemMessage(
              `Cart now contains: ${itemSummary}. Total is ₹${data.updatedCart.estimatedPrice}.`,
            );
          } else {
            onNewSystemMessage("Your cart is now empty.");
          }
        }
      }
    } catch (error) {
      console.error("Error processing voice routing:", error);
      onNewSystemMessage("Sorry, I had trouble parsing that voice command.");
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="w-full p-4 bg-brand-surface border-t border-brand-border">
      <button
        onMouseDown={startRecording}
        onMouseUp={stopRecording}
        onTouchStart={startRecording}
        onTouchEnd={stopRecording}
        disabled={isLoading}
        className={`w-full py-12 text-2xl font-bold uppercase border-4 focus:outline-none focus:ring-4 focus:ring-brand-primary/50 transition-colors ${
          isLoading
            ? "bg-brand-surface border-brand-border text-brand-text-muted cursor-not-allowed"
            : isRecording
              ? "bg-brand-alert border-brand-alert animate-pulse text-white shadow-[0_0_20px_var(--color-brand-alert)]"
              : "bg-brand-bg border-brand-primary text-brand-text-on-primary active:bg-brand-surface"
        }`}
        aria-label={
          isRecording ? "Listening. Release to send command." : "Hold to talk."
        }
        style={{ touchAction: "none", userSelect: "none" }}
      >
        {isLoading
          ? "Processing..."
          : isRecording
            ? "Listening..."
            : "Hold to Speak"}
      </button>
    </div>
  );
}
