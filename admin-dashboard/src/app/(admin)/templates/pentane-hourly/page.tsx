'use client';

import React, { useState, useEffect } from 'react';
import { TemplatePreview } from '@/components/TemplatePreview';

export default function PentaneHourlyTemplatePage() {
  const [viewportHeight, setViewportHeight] = useState(1000);

  useEffect(() => {
    const calculateHeight = () => {
      const headerHeight = 80; // Approximate header height
      const availableHeight = window.innerHeight - headerHeight;
      setViewportHeight(Math.max(availableHeight, 800));
    };

    calculateHeight();
    window.addEventListener('resize', calculateHeight);

    return () => {
      window.removeEventListener('resize', calculateHeight);
    };
  }, []);

  return (
    <div className="h-screen bg-gray-50 overflow-hidden">
      <TemplatePreview
        title="Pentane Hourly — Template Preview"
        src="/templates/pentane-hourly.pdf"
        height={viewportHeight}
      />
    </div>
  );
}