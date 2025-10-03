'use client';

import React, { useState, useEffect, useMemo, useCallback } from 'react';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { 
  ZoomIn, 
  ZoomOut, 
  GitCompare, 
  ExternalLink, 
  Download,
  AlertCircle,
  CheckCircle,
  AlertTriangle,
  Eye,
  EyeOff
} from 'lucide-react';
import * as XLSX from 'xlsx';
import { Toggles, Targets } from '@/lib/logs/templates/versioned-types';

interface CellData {
  value: any;
  type: 'string' | 'number' | 'boolean' | 'date' | 'formula';
  style?: {
    bold?: boolean;
    italic?: boolean;
    underline?: boolean;
    backgroundColor?: string;
    color?: string;
    textAlign?: 'left' | 'center' | 'right';
    borderTop?: boolean;
    borderBottom?: boolean;
    borderLeft?: boolean;
    borderRight?: boolean;
  };
  diffStatus?: 'match' | 'changed' | 'missing' | 'added';
}

interface ExcelSheetData {
  cells: { [key: string]: CellData };
  columnWidths: { [key: string]: number };
  rowHeights: { [key: string]: number };
  mergedCells: string[];
}

interface ExcelPreviewProps {
  // Firebase Storage path to Excel file
  excelPath: string;
  
  // Operation range (e.g., "B12:N28")
  operationRange: string;
  
  // Template configuration for live updates
  gasType?: 'methane' | 'pentane';
  toggles?: Toggles;
  targets?: Targets;
  
  // Comparison mode
  compareToBlank?: boolean;
  showDiffOnly?: boolean;
  
  // Callbacks
  onDiffStatusChange?: (hasErrors: boolean, hasWarnings: boolean) => void;
  onCellClick?: (cellRef: string, cellData: CellData) => void;
  
  // Display options
  className?: string;
  height?: number;
}

interface DiffResult {
  hasErrors: boolean;
  hasWarnings: boolean;
  totalCells: number;
  matchingCells: number;
  changedCells: number;
  missingCells: number;
  addedCells: number;
}

// Helper functions moved to top level
const columnToNumber = (col: string): number => {
  let result = 0;
  for (let i = 0; i < col.length; i++) {
    result = result * 26 + (col.charCodeAt(i) - 64);
  }
  return result;
};

const numberToColumn = (num: number): string => {
  let result = '';
  while (num > 0) {
    num--;
    result = String.fromCharCode(65 + (num % 26)) + result;
    num = Math.floor(num / 26);
  }
  return result;
};

