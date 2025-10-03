'use client';

import React, { useEffect, useState, useRef } from 'react';
import { Range, Field } from '@/lib/logs/templates/types';
import { cn } from '@/lib/utils';

interface ExcelPreviewProps {
  html: string;
  css?: string;
  operationRange?: Range;
  fields?: Field[];
  onFieldClick?: (field: Field, cellRef: string) => void;
  className?: string;
}

export function ExcelPreview({
  html,
  css,
  operationRange,
  fields = [],
  onFieldClick,
  className
}: ExcelPreviewProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const [highlightedCells, setHighlightedCells] = useState<Set<string>>(new Set());
  
  useEffect(() => {
    if (!containerRef.current || !operationRange) return;
    
    const parseRange = (start: string, end: string) => {
      const startCol = start.match(/[A-Z]+/)?.[0] || 'A';
      const startRow = parseInt(start.match(/\d+/)?.[0] || '1');
      const endCol = end.match(/[A-Z]+/)?.[0] || 'A';
      const endRow = parseInt(end.match(/\d+/)?.[0] || '1');
      
      const cells = new Set<string>();
      const colToNum = (col: string) => {
        let num = 0;
        for (let i = 0; i < col.length; i++) {
          num = num * 26 + (col.charCodeAt(i) - 64);
        }
        return num;
      };
      
      const numToCol = (num: number) => {
        let col = '';
        while (num > 0) {
          const mod = (num - 1) % 26;
          col = String.fromCharCode(65 + mod) + col;
          num = Math.floor((num - mod) / 26);
        }
        return col;
      };
      
      const startColNum = colToNum(startCol);
      const endColNum = colToNum(endCol);
      
      for (let row = startRow; row <= endRow; row++) {
        for (let colNum = startColNum; colNum <= endColNum; colNum++) {
          cells.add(`${numToCol(colNum)}${row}`);
        }
      }
      
      return cells;
    };
    
    if (operationRange.role === 'operation') {
      const cells = parseRange(operationRange.start, operationRange.end);
      setHighlightedCells(cells);
    }
  }, [operationRange]);
  
  useEffect(() => {
    if (!containerRef.current) return;
    
    const tableElement = containerRef.current.querySelector('table');
    if (!tableElement) return;
    
    const handleCellClick = (e: MouseEvent) => {
      const target = e.target as HTMLElement;
      const td = target.closest('td, th');
      if (!td) return;
      
      const tr = td.closest('tr');
      if (!tr) return;
      
      const rowIndex = Array.from(tr.parentElement?.children || []).indexOf(tr);
      const cellIndex = Array.from(tr.children).indexOf(td);
      
      const col = String.fromCharCode(65 + cellIndex);
      const row = rowIndex + 1;
      const cellRef = `${col}${row}`;
      
      if (highlightedCells.has(cellRef) && onFieldClick) {
        const field = fields.find(f => f.excelKey === cellRef);
        if (field) {
          onFieldClick(field, cellRef);
        }
      }
    };
    
    tableElement.addEventListener('click', handleCellClick);
    return () => tableElement.removeEventListener('click', handleCellClick);
  }, [highlightedCells, fields, onFieldClick]);
  
  useEffect(() => {
    if (!containerRef.current) return;
    
    const addOperationHighlights = () => {
      const tds = containerRef.current?.querySelectorAll('td, th');
      tds?.forEach((td, index) => {
        const tr = td.closest('tr');
        if (!tr) return;
        
        const rowIndex = Array.from(tr.parentElement?.children || []).indexOf(tr);
        const cellIndex = Array.from(tr.children).indexOf(td);
        
        const col = String.fromCharCode(65 + cellIndex);
        const row = rowIndex + 1;
        const cellRef = `${col}${row}`;
        
        if (highlightedCells.has(cellRef)) {
          td.classList.add('operation-cell');
        }
      });
    };
    
    addOperationHighlights();
  }, [html, highlightedCells]);
  
  return (
    <div className={cn("excel-preview-container", className)}>
      <style>{`
        .excel-preview-container {
          width: 100%;
          overflow: auto;
          background: white;
          border-radius: 8px;
          padding: 16px;
        }
        
        .excel-preview-container table {
          border-collapse: collapse;
          font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
          font-size: 11px;
          min-width: 100%;
        }
        
        .excel-preview-container td,
        .excel-preview-container th {
          border: 1px solid #d0d0d0;
          padding: 2px 4px;
          text-align: left;
          white-space: nowrap;
          min-height: 21px;
        }
        
        .excel-preview-container th {
          background-color: #f0f0f0;
          font-weight: bold;
        }
        
        .excel-preview-container .operation-cell {
          background-color: rgba(59, 130, 246, 0.1);
          border: 2px solid #3b82f6;
          cursor: pointer;
          position: relative;
        }
        
        .excel-preview-container .operation-cell:hover {
          background-color: rgba(59, 130, 246, 0.2);
        }
        
        .excel-preview-container .operation-cell::after {
          content: '✏️';
          position: absolute;
          top: 2px;
          right: 2px;
          font-size: 10px;
          opacity: 0;
          transition: opacity 0.2s;
        }
        
        .excel-preview-container .operation-cell:hover::after {
          opacity: 0.7;
        }
        
        .excel-preview-container .locked-cell {
          background-color: rgba(156, 163, 175, 0.1);
          cursor: not-allowed;
        }
        
        .excel-preview-container .merged-cell {
          text-align: center;
          font-weight: bold;
        }
        
        ${css || ''}
      `}</style>
      
      <div 
        ref={containerRef}
        dangerouslySetInnerHTML={{ __html: html }}
      />
      
      {operationRange && (
        <div className="mt-4 p-3 bg-blue-50 rounded-lg border border-blue-200">
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 bg-blue-100 border-2 border-blue-500 rounded"></div>
            <span className="text-sm text-gray-700">
              Operation Area (Editable) - {operationRange.start} to {operationRange.end}
            </span>
          </div>
          <div className="flex items-center gap-2 mt-1">
            <div className="w-4 h-4 bg-gray-100 border border-gray-300 rounded"></div>
            <span className="text-sm text-gray-700">
              Locked Areas (Compliance)
            </span>
          </div>
        </div>
      )}
    </div>
  );
}