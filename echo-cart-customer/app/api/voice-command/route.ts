import { NextResponse } from "next/server";

// Ensure you add OPENAI_API_KEY to your .env.local file
const OPENAI_API_KEY = process.env.OPENAI_API_KEY;

type ConversationEntry = {
  role: "user" | "ai";
  text: string;
};

const parseConversationContext = (
  rawValue: FormDataEntryValue | null,
): ConversationEntry[] => {
  if (!rawValue || typeof rawValue !== "string") return [];

  try {
    const parsed = JSON.parse(rawValue);
    if (!Array.isArray(parsed)) return [];

    return parsed.filter(
      (entry): entry is ConversationEntry =>
        Boolean(entry) &&
        typeof entry === "object" &&
        "role" in entry &&
        "text" in entry &&
        (entry.role === "user" || entry.role === "ai") &&
        typeof entry.text === "string",
    );
  } catch (error) {
    console.warn("Failed to parse conversation context:", error);
    return [];
  }
};

const isSupportedLanguageText = (text: string) => {
  const trimmed = text.trim();
  if (!trimmed) return false;

  const hasLatin = /[A-Za-z]/.test(trimmed);
  const hasDevanagari = /[\u0900-\u097F]/.test(trimmed);
  const hasBengali = /[\u0980-\u09FF]/.test(trimmed);
  const hasOtherIndicScript =
    /[\u0B00-\u0C7F\u0C80-\u0D7F\u0E00-\u0E7F\u0A80-\u0AFF\u0B80-\u0BFF]/.test(
      trimmed,
    );

  return (hasLatin || hasDevanagari || hasBengali) && !hasOtherIndicScript;
};

const getCartResetIntent = (text: string) => {
  const normalized = text.toLowerCase();
  const hasCartContext = /\b(cart|basket|order|list|trolley)\b/.test(
    normalized,
  );
  const resetPhrases =
    /\b(reset|clear|empty|remove all|start over|start again|remove)\b/.test(
      normalized,
    ) ||
    /\b(khali|saf|saf karo|saf koro|hata do|hatao|shuru|phir se|mushon|sob|sara)\b/.test(
      normalized,
    );

  return resetPhrases && (hasCartContext || normalized.includes("cart"));
};

