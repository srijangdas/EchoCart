'use client';

import React, { createContext, useContext, useState, useCallback } from 'react';

type AccessibilityContextType = {
  announcement: string;
  announce: (message: string) => void;
};

const AccessibilityContext = createContext<AccessibilityContextType | undefined>(undefined);

export function AccessibilityProvider({ children }: { children: React.ReactNode }) {
  const [announcement, setAnnouncement] = useState('');

  const announce = useCallback((message: string) => {
    setAnnouncement('');
    setTimeout(() => {
      setAnnouncement(message);
    }, 50);
  }, []);

  return (
    <AccessibilityContext.Provider value={{ announcement, announce }}>
      {children}
      <div 
        aria-live="assertive" 
        aria-atomic="true" 
        className="sr-only"
        style={{
          position: 'absolute', width: '1px', height: '1px', padding: '0',
          margin: '-1px', overflow: 'hidden', clip: 'rect(0, 0, 0, 0)',
          whiteSpace: 'nowrap', border: '0'
        }}
      >
        {announcement}
      </div>
    </AccessibilityContext.Provider>
  );
}

export function useAccessibility() {
  const context = useContext(AccessibilityContext);
  if (!context) {
    throw new Error('useAccessibility must be used within an AccessibilityProvider');
  }
  return context;
}