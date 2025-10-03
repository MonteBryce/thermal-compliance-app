'use client';

import { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Progress } from '@/components/ui/progress';
import { 
  Upload, 
  CheckCircle, 
  AlertCircle, 
  XCircle,
  FileSpreadsheet,
  RefreshCw,
  Eye,
  Download,
  AlertTriangle
} from 'lucide-react';
import { LogTemplate, StructureCheckResult, StructureMismatch } from '@/lib/types/template';
import { TemplateService } from '@/lib/services/template.service';

interface StructureValidationPanelProps {
  template: LogTemplate;
  onValidationComplete?: (result: StructureCheckResult) => void;
}

export function StructureValidationPanel({ template, onValidationComplete }: StructureValidationPanelProps) {
  const [isValidating, setIsValidating] = useState(false);
  const [structureCheck, setStructureCheck] = useState<StructureCheckResult | null>(null);
  const [uploadedFileName, setUploadedFileName] = useState<string | null>(null);
  const [validationProgress, setValidationProgress] = useState(0);

  const templateService = TemplateService.getInstance();

  const handleFileUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    setUploadedFileName(file.name);
    setIsValidating(true);
    setValidationProgress(0);

    try {
      // Simulate progress for better UX
      const progressInterval = setInterval(() => {
        setValidationProgress(prev => Math.min(prev + 20, 90));
      }, 200);

      const result = await templateService.validateAgainstExcel(template, file);
      
      clearInterval(progressInterval);
      setValidationProgress(100);
      
      setTimeout(() => {
        setStructureCheck(result);
        onValidationComplete?.(result);
        setIsValidating(false);
        setValidationProgress(0);
      }, 500);

    } catch (error) {
      console.error('Validation error:', error);
      setIsValidating(false);
      setValidationProgress(0);
      
      // Show error state
      const errorResult: StructureCheckResult = {
        passed: false,
        mismatches: [{
          type: 'missing_metric',
          actual: 'File parsing failed',
          expected: 'Valid Excel file',
          suggestion: 'Check file format and try again',
          severity: 'error'
        }],
        warnings: [`Failed to parse Excel file: ${error}`]
      };
      setStructureCheck(errorResult);
    }
  };

  const getMismatchIcon = (mismatch: StructureMismatch) => {
    switch (mismatch.severity) {
      case 'error':
        return <XCircle className="h-4 w-4 text-red-500" />;
      case 'warning':
        return <AlertTriangle className="h-4 w-4 text-yellow-500" />;
      default:
        return <AlertCircle className="h-4 w-4 text-blue-500" />;
    }
  };

  const getMismatchColor = (severity: 'error' | 'warning') => {
    switch (severity) {
      case 'error':
        return 'border-red-600 bg-red-900/20';
      case 'warning':
        return 'border-yellow-600 bg-yellow-900/20';
      default:
        return 'border-blue-600 bg-blue-900/20';
    }
  };

  const getMismatchBadgeColor = (severity: 'error' | 'warning') => {
    switch (severity) {
      case 'error':
        return 'bg-red-600 text-white';
      case 'warning':
        return 'bg-yellow-600 text-white';
      default:
        return 'bg-blue-600 text-white';
    }
  };

  const getOverallStatus = () => {
    if (!structureCheck) return null;
    
    const errorCount = structureCheck.mismatches.filter(m => m.severity === 'error').length;
    const warningCount = structureCheck.mismatches.filter(m => m.severity === 'warning').length;
    
    if (errorCount > 0) {
      return {
        icon: <XCircle className="h-5 w-5 text-red-500" />,
        text: `${errorCount} error(s), ${warningCount} warning(s)`,
        color: 'text-red-400',
        bgColor: 'bg-red-600'
      };
    } else if (warningCount > 0) {
      return {
        icon: <AlertTriangle className="h-5 w-5 text-yellow-500" />,
        text: `${warningCount} warning(s) found`,
        color: 'text-yellow-400',
        bgColor: 'bg-yellow-600'
      };
    } else {
      return {
        icon: <CheckCircle className="h-5 w-5 text-green-500" />,
        text: 'Perfect match!',
        color: 'text-green-400',
        bgColor: 'bg-green-600'
      };
    }
  };

  const exportValidationReport = () => {
    if (!structureCheck) return;

    const report = {
      template: {
        logType: template.logType,
        displayName: template.displayName,
        version: template.version
      },
      validation: {
        timestamp: new Date().toISOString(),
        fileName: uploadedFileName,
        passed: structureCheck.passed,
        summary: {
          totalMismatches: structureCheck.mismatches.length,
          errors: structureCheck.mismatches.filter(m => m.severity === 'error').length,
          warnings: structureCheck.mismatches.filter(m => m.severity === 'warning').length
        },
        mismatches: structureCheck.mismatches,
        warnings: structureCheck.warnings
      }
    };

    const dataStr = JSON.stringify(report, null, 2);
    const dataBlob = new Blob([dataStr], { type: 'application/json' });
    const url = URL.createObjectURL(dataBlob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `validation_report_${template.logType}_${new Date().toISOString().split('T')[0]}.json`;
    link.click();
    URL.revokeObjectURL(url);
  };

  const status = getOverallStatus();

  return (
    <Card className="bg-[#1E1E1E] border-gray-800">
      <CardHeader>
        <div className="flex items-center justify-between">
          <div>
            <CardTitle className="text-white flex items-center gap-2">
              <FileSpreadsheet className="h-5 w-5 text-orange-500" />
              Excel Structure Validation
            </CardTitle>
            <p className="text-gray-400 text-sm mt-1">
              Upload an Excel file to validate against this template
            </p>
          </div>
          {structureCheck && (
            <div className="flex items-center gap-2">
              <Button
                onClick={exportValidationReport}
                variant="outline"
                size="sm"
                className="border-gray-600 text-gray-300 hover:bg-gray-800"
              >
                <Download className="h-4 w-4 mr-2" />
                Export Report
              </Button>
            </div>
          )}
        </div>
      </CardHeader>

      <CardContent className="space-y-4">
        {/* File Upload */}
        <div>
          <input
            type="file"
            accept=".xlsx,.xls"
            onChange={handleFileUpload}
            disabled={isValidating}
            className="hidden"
            id="excel-validation-upload"
          />
          <label htmlFor="excel-validation-upload" className="cursor-pointer">
            <Button
              variant="outline"
              size="lg"
              className="w-full border-gray-600 text-gray-300 hover:bg-gray-800"
              disabled={isValidating}
              asChild
            >
              <div className="flex items-center justify-center gap-2 py-6">
                {isValidating ? (
                  <RefreshCw className="h-5 w-5 animate-spin" />
                ) : (
                  <Upload className="h-5 w-5" />
                )}
                <span>
                  {isValidating 
                    ? 'Validating...' 
                    : uploadedFileName 
                      ? `Replace ${uploadedFileName}` 
                      : 'Upload Excel Template'
                  }
                </span>
              </div>
            </Button>
          </label>
        </div>

        {/* Progress Bar */}
        {isValidating && (
          <div className="space-y-2">
            <div className="flex justify-between text-sm text-gray-400">
              <span>Analyzing structure...</span>
              <span>{validationProgress}%</span>
            </div>
            <Progress value={validationProgress} className="h-2" />
          </div>
        )}

        {/* Validation Results */}
        {structureCheck && !isValidating && (
          <div className="space-y-4">
            {/* Overall Status */}
            <Alert className={`border ${status?.bgColor.replace('bg-', 'border-').replace('-600', '-600')}`}>
              <div className="flex items-center gap-3">
                {status?.icon}
                <div className="flex-1">
                  <AlertDescription className={`${status?.color} font-medium`}>
                    {uploadedFileName && (
                      <span className="text-gray-300">
                        {uploadedFileName}: 
                      </span>
                    )}
                    {' '}{status?.text}
                  </AlertDescription>
                </div>
                <Badge className={`${status?.bgColor} text-white border-0`}>
                  {structureCheck.passed ? 'PASSED' : 'FAILED'}
                </Badge>
              </div>
            </Alert>

            {/* Summary Stats */}
            <div className="grid grid-cols-3 gap-4">
              <div className="bg-gray-800 rounded-lg p-3 text-center">
                <div className="text-2xl font-bold text-white">
                  {structureCheck.mismatches.length}
                </div>
                <div className="text-xs text-gray-400">Total Issues</div>
              </div>
              <div className="bg-gray-800 rounded-lg p-3 text-center">
                <div className="text-2xl font-bold text-red-400">
                  {structureCheck.mismatches.filter(m => m.severity === 'error').length}
                </div>
                <div className="text-xs text-gray-400">Errors</div>
              </div>
              <div className="bg-gray-800 rounded-lg p-3 text-center">
                <div className="text-2xl font-bold text-yellow-400">
                  {structureCheck.mismatches.filter(m => m.severity === 'warning').length}
                </div>
                <div className="text-xs text-gray-400">Warnings</div>
              </div>
            </div>

            {/* Detailed Issues */}
            {structureCheck.mismatches.length > 0 && (
              <div className="space-y-3">
                <h4 className="text-white font-medium">Detailed Issues</h4>
                {structureCheck.mismatches.map((mismatch, index) => (
                  <div 
                    key={index}
                    className={`p-3 rounded border ${getMismatchColor(mismatch.severity)}`}
                  >
                    <div className="flex items-start gap-3">
                      {getMismatchIcon(mismatch)}
                      <div className="flex-1 space-y-1">
                        <div className="flex items-center gap-2">
                          <Badge className={`text-xs ${getMismatchBadgeColor(mismatch.severity)} border-0`}>
                            {mismatch.severity.toUpperCase()}
                          </Badge>
                          <span className="text-white text-sm font-medium">
                            {mismatch.type.replace(/_/g, ' ').toUpperCase()}
                          </span>
                        </div>
                        
                        {mismatch.expected && (
                          <p className="text-gray-300 text-sm">
                            <strong>Expected:</strong> {mismatch.expected}
                          </p>
                        )}
                        
                        {mismatch.actual && (
                          <p className="text-gray-300 text-sm">
                            <strong>Found:</strong> {mismatch.actual}
                          </p>
                        )}
                        
                        {mismatch.suggestion && (
                          <p className="text-blue-300 text-sm">
                            💡 <strong>Suggestion:</strong> {mismatch.suggestion}
                          </p>
                        )}
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            )}

            {/* Warnings */}
            {structureCheck.warnings.length > 0 && (
              <div className="space-y-2">
                <h4 className="text-yellow-400 font-medium">Additional Warnings</h4>
                <div className="space-y-1">
                  {structureCheck.warnings.map((warning, index) => (
                    <div key={index} className="flex items-center gap-2 text-sm text-gray-300">
                      <AlertTriangle className="h-3 w-3 text-yellow-500 flex-shrink-0" />
                      <span>{warning}</span>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Structure Comparison */}
            {(structureCheck.templateHeaders || structureCheck.excelHeaders) && (
              <div className="grid grid-cols-2 gap-4">
                {structureCheck.templateHeaders && (
                  <div>
                    <h4 className="text-white font-medium mb-2">Template Metrics</h4>
                    <div className="bg-gray-800 rounded p-3 max-h-40 overflow-y-auto">
                      {structureCheck.templateHeaders.map((header, index) => (
                        <div key={index} className="text-sm text-gray-300 py-1">
                          {index + 1}. {header}
                        </div>
                      ))}
                    </div>
                  </div>
                )}
                
                {structureCheck.excelHeaders && (
                  <div>
                    <h4 className="text-white font-medium mb-2">Excel Metrics</h4>
                    <div className="bg-gray-800 rounded p-3 max-h-40 overflow-y-auto">
                      {structureCheck.excelHeaders.map((header, index) => (
                        <div key={index} className="text-sm text-gray-300 py-1">
                          {index + 1}. {header}
                        </div>
                      ))}
                    </div>
                  </div>
                )}
              </div>
            )}
          </div>
        )}

        {/* Help Text */}
        {!structureCheck && !isValidating && (
          <div className="text-center py-6 text-gray-500">
            <FileSpreadsheet className="h-12 w-12 mx-auto mb-4 text-gray-600" />
            <p className="text-sm">
              Upload an Excel template to validate structure compatibility
            </p>
            <p className="text-xs mt-2">
              Supports .xlsx and .xls formats
            </p>
          </div>
        )}
      </CardContent>
    </Card>
  );
}