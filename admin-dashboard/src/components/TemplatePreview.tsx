'use client';

import React from 'react';
import { Button } from '@/components/ui/button';
import { ExternalLink, Download, Printer } from 'lucide-react';

export interface TemplatePreviewProps {
  src: string;
  title?: string;
  height?: number;
}

export function TemplatePreview({ 
  src, 
  title = "PDF Template",
  height = 900 
}: TemplatePreviewProps) {
  const handleOpenNewTab = () => {
    window.open(src, '_blank');
  };

  const handleDownload = () => {
    const link = document.createElement('a');
    link.href = src;
    link.download = src.split('/').pop() || 'template.pdf';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  const handlePrint = () => {
    window.print();
  };

  return (
    <div className="flex flex-col min-h-screen">
      {/* Header Bar */}
      <div className="bg-white border-b border-gray-200 px-6 py-4 print:hidden shadow-sm">
        <div className="flex items-center justify-between">
          <h1 className="text-xl font-semibold text-gray-900">
            {title}
          </h1>
          
          <div className="flex items-center gap-3">
            <button
              onClick={handleOpenNewTab}
              className="inline-flex items-center gap-2 px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md shadow-sm hover:bg-gray-50 hover:text-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors"
            >
              <ExternalLink className="w-4 h-4" />
              Open in new tab
            </button>
            
            <button
              onClick={handleDownload}
              className="inline-flex items-center gap-2 px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md shadow-sm hover:bg-gray-50 hover:text-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors"
            >
              <Download className="w-4 h-4" />
              Download PDF
            </button>
            
            <button
              onClick={handlePrint}
              className="inline-flex items-center gap-2 px-3 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-md shadow-sm hover:bg-gray-50 hover:text-gray-900 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors"
            >
              <Printer className="w-4 h-4" />
              Print
            </button>
          </div>
        </div>
      </div>

      {/* PDF Container */}
      <div className="flex-1 bg-gray-100 overflow-auto">
        <object
          data={src}
          type="application/pdf"
          className="w-full min-h-screen"
          style={{ height: `${height}px` }}
          aria-label={title}
        >
          <iframe 
            src={src} 
            className="w-full min-h-screen border-0" 
            style={{ height: `${height}px` }}
            title={title}
          />
        </object>
        
        {/* Fallback content for browsers that don't support PDF embedding */}
        <noscript>
          <div className="flex flex-col items-center justify-center h-full p-8 text-center">
            <p className="text-gray-600 mb-4">
              Your browser doesn't support embedded PDF viewing.
            </p>
            <a 
              href={src}
              download
              className="inline-flex items-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
            >
              <Download className="w-4 h-4" />
              Download PDF to view
            </a>
          </div>
        </noscript>
      </div>

      {/* Print Styles */}
      <style jsx global>{`
        @media print {
          .print\\:hidden {
            display: none !important;
          }
          
          body {
            margin: 0 !important;
            padding: 0 !important;
          }
          
          object[type="application/pdf"] {
            width: 100% !important;
            height: 100vh !important;
          }
        }
      `}</style>
    </div>
  );
}