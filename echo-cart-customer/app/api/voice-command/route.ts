import { NextResponse } from "next/server";

// Ensure you add OPENAI_API_KEY to your .env.local file
const OPENAI_API_KEY = process.env.OPENAI_API_KEY;

export async function POST(req: Request) {
  try {
    const formData = await req.formData();
    const audioFile = formData.get("audio") as Blob;
    const currentCartString = formData.get("currentCart") as string;
    const activeOrderId = formData.get("activeOrderId") as string | null;
    const activeOrderStatus = formData.get("activeOrderStatus") as
      | string
      | null;
    const authToken = formData.get("authToken") as string | null;

    if (!audioFile) {
      return NextResponse.json(
        { error: "No audio file provided" },
        { status: 400 },
      );
    }

    // --- TRANSCRIPTION: Convert Audio to Text (Whisper) ---
    const whisperData = new FormData();
    whisperData.append("file", audioFile, "recording.webm");
    whisperData.append("model", "whisper-1");

    const whisperResponse = await fetch(
      "https://api.openai.com/v1/audio/transcriptions",
      {
        method: "POST",
        headers: { Authorization: `Bearer ${OPENAI_API_KEY}` },
        body: whisperData,
      },
    );

    const whisperResult = await whisperResponse.json();

    // 1. Check if OpenAI explicitly rejected the request (e.g., Billing issues, Bad API Key)
    if (whisperResult.error) {
      console.error("OpenAI API Error:", whisperResult.error);
      return NextResponse.json(
        {
          error: `OpenAI Error: ${whisperResult.error.message}`,
        },
        { status: 500 },
      );
    }

    const userSpokenText = whisperResult.text;

    // 2. Check if the audio was just completely silent or too short
    if (!userSpokenText || userSpokenText.trim() === "") {
      return NextResponse.json(
        {
          error:
            "No speech detected. Make sure to hold the button down while speaking.",
        },
        { status: 400 },
      );
    }

    if (!userSpokenText) {
      return NextResponse.json(
        { error: "Could not understand audio" },
        { status: 400 },
      );
    }

    if (activeOrderId) {
      const normalizedTranscript = userSpokenText.toLowerCase();
      const wantsToCallDriver =
        normalizedTranscript.includes("call") &&
        (normalizedTranscript.includes("driver") ||
          normalizedTranscript.includes("delivery") ||
          normalizedTranscript.includes("delivery person"));

      if (wantsToCallDriver) {
        return NextResponse.json({
          transcript: userSpokenText,
          orderUpdate: {
            message: "I can help you call your delivery person.",
            orderStatus: "CALL_REQUESTED",
            deliveryPersonName: null,
            deliveryPersonMobile: null,
            shouldResetActiveOrder: false,
            shouldOpenDialer: true,
          },
        });
      }

      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      let statusPayload: Record<string, any> | null = null;
      let normalizedStatus = (activeOrderStatus || "PENDING").toUpperCase();

      try {
        if (authToken) {
          const statusResponse = await fetch(
            `https://api.echocart.in/api/orders/${activeOrderId}/status`,
            {
              method: "GET",
              headers: {
                Authorization: `Bearer ${authToken}`,
              },
            },
          );

          if (statusResponse.ok) {
            statusPayload = await statusResponse.json();
            normalizedStatus = (
              statusPayload?.status ||
              activeOrderStatus ||
              "PENDING"
            ).toUpperCase();
          }
        }
      } catch (error) {
        console.error("Failed to fetch active order status:", error);
      }

      const deliveryPersonName = statusPayload?.deliveryName;
      null;

      const deliveryPersonMobile = statusPayload?.deliveryPhoneNo;
      null;

      if (normalizedStatus === "DELIVERED") {
        return NextResponse.json({
          transcript: userSpokenText,
          orderUpdate: {
            message:
              "Your order has been delivered. Order tracking mode is now closed, and you can place new orders again.",
            orderStatus: normalizedStatus,
            deliveryPersonName: deliveryPersonName,
            deliveryPersonMobile: null,
            shouldResetActiveOrder: true,
          },
        });
      }

      if (normalizedStatus === "CANCELLED") {
        return NextResponse.json({
          transcript: userSpokenText,
          orderUpdate: {
            message:
              "Your order was cancelled. You can place a new order whenever you are ready.",
            orderStatus: normalizedStatus,
            deliveryPersonName: deliveryPersonName,
            deliveryPersonMobile: null,
            shouldResetActiveOrder: true,
          },
        });
      }

      const messageByStatus: Record<string, string> = {
        PENDING:
          "Your order is still pending. We are waiting for delivery partner to accept it.",
        ACCEPTED:
          "Your order has been accepted and is being prepared. Driver will buy soon.",
        SHOPPING:
          "Your delivery person is currently shopping for your order. You can call them on",
        IN_TRANSIT:
          "Your order is on the way. You can call your delivery person on",
      };

      const baseMessage =
        messageByStatus[normalizedStatus] ||
        "I’m tracking your current order and can share updates for it.";
      const message =
        normalizedStatus === "SHOPPING" || normalizedStatus === "IN_TRANSIT"
          ? `${baseMessage} ${deliveryPersonMobile || "the number shared with you"}.`
          : baseMessage;

      return NextResponse.json({
        transcript: userSpokenText,
        orderUpdate: {
          message,
          orderStatus: normalizedStatus,
          deliveryPersonName: deliveryPersonName,
          deliveryPersonMobile,
          shouldResetActiveOrder: false,
        },
      });
    }

    // --- INTENT PARSING: Update the Cart (GPT-4o) ---
    const systemPrompt = `You are a strict JSON-only API for the EchoCart grocery application.
    Your job is to take the user's voice request and their CURRENT CART, and output the NEW CART state.
    
    CRITICAL RULES:
    - Output ONLY valid JSON. No markdown backticks, no explanations.
    - The schema must exactly match the expected backend format.
    - All prices and the estimatedPrice MUST be in Indian Rupees (INR). Estimate realistic Indian market prices if exact prices are unknown.
    - For generic groceries (e.g., potatoes, rice, milk), DO NOT include "brand", "model", or "color". Just name, price, and quantity.
    - If the user explicitly asks to "checkout", "place the order", or says they are "done", set the "checkoutRequested" flag to true. Otherwise, false.
    - Do NOT allow checkout if the resulting cart has no items. If the cart is empty, return a clarification asking the user to add at least one item first.
    When defining an item's name, always incorporate the specific unit, package type, or metric mentioned by the user if it dictates weight or volume.
    For example, if a user asks for '2.5 kg potatoes', set name to 'Potatoes (kg)' and quantity to 2.5. If they ask for 'one 500 ml milk carton', set name to '500ml Milk Carton' and quantity to 1.
    If the user requests a specific brand or variant, include that in the name. For example, 'Amul Butter 200g' or 'Tata Salt 1kg'.
    If the user requests a quantity in a unit that is not standard (e.g., 'a pinch of salt', 'a handful of rice'), convert it to a reasonable metric equivalent (e.g., 1g for a pinch, 50g for a handful) and reflect that in the name and quantity.
    If the user requests an item that is vague or ambiguous (e.g., 'some snacks', 'a few vegetables'), do not add it to the cart. Instead, return a clarification JSON object like:
    {"action":"clarify","message":"Could you be more specific about which snacks you want?"}
    
    EXPECTED SCHEMA:
    {
      "orderJson": {
        "itemList": [
          { "name": "Item Name", "price": 50.0, "quantity": 1 }
        ]
      },
      "estimatedPrice": 50.0
    }
    OR, when clarification is needed:
    {"action":"clarify","message":"Could you be more specific about which snacks you want?"}`;

    const llmResponse = await fetch(
      "https://api.openai.com/v1/chat/completions",
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${OPENAI_API_KEY}`,
        },
        body: JSON.stringify({
          model: "gpt-4o",
          messages: [
            { role: "system", content: systemPrompt },
            {
              role: "user",
              content: `CURRENT CART: ${currentCartString}\n\nUSER REQUEST: "${userSpokenText}"\n\nReturn the updated JSON cart.`,
            },
          ],
          temperature: 0.1, // Keep it low so the AI doesn't get overly creative with the JSON formatting
        }),
      },
    );

    const llmResult = await llmResponse.json();
    const rawContent = llmResult.choices[0].message.content;
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    let parsedResponse: Record<string, any> | null = null;

    try {
      parsedResponse = JSON.parse(rawContent);
    } catch (error) {
      console.error("Failed to parse LLM response as JSON:", rawContent);
      return NextResponse.json({
        transcript: userSpokenText,
        clarification: "I need a bit more detail to process that request.",
      });
    }

    if (parsedResponse?.action === "clarify" || parsedResponse?.clarification) {
      return NextResponse.json({
        transcript: userSpokenText,
        clarification: parsedResponse.message || parsedResponse.clarification,
      });
    }

    const itemList = parsedResponse?.orderJson?.itemList ?? [];
    const normalizedTranscript = userSpokenText.toLowerCase();
    const wantsCheckout =
      normalizedTranscript.includes("checkout") ||
      normalizedTranscript.includes("place the order") ||
      normalizedTranscript.includes("place order") ||
      normalizedTranscript.includes("done") ||
      normalizedTranscript.includes("finish");

    if (!parsedResponse?.orderJson || !Array.isArray(itemList)) {
      console.error("LLM returned an invalid cart payload:", parsedResponse);
      return NextResponse.json({
        transcript: userSpokenText,
        clarification: "I need a bit more detail to process that request.",
      });
    }

    if (!itemList.length) {
      return NextResponse.json({
        transcript: userSpokenText,
        clarification: wantsCheckout
          ? "Your cart is empty. Add at least one item before placing an order."
          : "I couldn’t find a valid item in that request. Please be more specific.",
      });
    }

    if (wantsCheckout && parsedResponse?.checkoutRequested) {
      return NextResponse.json({
        transcript: userSpokenText,
        clarification:
          "Your cart is empty. Add at least one item before placing an order.",
      });
    }

    return NextResponse.json({
      transcript: userSpokenText,
      updatedCart: parsedResponse,
    });
  } catch (error) {
    console.error("AI Processing Error:", error);
    return NextResponse.json(
      { error: "Failed to process voice command" },
      { status: 500 },
    );
  }
}
