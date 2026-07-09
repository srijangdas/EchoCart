import { NextResponse } from 'next/server';

// Ensure you add OPENAI_API_KEY to your .env.local file
const OPENAI_API_KEY = process.env.OPENAI_API_KEY;

export async function POST(req: Request) {
  try {
    const formData = await req.formData();
    const audioFile = formData.get('audio') as Blob;
    const currentCartString = formData.get('currentCart') as string;

    if (!audioFile) {
      return NextResponse.json({ error: 'No audio file provided' }, { status: 400 });
    }

    // --- TRANSCRIPTION: Convert Audio to Text (Whisper) ---
    const whisperData = new FormData();
    whisperData.append('file', audioFile, 'recording.webm');
    whisperData.append('model', 'whisper-1');

    const whisperResponse = await fetch('https://api.openai.com/v1/audio/transcriptions', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${OPENAI_API_KEY}` },
      body: whisperData,
    });

    const whisperResult = await whisperResponse.json();

    // 1. Check if OpenAI explicitly rejected the request (e.g., Billing issues, Bad API Key)
    if (whisperResult.error) {
      console.error("OpenAI API Error:", whisperResult.error);
      return NextResponse.json({ 
        error: `OpenAI Error: ${whisperResult.error.message}` 
      }, { status: 500 });
    }

    const userSpokenText = whisperResult.text;

    // 2. Check if the audio was just completely silent or too short
    if (!userSpokenText || userSpokenText.trim() === '') {
      return NextResponse.json({ 
        error: 'No speech detected. Make sure to hold the button down while speaking.' 
      }, { status: 400 });
    }

    if (!userSpokenText) {
      return NextResponse.json({ error: 'Could not understand audio' }, { status: 400 });
    }

    // --- INTENT PARSING: Update the Cart (GPT-4o) ---
    const systemPrompt = `You are a strict JSON-only API for the EchoCart grocery application.
    Your job is to take the user's voice request and their CURRENT CART, and output the NEW CART state.
    
    CRITICAL RULES:
    - Output ONLY valid JSON. No markdown backticks, no explanations.
    - The schema must exactly match the expected backend format.
    - All prices and the estimatedPrice MUST be in Indian Rupees (INR). Estimate realistic Indian market prices if exact prices are unknown.
    - For generic groceries (e.g., potatoes, rice, milk), DO NOT include "brand", "model", or "color". Just name, price, and quantity.
    
    EXPECTED SCHEMA:
    {
      "orderJson": {
        "itemList": [
          { "name": "Item Name", "price": 50.0, "quantity": 1 }
        ]
      },
      "estimatedPrice": 50.0
    }`;

    const llmResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${OPENAI_API_KEY}`
      },
      body: JSON.stringify({
        model: 'gpt-4o',
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: `CURRENT CART: ${currentCartString}\n\nUSER REQUEST: "${userSpokenText}"\n\nReturn the updated JSON cart.` }
        ],
        temperature: 0.1 // Keep it low so the AI doesn't get overly creative with the JSON formatting
      })
    });

    const llmResult = await llmResponse.json();
    const rawContent = llmResult.choices[0].message.content;
    
    // Parse the AI's string response into an actual JSON object to send back to your frontend
    const updatedCart = JSON.parse(rawContent);

    return NextResponse.json({ 
      transcript: userSpokenText, 
      updatedCart: updatedCart 
    });

  } catch (error) {
    console.error("AI Processing Error:", error);
    return NextResponse.json({ error: 'Failed to process voice command' }, { status: 500 });
  }
}