import { NextRequest, NextResponse } from 'next/server';
import * as XLSX from 'xlsx';
import * as fs from 'fs';
import * as path from 'path';
import { createSecureApiHandler, sanitizeInput } from '@/lib/api/secure-api';
import { z } from 'zod';

const requestSchema = z.object({
  templatePath: z.string().min(1).max(500),
});

export const POST = createSecureApiHandler(
  async (request: NextRequest, { body, user }) => {
    const { templatePath } = body as z.infer<typeof requestSchema>;
    
    const sanitizedPath = sanitizeInput(templatePath);
    
    if (sanitizedPath.includes('..') || sanitizedPath.includes('~')) {
      return NextResponse.json({ error: 'Invalid template path' }, { status: 400 });
    }
    
    const fullPath = path.join(process.cwd(), sanitizedPath);
    
    if (!fullPath.startsWith(process.cwd())) {
      return NextResponse.json({ error: 'Path traversal attempt detected' }, { status: 403 });
    }
    
    if (!fs.existsSync(fullPath)) {
      return NextResponse.json({ error: 'Template file not found' }, { status: 404 });
    }
    
    const workbook = XLSX.readFile(fullPath);
    const firstSheet = workbook.SheetNames[0];
    const worksheet = workbook.Sheets[firstSheet];
    
    if (!worksheet) {
      return NextResponse.json({ error: 'No worksheet found' }, { status: 400 });
    }
    
    const html = XLSX.utils.sheet_to_html(worksheet, {
      id: 'excel-preview',
      editable: false
    });
    
    const mergedCells = worksheet['!merges'] || [];
    
    const css = `
      #excel-preview {
        border-collapse: collapse;
        font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        font-size: 11px;
        width: 100%;
      }
      
      #excel-preview td,
      #excel-preview th {
        border: 1px solid #d0d0d0;
        padding: 2px 4px;
        text-align: left;
        white-space: nowrap;
        min-height: 21px;
        vertical-align: top;
      }
      
      #excel-preview th {
        background-color: #f0f0f0;
        font-weight: bold;
      }
      
      #excel-preview tr:first-child th,
      #excel-preview tr:first-child td {
        background-color: #4a5568;
        color: white;
        font-weight: bold;
        text-align: center;
      }
      
      #excel-preview .merged-cell {
        text-align: center;
        font-weight: bold;
        background-color: #f8f9fa;
      }
      
      #excel-preview .number-cell {
        text-align: right;
      }
      
      #excel-preview .text-cell {
        text-align: left;
      }
      
      #excel-preview .center-cell {
        text-align: center;
      }
    `;
    
    return NextResponse.json({
      html,
      css,
      mergedCells,
      sheetName: firstSheet
    });
  },
  {
    requireAuth: true,
    rateLimit: true,
    validateBody: requestSchema,
  }
);