export function ExcelPreview({
  excelPath,
  operationRange,
  gasType = 'methane',
  toggles = {},
  targets = {},
  compareToBlank = false,
  showDiffOnly = false,
  onDiffStatusChange,
  onCellClick,
  className = '',
  height = 400
}: ExcelPreviewProps) {
  const [sheetData, setSheetData] = useState<ExcelSheetData | null>(null);
  const [blankSheetData, setBlankSheetData] = useState<ExcelSheetData | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [zoom, setZoom] = useState(100);
  const [showGridlines, setShowGridlines] = useState(true);
  
  // Parse operation range
  const parsedRange = useMemo(() => {
    const match = operationRange.match(/([A-Z]+)(\d+):([A-Z]+)(\d+)/);
    if (!match) return null;
    
    const [, startCol, startRow, endCol, endRow] = match;
    return {
      startCol: columnToNumber(startCol),
      startRow: parseInt(startRow),
      endCol: columnToNumber(endCol),
      endRow: parseInt(endRow),
      startColLetter: startCol,
      endColLetter: endCol
    };
  }, [operationRange]);

  // Load Excel file from Firebase Storage
  const loadExcelFile = useCallback(async (filePath: string, isBlank = false) => {
    try {
      setLoading(true);
      setError(null);

      // For demo purposes, we'll simulate loading from Firebase Storage
      // In production, you'd use Firebase SDK to download the file
      const response = await fetch(`/api/excel-storage?path=${encodeURIComponent(filePath)}`);
      
      if (!response.ok) {
        throw new Error('Failed to load Excel file');
      }

      const arrayBuffer = await response.arrayBuffer();
      const workbook = XLSX.read(arrayBuffer, { type: 'array' });
      
      // Get first worksheet
      const worksheet = workbook.Sheets[workbook.SheetNames[0]];
      const sheetData: ExcelSheetData = {
        cells: {},
        columnWidths: {},
        rowHeights: {},
        mergedCells: []
      };

      // Parse cells in operation range
      if (parsedRange) {
        for (let row = parsedRange.startRow; row <= parsedRange.endRow; row++) {
          for (let col = parsedRange.startCol; col <= parsedRange.endCol; col++) {
            const cellRef = numberToColumn(col) + row;
            const cell = worksheet[cellRef];
            
            if (cell) {
              const cellData: CellData = {
                value: cell.v,
                type: getCellType(cell),
                style: getCellStyle(cell)
              };

              // Apply dynamic updates based on toggles/targets
              if (!isBlank) {
                cellData.value = applyDynamicUpdates(cellData.value, cellRef, gasType, toggles, targets);
              }

              sheetData.cells[cellRef] = cellData;
            }
          }
        }

        // Extract column widths and row heights
        if (worksheet['!cols']) {
          worksheet['!cols'].forEach((col, index) => {
            if (col && col.width) {
              const colLetter = numberToColumn(parsedRange.startCol + index);
              sheetData.columnWidths[colLetter] = col.width;
            }
          });
        }

        if (worksheet['!rows']) {
          worksheet['!rows'].forEach((row, index) => {
            if (row && row.height) {
              sheetData.rowHeights[parsedRange.startRow + index] = row.height;
            }
          });
        }

        // Extract merged cells
        if (worksheet['!merges']) {
          worksheet['!merges'].forEach(merge => {
            const mergeRange = XLSX.utils.encode_range(merge);
            sheetData.mergedCells.push(mergeRange);
          });
        }
      }

      if (isBlank) {
        setBlankSheetData(sheetData);
      } else {
        setSheetData(sheetData);
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load Excel file');
    } finally {
      setLoading(false);
    }
  }, [parsedRange, gasType, toggles, targets]);

  // Get cell type from XLSX cell
  const getCellType = (cell: any): CellData['type'] => {
    if (cell.t === 's') return 'string';
    if (cell.t === 'n') return 'number';
    if (cell.t === 'b') return 'boolean';
    if (cell.t === 'd') return 'date';
    if (cell.f) return 'formula';
    return 'string';
  };

  // Get cell style from XLSX cell
  const getCellStyle = (cell: any): CellData['style'] => {
    const style: CellData['style'] = {};
    
    if (cell.s) {
      const cellStyle = cell.s;
      
      if (cellStyle.font) {
        style.bold = cellStyle.font.bold;
        style.italic = cellStyle.font.italic;
        style.underline = cellStyle.font.underline;
        if (cellStyle.font.color) {
          style.color = `#${cellStyle.font.color.rgb || '000000'}`;
        }
      }
      
      if (cellStyle.fill && cellStyle.fill.bgColor) {
        style.backgroundColor = `#${cellStyle.fill.bgColor.rgb || 'FFFFFF'}`;
      }
      
      if (cellStyle.alignment) {
        style.textAlign = cellStyle.alignment.horizontal || 'left';
      }
      
      if (cellStyle.border) {
        style.borderTop = !!cellStyle.border.top;
        style.borderBottom = !!cellStyle.border.bottom;
        style.borderLeft = !!cellStyle.border.left;
        style.borderRight = !!cellStyle.border.right;
      }
    }
    
    return style;
  };

  // Apply dynamic updates based on template configuration
  const applyDynamicUpdates = (
    value: any, 
    cellRef: string, 
    gasType: 'methane' | 'pentane',
    toggles: Toggles,
    targets: Targets
  ): any => {
    if (typeof value !== 'string') return value;

    let updatedValue = value;

    // Gas type substitutions
    if (gasType === 'pentane') {
      updatedValue = updatedValue
        .replace(/methane/gi, 'pentane')
        .replace(/CH4/g, 'C5H12')
        .replace(/C1/g, 'C5');
    }

    // Toggle-based substitutions
    if (toggles.hasH2S && value.toLowerCase().includes('h2s')) {
      updatedValue = updatedValue.replace(/\b0\b/g, targets.h2sPPM?.toString() || '10');
    }

    if (toggles.hasBenzene && value.toLowerCase().includes('benzene')) {
      updatedValue = updatedValue.replace(/\b0\b/g, targets.benzenePPM?.toString() || '1');
    }

    if (toggles.hasLEL && value.toLowerCase().includes('lel')) {
      updatedValue = updatedValue.replace(/\b0\b/g, targets.lelPct?.toString() || '5');
    }

    if (toggles.isRefill && value.toLowerCase().includes('refill')) {
      updatedValue = updatedValue.replace(/\b0\b/g, targets.tankRefillBBLHR?.toString() || '100');
    }

    // Time format changes for 12-hour mode
    if (toggles.is12hr && /\d{2}:\d{2}/.test(value)) {
      // Convert 24-hour to 12-hour format
      const timeMatch = value.match(/(\d{2}):(\d{2})/);
      if (timeMatch) {
        const hours = parseInt(timeMatch[1]);
        const minutes = timeMatch[2];
        const period = hours >= 12 ? 'PM' : 'AM';
        const displayHours = hours === 0 ? 12 : hours > 12 ? hours - 12 : hours;
        updatedValue = value.replace(/\d{2}:\d{2}/, `${displayHours}:${minutes} ${period}`);
      }
    }

    return updatedValue;
  };

  // Perform diff comparison
  const diffResult: DiffResult = useMemo(() => {
    if (!compareToBlank || !sheetData || !blankSheetData) {
      return {
        hasErrors: false,
        hasWarnings: false,
        totalCells: 0,
        matchingCells: 0,
        changedCells: 0,
        missingCells: 0,
        addedCells: 0
      };
    }

    let totalCells = 0;
    let matchingCells = 0;
    let changedCells = 0;
    let missingCells = 0;
    let addedCells = 0;

    // Compare current sheet to blank template
    const allCellRefs = new Set([
      ...Object.keys(sheetData.cells),
      ...Object.keys(blankSheetData.cells)
    ]);

    allCellRefs.forEach(cellRef => {
      totalCells++;
      const currentCell = sheetData.cells[cellRef];
      const blankCell = blankSheetData.cells[cellRef];

      if (currentCell && blankCell) {
        if (currentCell.value === blankCell.value) {
          matchingCells++;
          currentCell.diffStatus = 'match';
        } else {
          changedCells++;
          currentCell.diffStatus = 'changed';
        }
      } else if (currentCell && !blankCell) {
        addedCells++;
        currentCell.diffStatus = 'added';
      } else if (!currentCell && blankCell) {
        missingCells++;
        // Add missing cell to current sheet for display
        sheetData.cells[cellRef] = {
          ...blankCell,
          diffStatus: 'missing'
        };
      }
    });

    const hasErrors = missingCells > 0;
    const hasWarnings = changedCells > 0;

    return {
      hasErrors,
      hasWarnings,
      totalCells,
      matchingCells,
      changedCells,
      missingCells,
      addedCells
    };
  }, [sheetData, blankSheetData, compareToBlank]);

  // Notify parent of diff status changes
  useEffect(() => {
    if (onDiffStatusChange && compareToBlank) {
      onDiffStatusChange(diffResult.hasErrors, diffResult.hasWarnings);
    }
  }, [diffResult, onDiffStatusChange, compareToBlank]);

  // Load Excel files
  useEffect(() => {
    if (excelPath) {
      loadExcelFile(excelPath, false);
    }
  }, [excelPath, loadExcelFile]);

  useEffect(() => {
    if (compareToBlank && excelPath) {
      // Load blank template (same file but without dynamic updates)
      loadExcelFile(excelPath, true);
    }
  }, [compareToBlank, excelPath, loadExcelFile]);

  // Handle zoom changes
  const handleZoomIn = () => setZoom(prev => Math.min(prev + 25, 200));
  const handleZoomOut = () => setZoom(prev => Math.max(prev - 25, 50));

  // Render cell content
  const renderCell = (cellRef: string, rowIndex: number, colIndex: number) => {
    const cellData = sheetData?.cells[cellRef];
    if (!cellData && !showDiffOnly) return null;
    if (showDiffOnly && cellData?.diffStatus === 'match') return null;

    const isHeader = rowIndex === 0;
    const isNumeric = cellData?.type === 'number';
    
    let backgroundColor = cellData?.style?.backgroundColor || '#ffffff';
    let textColor = cellData?.style?.color || '#000000';
    
    // Apply diff status colors
    if (compareToBlank && cellData?.diffStatus) {
      switch (cellData.diffStatus) {
        case 'match':
          backgroundColor = '#f0f9ff'; // Light blue
          break;
        case 'changed':
          backgroundColor = '#fef3c7'; // Light yellow
          break;
        case 'missing':
          backgroundColor = '#fee2e2'; // Light red
          break;
        case 'added':
          backgroundColor = '#d1fae5'; // Light green
          break;
      }
    }

    const cellStyle: React.CSSProperties = {
      padding: '4px 8px',
      backgroundColor,
      color: textColor,
      fontWeight: (cellData?.style?.bold || isHeader) ? 'bold' : 'normal',
      fontStyle: cellData?.style?.italic ? 'italic' : 'normal',
      textDecoration: cellData?.style?.underline ? 'underline' : 'none',
      textAlign: isNumeric ? 'right' : (cellData?.style?.textAlign || 'left'),
      borderTop: (cellData?.style?.borderTop || showGridlines) ? '1px solid #e5e7eb' : 'none',
      borderBottom: (cellData?.style?.borderBottom || showGridlines) ? '1px solid #e5e7eb' : 'none',
      borderLeft: (cellData?.style?.borderLeft || showGridlines) ? '1px solid #e5e7eb' : 'none',
      borderRight: (cellData?.style?.borderRight || showGridlines) ? '1px solid #e5e7eb' : 'none',
      fontSize: `${zoom}%`,
      minHeight: '24px',
      whiteSpace: 'nowrap',
      overflow: 'hidden',
      textOverflow: 'ellipsis',
      cursor: 'pointer'
    };

    const displayValue = cellData?.value ?? '';

    return (
      <div
        key={cellRef}
        style={cellStyle}
        onClick={() => onCellClick?.(cellRef, cellData!)}
        title={`${cellRef}: ${displayValue}`}
      >
        {displayValue}
      </div>
    );
  };

  if (loading) {
    return (
      <Card className={className}>
        <CardContent className="flex items-center justify-center p-12">
          <div className="text-gray-400">Loading Excel preview...</div>
        </CardContent>
      </Card>
    );
  }

  if (error) {
    return (
      <Card className={className}>
        <CardContent className="p-6">
          <Alert>
            <AlertCircle className="h-4 w-4" />
            <AlertDescription>{error}</AlertDescription>
          </Alert>
        </CardContent>
      </Card>
    );
  }

  if (!sheetData || !parsedRange) {
    return (
      <Card className={className}>
        <CardContent className="flex items-center justify-center p-12">
          <div className="text-gray-400">No Excel data available</div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className={className}>
      <CardHeader>
        <div className="flex items-center justify-between">
          <CardTitle className="flex items-center gap-2">
            <Eye className="w-5 h-5" />
            Excel Preview
            <Badge variant="outline">{operationRange}</Badge>
          </CardTitle>
          
          <div className="flex items-center gap-2">
            {/* Zoom Controls */}
            <div className="flex items-center gap-1">
              <Button variant="outline" size="sm" onClick={handleZoomOut}>
                <ZoomOut className="w-4 h-4" />
              </Button>
              <Select value={zoom.toString()} onValueChange={(value) => setZoom(parseInt(value))}>
                <SelectTrigger className="w-20">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="50">50%</SelectItem>
                  <SelectItem value="75">75%</SelectItem>
                  <SelectItem value="100">100%</SelectItem>
                  <SelectItem value="125">125%</SelectItem>
                  <SelectItem value="150">150%</SelectItem>
                  <SelectItem value="200">200%</SelectItem>
                </SelectContent>
              </Select>
              <Button variant="outline" size="sm" onClick={handleZoomIn}>
                <ZoomIn className="w-4 h-4" />
              </Button>
            </div>

            {/* View Options */}
            <Button
              variant="outline"
              size="sm"
              onClick={() => setShowGridlines(!showGridlines)}
            >
              {showGridlines ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
              Gridlines
            </Button>

            {/* Actions */}
            <Button variant="outline" size="sm">
              <ExternalLink className="w-4 h-4 mr-2" />
              Open Original
            </Button>
            
            <Button variant="outline" size="sm">
              <Download className="w-4 h-4 mr-2" />
              Download
            </Button>
          </div>
        </div>

        {/* Diff Status */}
        {compareToBlank && (
          <div className="flex items-center gap-4 mt-2">
            <div className="flex items-center gap-2">
              <GitCompare className="w-4 h-4" />
              <span className="text-sm font-medium">Comparison to Blank Template:</span>
            </div>
            
            <div className="flex items-center gap-4 text-sm">
              <div className="flex items-center gap-1">
                <CheckCircle className="w-4 h-4 text-green-600" />
                <span>{diffResult.matchingCells} Matching</span>
              </div>
              
              {diffResult.changedCells > 0 && (
                <div className="flex items-center gap-1">
                  <AlertTriangle className="w-4 h-4 text-yellow-600" />
                  <span>{diffResult.changedCells} Changed</span>
                </div>
              )}
              
              {diffResult.missingCells > 0 && (
                <div className="flex items-center gap-1">
                  <AlertCircle className="w-4 h-4 text-red-600" />
                  <span>{diffResult.missingCells} Missing</span>
                </div>
              )}
              
              {diffResult.addedCells > 0 && (
                <div className="flex items-center gap-1">
                  <CheckCircle className="w-4 h-4 text-blue-600" />
                  <span>{diffResult.addedCells} Added</span>
                </div>
              )}
            </div>

            {diffResult.hasErrors && (
              <Badge variant="destructive">
                Validation Failed
              </Badge>
            )}
            
            {diffResult.hasWarnings && !diffResult.hasErrors && (
              <Badge variant="outline" className="border-yellow-500 text-yellow-600">
                Has Warnings
              </Badge>
            )}
          </div>
        )}
      </CardHeader>

      <CardContent>
        {/* Excel Grid */}
        <div
          className="border border-gray-300 overflow-auto bg-white"
          style={{ height: `${height}px` }}
        >
          <div className="inline-block min-w-full">
            {/* Grid Header */}
            <div className="sticky top-0 bg-gray-50 border-b border-gray-300 flex">
              {/* Row Header */}
              <div className="w-12 p-2 border-r border-gray-300 text-center text-xs font-medium text-gray-600">
                #
              </div>
              
              {/* Column Headers */}
              {Array.from({ length: parsedRange.endCol - parsedRange.startCol + 1 }, (_, colIndex) => {
                const colNumber = parsedRange.startCol + colIndex;
                const colLetter = numberToColumn(colNumber);
                const width = sheetData.columnWidths[colLetter] || 100;
                
                return (
                  <div
                    key={colLetter}
                    className="p-2 border-r border-gray-300 text-center text-xs font-medium text-gray-600 bg-gray-50"
                    style={{ width: `${width * zoom / 100}px`, minWidth: '60px' }}
                  >
                    {colLetter}
                  </div>
                );
              })}
            </div>

            {/* Grid Rows */}
            {Array.from({ length: parsedRange.endRow - parsedRange.startRow + 1 }, (_, rowIndex) => {
              const rowNumber = parsedRange.startRow + rowIndex;
              const height = sheetData.rowHeights[rowNumber] || 20;
              
              return (
                <div key={rowNumber} className="flex">
                  {/* Row Header */}
                  <div
                    className="w-12 p-2 border-r border-b border-gray-300 text-center text-xs text-gray-600 bg-gray-50"
                    style={{ minHeight: `${height * zoom / 100}px` }}
                  >
                    {rowNumber}
                  </div>
                  
                  {/* Row Cells */}
                  {Array.from({ length: parsedRange.endCol - parsedRange.startCol + 1 }, (_, colIndex) => {
                    const colNumber = parsedRange.startCol + colIndex;
                    const colLetter = numberToColumn(colNumber);
                    const cellRef = colLetter + rowNumber;
                    const width = sheetData.columnWidths[colLetter] || 100;
                    
                    return (
                      <div
                        key={cellRef}
                        style={{ 
                          width: `${width * zoom / 100}px`, 
                          minWidth: '60px',
                          minHeight: `${height * zoom / 100}px`
                        }}
                      >
                        {renderCell(cellRef, rowIndex, colIndex)}
                      </div>
                    );
                  })}
                </div>
              );
            })}
          </div>
        </div>

        {/* Legend for diff colors */}
        {compareToBlank && (
          <div className="mt-4 flex items-center gap-6 text-xs">
            <div className="flex items-center gap-2">
              <div className="w-4 h-4 bg-blue-100 border border-gray-300"></div>
              <span>Matching</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-4 h-4 bg-yellow-100 border border-gray-300"></div>
              <span>Changed</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-4 h-4 bg-red-100 border border-gray-300"></div>
              <span>Missing</span>
            </div>
            <div className="flex items-center gap-2">
              <div className="w-4 h-4 bg-green-100 border border-gray-300"></div>
              <span>Added</span>
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  );
}