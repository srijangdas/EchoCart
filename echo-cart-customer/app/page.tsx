'use client';

import React, { useState, useEffect, useRef } from 'react';
import { useRouter } from 'next/navigation';
import { getTokens } from '@/utils/api';
import Link from 'next/link';
import VoiceInterface from '../components/VoiceInterface';
import { useAccessibility } from '../context/AccessibilityContext';

type Message = {
  id: string;
  role: 'user' | 'ai';
  text: string;
};

export default function Home() {
  const router = useRouter();
  const { announce } = useAccessibility();

  // Authentication check
  useEffect(() => {
    const { token } = getTokens();
    if (!token) {
      router.push('/login');
    }
  }, [router]);

  // Initial load announcement
  useEffect(() => {
    announce('EchoCart AI is ready. Hold the bottom button to speak.');
  }, [announce]);

  const [messages, setMessages] = useState<Message[]>([
    { id: '1', role: 'ai', text: 'EchoCart active. Hold the button below and tell me what you need to add to your order.' }
  ]);
  
  const [cart, setCart] = useState({ 
    orderJson: { itemList: [] }, 
    estimatedPrice: 0 
  });

  const chatEndRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    chatEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const handleNewUserMessage = (text: string) => {
    setMessages(prev => [...prev, { id: Date.now().toString(), role: 'user', text }]);
  };

  const handleNewSystemMessage = (text: string) => {
    setMessages(prev => [...prev, { id: (Date.now() + 1).toString(), role: 'ai', text }]);
    // Speak the AI's response aloud
    announce(text);
  };

  const handleCartUpdate = (updatedCart: any) => {
    setCart(updatedCart);
  };

  const handleCheckout = () => {
    alert("This will send a final stateless POST to /api/orders:\n" + JSON.stringify(cart, null, 2));
  };

  return (
    <div className="flex flex-col min-h-screen max-w-md mx-auto border-x border-brand-border bg-brand-bg text-white">
      
      <header className="p-6 border-b border-brand-border bg-brand-surface flex justify-between items-center" role="banner">
        <div>
          <h1 className="text-3xl font-extrabold tracking-wide text-brand-primary">EchoCart</h1>
          <p className="text-sm text-brand-text-muted mt-1 font-medium" aria-live="polite">
            Cart Total: ₹{cart.estimatedPrice} | Items: {cart.orderJson.itemList.length}
          </p>
        </div>
        
        <Link 
          href="/profile" 
          className="p-3 border-2 border-brand-border rounded-full hover:border-brand-primary hover:bg-brand-surface text-brand-text-muted transition-colors"
          aria-label="Open Account Profile and Settings"
        >
          <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
          </svg>
        </Link>
      </header>

      <main className="grow p-6 overflow-y-auto space-y-6" role="log" aria-live="polite">
        {messages.map((msg) => (
          <div 
            key={msg.id} 
            className={`p-4 rounded-2xl max-w-[85%] shadow-lg ${
              msg.role === 'user' 
                ? 'bg-brand-primary text-brand-text-on-primary ml-auto rounded-br-sm' 
                : 'bg-brand-surface border border-brand-border text-white mr-auto rounded-bl-sm'
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

      {cart.orderJson.itemList.length > 0 && (
        <div className="p-4 bg-brand-bg">
          <button 
            onClick={handleCheckout}
            className="w-full py-4 bg-green-600 text-white font-bold rounded hover:bg-green-500 transition-colors"
          >
            Place Order (₹{cart.estimatedPrice})
          </button>
        </div>
      )}

      <footer className="sticky bottom-0 bg-brand-bg">
        <VoiceInterface 
          currentCart={cart}
          onCartUpdate={handleCartUpdate}
          onNewUserMessage={handleNewUserMessage}
          onNewSystemMessage={handleNewSystemMessage}
        />
      </footer>
      
    </div>
  );
}