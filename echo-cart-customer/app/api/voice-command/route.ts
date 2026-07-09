import { NextResponse } from 'next/server';

export async function POST(request: Request) {
  try {
    // 1. Receive the audio file from the frontend
    const formData = await request.formData();
    const audioFile = formData.get('audio') as Blob;
    
    if (!audioFile) {
      return NextResponse.json({ success: false, error: "No audio file received." }, { status: 400 });
    }

    console.log(`✅ Success: Received audio file on server. Size: ${audioFile.size} bytes`);

    // 2. [TODO] Send audioFile to OpenAI Whisper for text transcription
    
    // 3. [TODO] Parse text intent & make a fetch call to https://api.echocart.in
    
    // 4. Return the temporary response back to the screen reader
    return NextResponse.json({ 
      success: true, 
      message: "Audio received successfully by the server." 
    });

  } catch (error) {
    console.error("Server error processing audio:", error);
    return NextResponse.json({ success: false, error: "Server failed to process audio." }, { status: 500 });
  }
}