'use client';

import React, { useState, useEffect, useRef } from 'react';
import { useRouter } from 'next/navigation'; 
import { getTokens } from '@/utils/api';     
import Link from 'next/link';               
import { useAccessibility } from '../context/AccessibilityContext';
import VoiceInterface from '../components/VoiceInterface';

type Message = {
  id: string;
  role: 'user' | 'ai';
  text: string;
};

export default function Home() {
  const router = useRouter();
  const { announce } = useAccessibility();
  
  // AUTH CHECK: Redirects to login if no token
  useEffect(() => {
    const { token } = getTokens();
    if (!token) {
      router.push('/login');
    }
  }, [router]);

  // Initialize with a welcome message
  const [messages, setMessages] = useState<Message[]>([
    { id: '1', role: 'ai', text: 'EchoCart active. Hold the button below and tell me what you need to add to your order.' }
  ]);
  
  // Ref to handle auto-scrolling
  const chatEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    // Announce the initial load state for screen readers
    announce('EchoCart AI is ready. Hold the bottom button to speak.');
  }, [announce]);

  useEffect(() => {
    // Automatically scroll to the latest message whenever the array updates
    chatEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  return (
    <div className="flex flex-col min-h-screen max-w-md mx-auto border-x border-zinc-900 bg-black text-white">
      
      {/* UPDATED HEADER WITH PROFILE ICON */}
      <header className="p-6 border-b border-zinc-800 bg-zinc-950 flex justify-between items-center" role="banner">
        <div>
          <h1 className="text-3xl font-extrabold tracking-wide text-rose-500">EchoCart</h1>
          <p className="text-sm text-zinc-400 mt-1">AI Voice Assistant</p>
        </div>
        
        <Link 
          href="/profile" 
          className="p-3 border-2 border-zinc-700 rounded-full hover:border-rose-500 hover:bg-zinc-900 transition-colors"
          aria-label="Open Account Profile and Settings"
        >
          <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6 text-zinc-300" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
          </svg>
        </Link>
      </header>

      <main 
        className="flex-grow p-6 overflow-y-auto space-y-6" 
        role="log" 
        aria-live="polite"
        aria-atomic="false"
      >
        {messages.map((msg) => (
          <div 
            key={msg.id} 
            className={`p-4 rounded-2xl max-w-[85%] shadow-lg ${
              msg.role === 'user' 
                ? 'bg-rose-700 text-white ml-auto rounded-br-sm' 
                : 'bg-zinc-900 border border-zinc-800 text-zinc-100 mr-auto rounded-bl-sm'
            }`}
          >
            <span className="sr-only">
              {msg.role === 'user' ? 'You said:' : 'EchoCart said:'}
            </span>
            <p className="text-lg leading-relaxed">{msg.text}</p>
          </div>
        ))}
        <div ref={chatEndRef} />
      </main>

      <footer className="p-4 border-t border-zinc-900 sticky bottom-0 bg-black">
        <VoiceInterface />
      </footer>
      
    </div>
  );
}