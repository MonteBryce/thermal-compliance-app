'use client';

import React, { useEffect, useState } from 'react';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { FileSpreadsheet, Eye, Download, AlertCircle, CheckCircle, GitGitCompare } from 'lucide-react';
import { Toggles, Targets, FieldSpec, OperationRange } from '@/lib/logs/templates/versioned-types';

interface LiveExcelPreviewProps {
  gasType: 'methane' | 'pentane';
  toggles: Toggles;
  targets: Targets;
  fields: FieldSpec[];
  excelTemplatePath: string;
  operationRange: OperationRange;
}

interface ExcelCell {
  value: string;
  type: 'header' | 'data' | 'operation' | 'locked';
  column: string;
  row: number;
  fieldKey?: string;
  unit?: string;
  required?: boolean;
}

export function LiveExcelPreview({
  gasType,
  toggles,
  targets,
  fields,
  excelTemplatePath,
  operationRange,
}: LiveExcelPreviewProps) {
  const [previewData, setPreviewData] = useState<ExcelCell[][]>([]);
  const [isGenerating, setIsGenerating] = useState(false);
  const [showComparison, setShowComparison] = useState(false);
  const [validationErrors, setValidationErrors] = useState<string[]>([]);

  useEffect(() => {
    generatePreview();
  }, [gasType, toggles, targets, fields]);

  const generatePreview = async () => {
    setIsGenerating(true);
    setValidationErrors([]);
    
    try {
      // Simulate Excel structure generation
      await new Promise(resolve => setTimeout(resolve, 500));
      
      const preview = generateExcelStructure();
      setPreviewData(preview);
      
      // Validate structure
      validateStructure(preview);
    } catch (error) {
      console.error('Failed to generate preview:', error);
    } finally {
      setIsGenerating(false);
    }
  };

  const generateExcelStructure = (): ExcelCell[][] => {
    const structure: ExcelCell[][] = [];
    
    // Generate column headers (row 1)
    const headers: ExcelCell[] = [
      { value: 'Time', type: 'header', column: 'A', row: 1 },
      { value: 'Date', type: 'header', column: 'B', row: 1 },
    ];
    
    // Add field-based headers
    let colIndex = 2;
    fields.forEach(field => {
      const column = String.fromCharCode(65 + colIndex);
      headers.push({
        value: `${field.label}${field.unit ? ` (${field.unit})` : ''}`,
        type: 'header',
        column,
        row: 1,
        fieldKey: field.key,
        unit: field.unit,
        required: field.required,
      });
      colIndex++;
    });
    
    structure.push(headers);
    
    // Generate operation area rows (12-28 for hourly logs)
    const startRow = 12;
    const endRow = toggles.is12hr ? 24 : 28;
    
    for (let row = startRow; row <= endRow; row++) {
      const rowData: ExcelCell[] = [];
      
      // Time column
      const hour = row - startRow;
      const timeValue = toggles.is12hr 
        ? `${hour === 0 ? 12 : hour > 12 ? hour - 12 : hour}:00 ${hour < 12 ? 'AM' : 'PM'}`
        : `${hour.toString().padStart(2, '0')}:00`;
      
      rowData.push({
        value: timeValue,
        type: 'locked',
        column: 'A',
        row,
      });
      
      // Date column
      rowData.push({
        value: 'MM/DD/YYYY',
        type: 'locked',
        column: 'B',
        row,
      });
      
      // Field columns
      colIndex = 2;
      fields.forEach(field => {
        const column = String.fromCharCode(65 + colIndex);
        const isInOperationRange = isColumnInRange(column, operationRange);
        
        rowData.push({
          value: getPlaceholderValue(field),
          type: isInOperationRange ? 'operation' : 'locked',
          column,
          row,
          fieldKey: field.key,
          unit: field.unit,
          required: field.required,
        });
        colIndex++;
      });
      
      structure.push(rowData);
    }
    
    return structure;
  };

  const isColumnInRange = (column: string, range: OperationRange): boolean => {
    const startCol = range.start.match(/[A-Z]+/)?.[0] || 'A';
    const endCol = range.end.match(/[A-Z]+/)?.[0] || 'Z';
    
    return column >= startCol && column <= endCol;
  };

  const getPlaceholderValue = (field: FieldSpec): string => {
    switch (field.type) {
      case 'number':
        if (field.key.includes('temp')) return '---°F';
        if (field.key.includes('vacuum')) return '---.--';
        if (field.key.includes('ppm')) return '---';
        if (field.key.includes('pct') || field.key.includes('%')) return '--.-%';
        return '---';
      case 'text':
        return field.key.includes('initial') ? '___' : '---';
      case 'time':
        return '--:--';
      default:
        return '---';
    }
  };

  const validateStructure = (structure: ExcelCell[][]) => {
    const errors: string[] = [];
    
    // Check required fields
    const requiredFields = fields.filter(f => f.required);
    const headerRow = structure[0];
    
    requiredFields.forEach(field => {
      const hasHeader = headerRow.some(cell => cell.fieldKey === field.key);
      if (!hasHeader) {
        errors.push(`Missing required field: ${field.label}`);
      }
    });
    
    // Check operation range coverage
    const operationCells = structure.flat().filter(cell => cell.type === 'operation');
    if (operationCells.length === 0) {
      errors.push('No cells in operation range - check range configuration');
    }
    
    // Check targets for enabled features
    if (toggles.hasH2S && !targets.h2sPPM) {
      errors.push('H₂S target required when H₂S monitoring is enabled');
    }
    
    if (toggles.hasBenzene && !targets.benzenePPM) {
      errors.push('Benzene target required when Benzene monitoring is enabled');
    }
    
    setValidationErrors(errors);
  };

  const getCellClassName = (cell: ExcelCell): string => {
    const base = 'border border-gray-300 px-2 py-1 text-xs min-w-[80px] text-center';
    
    switch (cell.type) {
      case 'header':
        return `${base} bg-gray-100 font-bold text-gray-800`;
      case 'operation':
        return `${base} bg-blue-50 border-blue-300 text-blue-800 ${cell.required ? 'font-medium' : ''}`;
      case 'locked':
        return `${base} bg-gray-50 text-gray-500`;
      default:
        return `${base} bg-white text-gray-700`;
    }
  };

  const exportPreview = () => {
    // TODO: Implement Excel export functionality
    console.log('Exporting preview...');
  };

  if (!excelTemplatePath) {
    return (
      <div className="text-center py-8">
        <FileSpreadsheet className="w-12 h-12 text-gray-400 mx-auto mb-4" />
        <h3 className="text-lg font-medium text-white mb-2">Upload Excel Template</h3>
        <p className="text-gray-400">
          Upload an Excel template to see the live preview with your current configuration.
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {/* Validation Errors */}
      {validationErrors.length > 0 && (
        <Alert variant="destructive">
          <AlertCircle className="w-4 h-4" />
          <AlertDescription>
            <div>
              <strong>Validation Issues:</strong>
              <ul className="list-disc list-inside mt-1">
                {validationErrors.map((error, index) => (
                  <li key={index} className="text-sm">{error}</li>
                ))}
              </ul>
            </div>
          </AlertDescription>
        </Alert>
      )}

      {/* Success Message */}
      {validationErrors.length === 0 && previewData.length > 0 && (
        <Alert className="bg-green-50 dark:bg-green-950 border-green-500">
          <CheckCircle className="w-4 h-4" />
          <AlertDescription>
            Template structure is valid and ready for use.
          </AlertDescription>
        </Alert>
      )}

      {/* Preview Controls */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <Badge className="bg-blue-600 text-white">
            Live Preview
          </Badge>
          <Badge variant="outline">
            {gasType.toUpperCase()}
          </Badge>
          {toggles.is12hr && (
            <Badge variant="outline">12-Hour</Badge>
          )}
        </div>
        
        <div className="flex gap-2">
          <Button
            variant="outline"
            size="sm"
            onClick={() => setShowComparison(!showComparison)}
            className="border-gray-600 text-gray-300"
          >
            <GitCompare className="w-4 h-4 mr-2" />
            GitCompare
          </Button>
          <Button
            variant="outline"
            size="sm"
            onClick={exportPreview}
            className="border-gray-600 text-gray-300"
          >
            <Download className="w-4 h-4 mr-2" />
            Export
          </Button>
        </div>
      </div>

      {/* Excel Preview Grid */}
      <div className="border border-gray-600 rounded-lg overflow-hidden bg-white">
        {isGenerating ? (
          <div className="p-8 text-center text-gray-500">
            Generating preview...
          </div>
        ) : (
          <div className="overflow-auto max-h-96">
            <table className="min-w-full">
              <tbody>
                {previewData.map((row, rowIndex) => (
                  <tr key={rowIndex}>
                    {row.map((cell, cellIndex) => (
                      <td
                        key={cellIndex}
                        className={getCellClassName(cell)}
                        title={cell.fieldKey ? `Field: ${cell.fieldKey}${cell.unit ? ` (${cell.unit})` : ''}` : undefined}
                      >
                        {cell.value}
                        {cell.required && (
                          <span className="text-red-500 ml-1">*</span>
                        )}
                      </td>
                    ))}
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Legend */}
      <div className="flex flex-wrap gap-4 text-sm">
        <div className="flex items-center gap-2">
          <div className="w-4 h-4 bg-gray-100 border border-gray-300"></div>
          <span className="text-gray-400">Headers</span>
        </div>
        <div className="flex items-center gap-2">
          <div className="w-4 h-4 bg-blue-50 border border-blue-300"></div>
          <span className="text-gray-400">Operation Area (Editable)</span>
        </div>
        <div className="flex items-center gap-2">
          <div className="w-4 h-4 bg-gray-50 border border-gray-300"></div>
          <span className="text-gray-400">Locked Areas</span>
        </div>
        <div className="flex items-center gap-2">
          <span className="text-red-500 font-bold">*</span>
          <span className="text-gray-400">Required Fields</span>
        </div>
      </div>

      {/* Field Summary */}
      <div className="grid grid-cols-3 gap-4 text-center">
        <div className="bg-[#1E1E1E] border border-gray-700 rounded-lg p-3">
          <div className="text-lg font-bold text-white">{fields.length}</div>
          <div className="text-sm text-gray-400">Total Fields</div>
        </div>
        <div className="bg-[#1E1E1E] border border-gray-700 rounded-lg p-3">
          <div className="text-lg font-bold text-orange-400">{fields.filter(f => f.required).length}</div>
          <div className="text-sm text-gray-400">Required</div>
        </div>
        <div className="bg-[#1E1E1E] border border-gray-700 rounded-lg p-3">
          <div className="text-lg font-bold text-blue-400">
            {previewData.flat().filter(cell => cell.type === 'operation').length}
          </div>
          <div className="text-sm text-gray-400">Editable Cells</div>
        </div>
      </div>
    </div>
  );
}