const getDeliveryDetails = (
  payload: Record<string, any> | null | undefined,
) => {
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

export async function POST(req: Request) {
  try {
    const formData = await req.formData();
    const audioFile = formData.get("audio") as Blob;
    const currentCartString = formData.get("currentCart") as string;
    const conversationContext = parseConversationContext(
      formData.get("conversationContext"),
    );
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

    if (!isSupportedLanguageText(userSpokenText)) {
      return NextResponse.json({
        transcript: userSpokenText,
        clarification:
          "Please speak in English, Hindi, or Bengali so I can help you.",
      });
    }

    const normalizedTranscript = userSpokenText.toLowerCase();
    const wantsResetCart = getCartResetIntent(userSpokenText);

    let parsedCurrentCart: Record<string, any> | null = null;
    try {
      parsedCurrentCart = JSON.parse(currentCartString || "{}");
    } catch {
      parsedCurrentCart = null;
    }

    if (wantsResetCart) {
      const cartResetBlocked =
        Boolean(activeOrderId) ||
        Boolean(
          activeOrderStatus && activeOrderStatus.toUpperCase() !== "PENDING",
        ) ||
        Boolean(parsedCurrentCart?.checkoutRequested);

      if (cartResetBlocked) {
        return NextResponse.json({
          transcript: userSpokenText,
          clarification:
            "You can only reset the cart before confirming the order.",
        });
      }

      return NextResponse.json({
        transcript: userSpokenText,
        updatedCart: {
          orderJson: { itemList: [] },
          estimatedPrice: 0,
          checkoutRequested: false,
        },
      });
    }

    if (activeOrderId) {
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

      const { deliveryPersonName, deliveryPersonMobile } =
        getDeliveryDetails(statusPayload);
      const wantsToCallDriver =
        (normalizedTranscript.includes("call") ||
          normalizedTranscript.includes("phone") ||
          normalizedTranscript.includes("call karo") ||
          normalizedTranscript.includes("call koro") ||
          normalizedTranscript.includes("call koren") ||
          normalizedTranscript.includes("phone karo") ||
          normalizedTranscript.includes("phone koro")) &&
        (normalizedTranscript.includes("driver") ||
          normalizedTranscript.includes("delivery") ||
          normalizedTranscript.includes("delivery person") ||
          normalizedTranscript.includes("delivery partner") ||
          normalizedTranscript.includes("partner") ||
          normalizedTranscript.includes("driver ko"));

      if (wantsToCallDriver) {
        const phoneToCall = deliveryPersonMobile || null;
        const driverLabel = deliveryPersonName || "your delivery person";

        return NextResponse.json({
          transcript: userSpokenText,
          orderUpdate: {
            message: phoneToCall
              ? `I’m opening your dialer to call ${driverLabel} at ${phoneToCall}.`
              : "I don’t have the delivery partner’s phone number yet. I’ll keep checking the order status.",
            orderStatus: normalizedStatus,
            deliveryPersonName,
            deliveryPersonMobile: phoneToCall,
            shouldResetActiveOrder: false,
            shouldOpenDialer: Boolean(phoneToCall),
          },
        });
      }

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
        ACCEPTED: "Your order has been accepted and is being prepared.",
        SHOPPING: "Your delivery person is currently shopping for your order.",
        IN_TRANSIT: "Your order is on the way.",
      };

      const baseMessage =
        messageByStatus[normalizedStatus] ||
        "I’m tracking your current order and can share updates for it.";
      const deliverySummary = [
        deliveryPersonName ? `Driver: ${deliveryPersonName}` : null,
        deliveryPersonMobile ? `Phone: ${deliveryPersonMobile}` : null,
      ]
        .filter(Boolean)
        .join(". ");
      const message =
        normalizedStatus === "SHOPPING" || normalizedStatus === "IN_TRANSIT"
          ? `${baseMessage} You can call them on ${deliveryPersonMobile || "the number shared with you"}.`
          : deliverySummary
            ? `${baseMessage} ${deliverySummary}.`
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
    const systemPrompt = `You are a strict, production-grade JSON-only API for the EchoCart grocery application.
    Your job is to parse the user's voice request (transcribed via Whisper) and their CURRENT CART, and output the updated NEW CART state.
    
    CRITICAL OUTPUT RULE:
    - Output ONLY valid, parsable JSON. Do NOT wrap the response in markdown code blocks (\`\`\`json ... \`\`\`), do NOT include explanations, and do NOT append conversational filler. If your response contains anything other than raw JSON, the system breaks.
    
    ACCENT & PHONETIC TYPO RESILIENCE (INDIAN CONTEXT):
    - The voice input is transcribed from speakers with Indian accents, speaking in Indian English, Hindi, or Bengali.
    - Expect and automatically correct common accent-based phonetic transcription errors or mixed-language phrases (e.g., if Whisper transcribes "aloo" or "alu", treat it as "Potatoes"; if it transcribes "peaj" or "pyaz", treat it as "Onions").
    - Fix phonetic misunderstandings gracefully (e.g., "butter" transcribed poorly, or brand names like "Amul" misspelled as "Amool" or "Amlu"). Map them to the correct local market items.
    
    PRODUCT CATEGORY & ELIGIBILITY CONTROLS (QUICK-COMMERCE RULES):
    - Act strictly like a standard grocery and daily essentials delivery chain (e.g., Blinkit, Zepto, Instamart).
    - ALLOWED CATEGORIES: Groceries, fresh produce, household/common-use personal care products (including condoms, hygiene products), and over-the-counter (OTC) medicines. Basic mobile/electronic accessories and utilities (e.g., chargers, cables, batteries) ARE explicitly allowed.
    - STRICTLY PROHIBITED CATEGORIES: Alcohol, tobacco, high-value consumer electronics (e.g., TVs, iPhones, laptops, smartphones), or heavy appliances. 
    - If the user requests a prohibited item, do NOT add it to the cart. Instead, immediately return a clarification JSON object blocking the item. Example: {"action":"clarify","message":"Sorry, we do not deliver alcohol or high-value electronics like TVs and smartphones."}
    
    CORE FUNCTIONAL RULES:
    - The schema must exactly match the expected backend format.
    - All prices and the estimatedPrice MUST be in Indian Rupees (INR). Estimate realistic Indian market prices if exact prices are unknown.
    - For generic groceries (e.g., potatoes, rice, milk), DO NOT include parameters like "brand", "model", or "color". Include only name, price, and quantity.
    - If the user explicitly asks to "checkout", "place the order", or says they are "done", set the "checkoutRequested" flag to true. Otherwise, false.
    - Only process requests in English, Hindi, or Bengali. If the request is in any other language, immediately return a clarification JSON object asking the user to switch to English, Hindi, or Bengali.
    - Support cart-reset requests such as "reset cart", "clear cart", "empty cart", and their Hindi/Bengali equivalents (e.g., "cart saaf karo", "empty kore dao").
    - Do NOT allow checkout if the resulting cart has no items. If the cart is empty, return a clarification asking the user to add at least one item first.
    
    CONTEXT & FOLLOW-UP RESOLUTION:
    - Use the conversation history to resolve follow-up requests. If the user mentions an item first and then provides a quantity in a later turn, combine them into a single cart entry. Do not ask for the same detail again if the latest turn already provided it.
    - If the latest request is a short quantity or size follow-up (e.g., "2 kg", "2kgs", "500 ml", "one bottle"), treat it as applying directly to the most recent item mentioned in the conversation.
    
    NAMING & QUANTITY CONVENTIONS:
    - Incorporate specific units, package types, or metrics mentioned by the user if it dictates weight or volume. 
      Examples: 
      - '2.5 kg potatoes' -> name: 'Potatoes (kg)', quantity: 2.5
      - 'one 500 ml milk carton' -> name: '500ml Milk Carton', quantity: 1
      - 'Amul Butter 200g' -> name: 'Amul Butter 200g', quantity: 1
      - 'Tata Salt 1kg' -> name: 'Tata Salt 1kg', quantity: 1
    - Convert non-standard quantities (e.g., 'a pinch of salt', 'a handful of rice') to reasonable metric equivalents (e.g., 1g for a pinch, 50g for a handful) and reflect that conversion directly in the name and quantity fields.
    
    AMBIGUITY HANDLING:
    - If the user requests an item that is vague or ambiguous (e.g., 'some snacks', 'a few vegetables'), do not add it to the cart. Instead, immediately return a clarification JSON object.
    
    EXPECTED SCHEMA FOR CART UPDATES:
    {
      "orderJson": {
        "itemList": [
          { "name": "Item Name", "price": 50.0, "quantity": 1 }
        ]
      },
      "estimatedPrice": 50.0,
      "checkoutRequested": false
    }
    
    EXPECTED SCHEMA FOR CLARIFICATIONS:
    {
      "action": "clarify",
      "message": "Could you be more specific about which snacks you want?"
    }`;

    const conversationSummary = conversationContext.length
      ? `CONVERSATION HISTORY:\n${conversationContext
          .slice(-6)
          .map(
            (entry) =>
              `${entry.role === "user" ? "User" : "Assistant"}: ${entry.text}`,
          )
          .join("\n")}\n\n`
      : "";

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
              content: `${conversationSummary}CURRENT CART: ${currentCartString}\n\nUSER REQUEST: "${userSpokenText}"\n\nReturn the updated JSON cart.`,
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
    const wantsCheckout =
      normalizedTranscript.includes("checkout") ||
      normalizedTranscript.includes("place the order") ||
      normalizedTranscript.includes("place order") ||
      normalizedTranscript.includes("done") ||
      normalizedTranscript.includes("finish") ||
      normalizedTranscript.includes("order karo") ||
      normalizedTranscript.includes("order koro") ||
      normalizedTranscript.includes("order koren") ||
      normalizedTranscript.includes("confirm karo") ||
      normalizedTranscript.includes("confirm koro") ||
      normalizedTranscript.includes("confirm koren") ||
      normalizedTranscript.includes("order de do") ||
      normalizedTranscript.includes("order dedo");

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
