'use client';

import { useEffect, useRef, useState } from 'react';
import { HotTable } from '@handsontable/react';
import { registerAllModules } from 'handsontable/registry';
import 'handsontable/dist/handsontable.full.min.css';
import { LogTemplate, TemplateMetric } from '@/lib/types/template';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Clock, Thermometer, Gauge, Wind, Droplets } from 'lucide-react';

// Register Handsontable modules
registerAllModules();

interface TemplateGridPreviewProps {
  template: LogTemplate;
  isEditable?: boolean;
  showMetadata?: boolean;
  onCellValueChange?: (row: number, col: number, oldValue: any, newValue: any) => void;
}

export function TemplateGridPreview({ 
  template, 
  isEditable = false,
  showMetadata = true,
  onCellValueChange 
}: TemplateGridPreviewProps) {
  // Early return if template is not provided
  if (!template) {
    return (
      <div className="flex items-center justify-center p-8 text-gray-500">
        <p>No template data available</p>
      </div>
    );
  }
  const hotTableRef = useRef<HotTable>(null);
  const [gridData, setGridData] = useState<(string | number)[][]>([]);
  const [columnHeaders, setColumnHeaders] = useState<string[]>([]);
  const [rowHeaders, setRowHeaders] = useState<string[]>([]);
  const [nestedHeaders, setNestedHeaders] = useState<any[]>([]);

  useEffect(() => {
    setupGridData();
  }, [template]);

  const setupGridData = () => {
    // Get visible metrics sorted by order
    const visibleMetrics = (template.metrics || [])
      .filter(metric => metric.visible)
      .sort((a, b) => a.order - b.order);

    // Setup column headers (hours)
    const headers = ['Metric', ...(template.hours || [])];
    setColumnHeaders(headers);

    // Setup nested headers for AM/PM grouping
    const nested = [];
    if (template.groups && template.groups.length > 0) {
      const nestedRow = ['Metric'];
      
      template.groups.forEach(group => {
        nestedRow.push({
          label: group.label,
          colspan: group.hours.length
        });
      });
      
      nested.push(nestedRow);
      nested.push(headers);
    }
    setNestedHeaders(nested);

    // Setup row headers (metric labels)
    const rowLabels = visibleMetrics.map(metric => 
      metric.unit ? `${metric.label} (${metric.unit})` : metric.label
    );
    setRowHeaders(rowLabels);

    // Setup grid data (empty cells with metric labels in first column)
    const data: (string | number)[][] = [];
    
    visibleMetrics.forEach((metric, rowIndex) => {
      const row: (string | number)[] = [];
      
      // First column: metric label with unit
      row.push(metric.unit ? `${metric.label} (${metric.unit})` : metric.label);
      
      // Remaining columns: empty cells for each hour
      (template.hours || []).forEach(() => {
        row.push(''); // Empty placeholder cells
      });
      
      data.push(row);
    });

    setGridData(data);
  };

  const getColumnWidth = (colIndex: number) => {
    if (colIndex === 0) return 250; // Metric label column
    return 70; // Hour columns
  };

  const getCellRenderer = (instance: any, td: HTMLTableCellElement, row: number, col: number, prop: any, value: any, cellProperties: any) => {
    // Style the metric label column
    if (col === 0) {
      td.style.backgroundColor = '#1E1E1E';
      td.style.color = '#F59E0B';
      td.style.fontWeight = 'bold';
      td.style.fontSize = '12px';
      td.style.borderRight = '2px solid #374151';
    } else {
      // Style hour cells
      td.style.backgroundColor = '#111111';
      td.style.color = '#9CA3AF';
      td.style.textAlign = 'center';
      td.style.fontSize = '14px';
      
      // Add placeholder text for empty cells
      if (!value || value === '') {
        const metric = (template.metrics || []).filter(m => m.visible).sort((a, b) => a.order - b.order)[row];
        if (metric?.unit) {
          td.style.color = '#6B7280';
          td.innerHTML = `<span style="font-style: italic;">-- ${metric.unit} --</span>`;
        } else {
          td.innerHTML = '<span style="font-style: italic; color: #6B7280;">--</span>';
        }
      }
    }
    
    return td;
  };

  const getCellClassName = (row: number, col: number) => {
    const classNames = [];
    
    if (col === 0) {
      classNames.push('metric-label-cell');
    } else {
      classNames.push('hour-cell');
      
      // Add styling for different hour groups
      const hourIndex = col - 1;
      if (hourIndex < 12) {
        classNames.push('am-hour');
      } else {
        classNames.push('pm-hour');
      }
    }
    
    return classNames.join(' ');
  };

  const getMetricIcon = (metric: TemplateMetric) => {
    switch (metric.category) {
      case 'primary':
        return <Thermometer className="h-4 w-4 text-red-400" />;
      case 'flow':
        return <Wind className="h-4 w-4 text-cyan-400" />;
      case 'pressure':
        return <Gauge className="h-4 w-4 text-blue-400" />;
      case 'composition':
        return <Droplets className="h-4 w-4 text-purple-400" />;
      default:
        return <Clock className="h-4 w-4 text-gray-400" />;
    }
  };

  const visibleMetrics = (template.metrics || [])
    .filter(metric => metric.visible)
    .sort((a, b) => a.order - b.order);

  return (
    <div className="space-y-4">
      {/* Template Metadata */}
      {showMetadata && (
        <Card className="bg-[#1E1E1E] border-gray-800">
          <CardHeader>
            <div className="flex items-center justify-between">
              <div>
                <CardTitle className="text-white">{template.displayName}</CardTitle>
                <p className="text-gray-400 text-sm mt-1">{template.description}</p>
              </div>
              <div className="flex items-center gap-2">
                <Badge className="bg-blue-600 text-white border-0">
                  v{template.version}
                </Badge>
                <Badge className="bg-green-600 text-white border-0">
                  {visibleMetrics.length} metrics
                </Badge>
              </div>
            </div>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
              <div>
                <p className="text-gray-400 text-xs">Log Type</p>
                <p className="text-white font-mono">{template.logType}</p>
              </div>
              <div>
                <p className="text-gray-400 text-xs">Hours</p>
                <p className="text-white">{(template.hours || []).length} hours</p>
              </div>
              <div>
                <p className="text-gray-400 text-xs">Required Fields</p>
                <p className="text-white">{visibleMetrics.filter(m => m.required).length}</p>
              </div>
              <div>
                <p className="text-gray-400 text-xs">Last Updated</p>
                <p className="text-white text-sm">
                  {new Date(template.updatedAt).toLocaleDateString()}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Metrics Summary */}
      <Card className="bg-[#1E1E1E] border-gray-800">
        <CardHeader>
          <CardTitle className="text-white text-sm">Visible Metrics</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex flex-wrap gap-2">
            {visibleMetrics.map((metric) => (
              <div key={metric.key} className="flex items-center gap-1 bg-gray-800 rounded px-2 py-1">
                {getMetricIcon(metric)}
                <span className="text-white text-xs">{metric.label}</span>
                {metric.unit && (
                  <span className="text-gray-400 text-xs">({metric.unit})</span>
                )}
                {metric.required && (
                  <span className="text-red-400 text-xs">*</span>
                )}
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      {/* Excel-style Grid */}
      <Card className="bg-[#1E1E1E] border-gray-800">
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="text-white">Template Preview</CardTitle>
            <div className="flex items-center gap-2">
              <Badge className="bg-orange-600 text-white border-0">
                Excel-style Grid
              </Badge>
              {!isEditable && (
                <Badge className="border-gray-600 text-gray-300">
                  Read Only
                </Badge>
              )}
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <div className="overflow-hidden rounded-lg border border-gray-700 bg-[#111111]">
            <style jsx>{`
              .handsontable {
                color: white !important;
                font-family: 'JetBrains Mono', monospace !important;
              }
              
              .handsontable .htCore thead th {
                background: #1E1E1E !important;
                color: #F59E0B !important;
                border-color: #374151 !important;
                font-weight: bold !important;
                text-align: center !important;
              }
              
              .handsontable .metric-label-cell {
                background: #1E1E1E !important;
                color: #F59E0B !important;
                font-weight: bold !important;
                border-right: 2px solid #374151 !important;
              }
              
              .handsontable .hour-cell {
                background: #111111 !important;
                color: #9CA3AF !important;
                text-align: center !important;
              }
              
              .handsontable .am-hour {
                border-top: 2px solid #3B82F6 !important;
              }
              
              .handsontable .pm-hour {
                border-top: 2px solid #F59E0B !important;
              }
              
              .handsontable .htCommentCell {
                background: #1E1E1E !important;
              }
              
              .handsontable .currentRow {
                background: #374151 !important;
              }
              
              .handsontable .currentCol {
                background: #374151 !important;
              }
            `}</style>
            
            <HotTable
              ref={hotTableRef}
              data={gridData}
              colHeaders={columnHeaders}
              rowHeaders={false}
              nestedHeaders={nestedHeaders.length > 0 ? nestedHeaders : undefined}
              width="100%"
              height={Math.min(600, (visibleMetrics.length + 2) * 30 + 100)}
              colWidths={(template.hours || []).map((_, index) => getColumnWidth(index))}
              readOnly={!isEditable}
              stretchH="none"
              manualRowResize={false}
              manualColumnResize={true}
              manualRowMove={false}
              manualColumnMove={false}
              contextMenu={false}
              comments={false}
              customBorders={true}
              fillHandle={false}
              cells={(row, col) => ({
                readOnly: col === 0 || !isEditable, // First column always read-only
                renderer: getCellRenderer,
                className: getCellClassName(row, col)
              })}
              afterChange={(changes) => {
                if (changes && onCellValueChange) {
                  changes.forEach(([row, col, oldValue, newValue]) => {
                    onCellValueChange(row, col, oldValue, newValue);
                  });
                }
              }}
              licenseKey="non-commercial-and-evaluation" // For demo purposes
            />
          </div>
          
          {/* Grid Legend */}
          <div className="mt-4 flex items-center justify-between text-xs text-gray-400">
            <div className="flex items-center gap-4">
              <div className="flex items-center gap-1">
                <div className="w-3 h-3 bg-blue-600 rounded"></div>
                <span>AM Hours (00-11)</span>
              </div>
              <div className="flex items-center gap-1">
                <div className="w-3 h-3 bg-orange-600 rounded"></div>
                <span>PM Hours (12-23)</span>
              </div>
              <div className="flex items-center gap-1">
                <span className="text-red-400">*</span>
                <span>Required Field</span>
              </div>
            </div>
            <div>
              {gridData.length} rows × {columnHeaders.length} columns
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}