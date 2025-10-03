import { NextRequest, NextResponse } from 'next/server';
import * as XLSX from 'xlsx';
import { Field, ValidationResult, ValidationIssue } from '@/lib/logs/templates/types';

export async function POST(request: NextRequest) {
  try {
    const formData = await request.formData();
    const file = formData.get('file') as File;
    const templateFieldsJson = formData.get('templateFields') as string;
    
    if (!file) {
      return NextResponse.json({ error: 'No file provided' }, { status: 400 });
    }
    
    if (!templateFieldsJson) {
      return NextResponse.json({ error: 'No template fields provided' }, { status: 400 });
    }
    
    const templateFields: Field[] = JSON.parse(templateFieldsJson);
    
    const arrayBuffer = await file.arrayBuffer();
    const workbook = XLSX.read(arrayBuffer, { type: 'array' });
    const firstSheet = workbook.SheetNames[0];
    const worksheet = workbook.Sheets[firstSheet];
    
    if (!worksheet) {
      return NextResponse.json({ error: 'No worksheet found in file' }, { status: 400 });
    }
    
    const headerRow = getHeaderRow(worksheet);
    const excelHeaders = headerRow.map(cell => cell.trim().toLowerCase());
    const templateHeaders = templateFields
      .filter(f => f.excelKey)
      .map(f => f.label.trim().toLowerCase());
    
    const issues: ValidationIssue[] = [];
    
    templateFields.forEach((field, index) => {
      if (!field.excelKey) return;
      
      const fieldLabel = field.label.toLowerCase();
      const matchingHeader = excelHeaders.find(h => 
        h.includes(fieldLabel) || fieldLabel.includes(h)
      );
      
      if (!matchingHeader && field.required) {
        issues.push({
          field: field.id,
          type: 'missing',
          expected: field.label,
          suggestion: `Add column "${field.label}" to Excel template`
        });
      }
    });
    
    excelHeaders.forEach((header, index) => {
      const matchingField = templateFields.find(f => 
        f.label.toLowerCase().includes(header) || header.includes(f.label.toLowerCase())
      );
      
      if (!matchingField) {
        issues.push({
          field: `excel-col-${index}`,
          type: 'extra',
          actual: header,
          suggestion: `Remove column "${header}" or map to template field`
        });
      }
    });
    
    const orderIssues = checkColumnOrder(excelHeaders, templateFields);
    issues.push(...orderIssues);
    
    const result: ValidationResult = {
      valid: issues.filter(i => i.type === 'missing').length === 0,
      issues,
      autoFixAvailable: issues.some(i => i.type === 'orderMismatch' || i.type === 'renamed'),
      suggestedFields: generateAutoFixSuggestions(excelHeaders, templateFields)
    };
    
    return NextResponse.json(result);
    
  } catch (error) {
    console.error('Validation error:', error);
    return NextResponse.json(
      { error: 'Failed to validate template' },
      { status: 500 }
    );
  }
}

function getHeaderRow(worksheet: XLSX.WorkSheet): string[] {
  const range = XLSX.utils.decode_range(worksheet['!ref'] || 'A1:Z1');
  const headers: string[] = [];
  
  for (let col = range.s.c; col <= range.e.c; col++) {
    const cellAddress = XLSX.utils.encode_cell({ r: 0, c: col });
    const cell = worksheet[cellAddress];
    headers.push(cell?.v?.toString() || '');
  }
  
  return headers;
}

function checkColumnOrder(excelHeaders: string[], templateFields: Field[]): ValidationIssue[] {
  const issues: ValidationIssue[] = [];
  
  templateFields.forEach((field, expectedIndex) => {
    if (!field.excelKey) return;
    
    const fieldLabel = field.label.toLowerCase();
    const actualIndex = excelHeaders.findIndex(h => 
      h.includes(fieldLabel) || fieldLabel.includes(h)
    );
    
    if (actualIndex !== -1 && actualIndex !== expectedIndex) {
      issues.push({
        field: field.id,
        type: 'orderMismatch',
        expected: `Position ${expectedIndex + 1}`,
        actual: `Position ${actualIndex + 1}`,
        suggestion: `Move "${field.label}" to column ${expectedIndex + 1}`
      });
    }
  });
  
  return issues;
}

function generateAutoFixSuggestions(excelHeaders: string[], templateFields: Field[]): Field[] {
  const suggestions: Field[] = [];
  
  excelHeaders.forEach((header, index) => {
    const closestField = templateFields.find(f => 
      f.label.toLowerCase().includes(header) || header.includes(f.label.toLowerCase())
    );
    
    if (closestField) {
      suggestions.push({
        ...closestField,
        label: header,
        excelKey: XLSX.utils.encode_cell({ r: 0, c: index })
      });
    }
  });
  
  return suggestions;
}