'use client';

import React, { useState, useRef } from 'react';
import { useAccessibility } from '../context/AccessibilityContext';

export default function VoiceInterface() {
    const { announce } = useAccessibility();
    const [isRecording, setIsRecording] = useState(false);

    // Refs to hold the recording instance and the data between renders
    const mediaRecorderRef = useRef<MediaRecorder | null>(null);
    const audioChunksRef = useRef<Blob[]>([]);

    const startRecording = async () => {
        try {
            // Request microphone access from the OS/Browser
            const stream = await navigator.mediaDevices.getUserMedia({ audio: true });

            const mediaRecorder = new MediaRecorder(stream);
            mediaRecorderRef.current = mediaRecorder;
            audioChunksRef.current = [];

            // Collect data chunks as the user speaks
            mediaRecorder.ondataavailable = (event) => {
                if (event.data.size > 0) {
                    audioChunksRef.current.push(event.data);
                }
            };

            // When the button is released, package the audio
            mediaRecorder.onstop = async () => {
                const audioBlob = new Blob(audioChunksRef.current, { type: 'audio/wav' });
                announce('Processing voice command.');
                stream.getTracks().forEach(track => track.stop());

                // --- NEW CODE: Send the file to our Next.js API ---
                const formData = new FormData();
                formData.append('audio', audioBlob, 'command.wav');

                try {
                    const response = await fetch('/api/voice-command', {
                        method: 'POST',
                        body: formData,
                    });
                    const data = await response.json();

                    if (data.success) {
                        announce(data.message);
                    } else {
                        announce('Error understanding command.');
                    }
                } catch (error) {
                    announce('Network error. Failed to reach server.');
                }
            };

            // Start recording
            mediaRecorder.start();
            setIsRecording(true);
            announce('Listening. Speak your request now.');

        } catch (err) {
            console.error("Microphone error:", err);
            announce('Microphone access denied or unavailable. Please check your browser permissions.');
        }
    };

    const stopRecording = () => {
        if (mediaRecorderRef.current && mediaRecorderRef.current.state === 'recording') {
            mediaRecorderRef.current.stop();
            setIsRecording(false);
        }
    };

    return (
        <button
            onMouseDown={startRecording}
            onMouseUp={stopRecording}
            onTouchStart={startRecording}
            onTouchEnd={stopRecording}
            className={`w-full py-12 text-2xl font-bold uppercase border-4 focus:outline-none focus:ring-4 focus:ring-rose-400 transition-colors ${isRecording
                    ? 'bg-red-600 border-red-400 animate-pulse text-white shadow-[0_0_20px_rgba(239,68,68,0.5)]'
                    : 'bg-black border-rose-500 text-rose-100 active:bg-zinc-900'
                }`}
            aria-label={isRecording ? "Listening. Release to send command." : "Hold to talk. Say an item to add to your cart."}
            style={{ touchAction: 'none', userSelect: 'none' }}
        >
            {isRecording ? 'Listening...' : 'Hold to Speak'}
        </button>
    );
}