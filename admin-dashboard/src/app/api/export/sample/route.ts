import { NextRequest, NextResponse } from 'next/server';
import * as XLSX from 'xlsx';
import { Field } from '@/lib/logs/templates/types';

export async function POST(request: NextRequest) {
  try {
    const { templateFields, templateKey } = await request.json();
    
    if (!templateFields || !Array.isArray(templateFields)) {
      return NextResponse.json({ error: 'Template fields are required' }, { status: 400 });
    }
    
    const fields: Field[] = templateFields;
    
    const workbook = XLSX.utils.book_new();
    
    const headers = fields
      .filter(f => f.visible)
      .map(f => f.label);
    
    const sampleData = fields
      .filter(f => f.visible)
      .map(f => generateSampleValue(f));
    
    const worksheetData = [headers, sampleData];
    
    const worksheet = XLSX.utils.aoa_to_sheet(worksheetData);
    
    const columnWidths = headers.map(header => ({
      wch: Math.max(header.length + 2, 12)
    }));
    worksheet['!cols'] = columnWidths;
    
    fields.forEach((field, index) => {
      if (!field.visible) return;
      
      const headerCell = XLSX.utils.encode_cell({ r: 0, c: index });
      const dataCell = XLSX.utils.encode_cell({ r: 1, c: index });
      
      if (!worksheet[headerCell]) worksheet[headerCell] = {};
      if (!worksheet[dataCell]) worksheet[dataCell] = {};
      
      worksheet[headerCell].s = {
        font: { bold: true },
        fill: { fgColor: { rgb: "4A5568" } },
        alignment: { horizontal: "center" }
      };
      
      if (field.type === 'number') {
        worksheet[dataCell].t = 'n';
        worksheet[dataCell].s = {
          numFmt: field.unit?.includes('%') ? '0.00%' : '0.00'
        };
      }
    });
    
    const sheetName = 'Sample Log';
    XLSX.utils.book_append_sheet(workbook, worksheet, sheetName);
    
    const buffer = XLSX.write(workbook, { 
      type: 'buffer', 
      bookType: 'xlsx',
      compression: true
    });
    
    const fileName = `${templateKey || 'sample'}_log_template.xlsx`;
    
    return new NextResponse(buffer, {
      status: 200,
      headers: {
        'Content-Type': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'Content-Disposition': `attachment; filename="${fileName}"`,
        'Content-Length': buffer.length.toString()
      }
    });
    
  } catch (error) {
    console.error('Sample generation error:', error);
    return NextResponse.json(
      { error: 'Failed to generate sample file' },
      { status: 500 }
    );
  }
}

function generateSampleValue(field: Field): any {
  switch (field.type) {
    case 'number':
      if (field.label.toLowerCase().includes('temp')) {
        return 1650; // Sample temperature
      }
      if (field.label.toLowerCase().includes('ppm')) {
        return 25.5; // Sample PPM reading
      }
      if (field.label.toLowerCase().includes('pressure')) {
        return 14.7; // Sample pressure
      }
      if (field.label.toLowerCase().includes('flow')) {
        return 150.0; // Sample flow rate
      }
      return field.rules?.min || 0;
      
    case 'text':
      if (field.label.toLowerCase().includes('operator')) {
        return 'JD';
      }
      if (field.label.toLowerCase().includes('initial')) {
        return 'AB';
      }
      if (field.label.toLowerCase().includes('location')) {
        return 'Tank 001';
      }
      return 'Sample';
      
    case 'boolean':
      return true;
      
    case 'hour':
      return '01:00';
      
    default:
      return '';
  }
}