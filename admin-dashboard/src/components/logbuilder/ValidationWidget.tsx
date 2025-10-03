'use client';

import React, { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Field, ValidationResult, ValidationIssue } from '@/lib/logs/templates/types';
import { Upload, AlertTriangle, CheckCircle, Wrench, Download, X } from 'lucide-react';

interface ValidationWidgetProps {
  template: {
    key: string;
    title: string;
    fields: Field[];
  };
  onAutoFix?: (fixedFields: Field[]) => void;
  className?: string;
}

export function ValidationWidget({ template, onAutoFix, className }: ValidationWidgetProps) {
  const [validationResult, setValidationResult] = useState<ValidationResult | null>(null);
  const [validating, setValidating] = useState(false);
  const [uploading, setUploading] = useState(false);

  const handleFileUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    try {
      setValidating(true);
      const formData = new FormData();
      formData.append('file', file);
      formData.append('templateFields', JSON.stringify(template.fields));

      const response = await fetch('/api/export/validate', {
        method: 'POST',
        body: formData
      });

      if (response.ok) {
        const result: ValidationResult = await response.json();
        setValidationResult(result);
      } else {
        const error = await response.json();
        console.error('Validation error:', error);
      }
    } catch (error) {
      console.error('Upload error:', error);
    } finally {
      setValidating(false);
    }
  };

  const handleAutoFix = () => {
    if (!validationResult?.suggestedFields || !onAutoFix) return;
    onAutoFix(validationResult.suggestedFields);
    setValidationResult(null);
  };

  const handleDownloadSample = async () => {
    try {
      setUploading(true);
      const response = await fetch('/api/export/sample', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          templateFields: template.fields,
          templateKey: template.key
        })
      });

      if (response.ok) {
        const blob = await response.blob();
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `${template.key}_sample.xlsx`;
        document.body.appendChild(a);
        a.click();
        window.URL.revokeObjectURL(url);
        document.body.removeChild(a);
      } else {
        console.error('Sample generation failed');
      }
    } catch (error) {
      console.error('Download error:', error);
    } finally {
      setUploading(false);
    }
  };

  const getSeverityColor = (issue: ValidationIssue) => {
    switch (issue.type) {
      case 'missing':
        return 'destructive';
      case 'extra':
        return 'secondary';
      case 'orderMismatch':
      case 'renamed':
        return 'outline';
      default:
        return 'secondary';
    }
  };

  const getSeverityIcon = (issue: ValidationIssue) => {
    switch (issue.type) {
      case 'missing':
        return <X className="w-4 h-4" />;
      case 'extra':
        return <AlertTriangle className="w-4 h-4" />;
      default:
        return <AlertTriangle className="w-4 h-4" />;
    }
  };

  return (
    <Card className={className}>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <Wrench className="w-5 h-5" />
          Template Validation
        </CardTitle>
        <CardDescription>
          Upload a blank Excel file to validate against the current template structure
        </CardDescription>
      </CardHeader>
      <CardContent className="space-y-4">
        <div className="flex gap-2">
          <Button variant="outline" asChild className="flex-1">
            <label htmlFor="validation-upload" className="cursor-pointer">
              <Upload className="w-4 h-4 mr-2" />
              {validating ? 'Validating...' : 'Upload Excel'}
              <input
                id="validation-upload"
                type="file"
                accept=".xlsx,.xls"
                className="hidden"
                onChange={handleFileUpload}
                disabled={validating}
              />
            </label>
          </Button>
          <Button variant="outline" onClick={handleDownloadSample} disabled={uploading}>
            <Download className="w-4 h-4 mr-2" />
            {uploading ? 'Generating...' : 'Sample'}
          </Button>
        </div>

        {validationResult && (
          <div className="space-y-4">
            <Alert variant={validationResult.valid ? 'default' : 'destructive'}>
              <div className="flex items-center gap-2">
                {validationResult.valid ? (
                  <CheckCircle className="w-4 h-4 text-green-600" />
                ) : (
                  <AlertTriangle className="w-4 h-4" />
                )}
                <AlertDescription>
                  {validationResult.valid
                    ? 'Template structure is valid!'
                    : `Found ${validationResult.issues.length} validation issues`}
                </AlertDescription>
              </div>
            </Alert>

            {validationResult.issues.length > 0 && (
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <h4 className="font-medium">Validation Issues</h4>
                  {validationResult.autoFixAvailable && onAutoFix && (
                    <Button variant="outline" size="sm" onClick={handleAutoFix}>
                      <Wrench className="w-4 h-4 mr-2" />
                      Auto-Fix
                    </Button>
                  )}
                </div>
                
                <div className="space-y-2">
                  {validationResult.issues.map((issue, index) => (
                    <div key={index} className="flex items-start gap-3 p-3 bg-gray-50 rounded-lg">
                      <Badge variant={getSeverityColor(issue)} className="mt-0.5">
                        {getSeverityIcon(issue)}
                        {issue.type}
                      </Badge>
                      <div className="flex-1 text-sm">
                        <p className="font-medium text-gray-900">
                          Field: {issue.field}
                        </p>
                        {issue.expected && (
                          <p className="text-gray-600">
                            Expected: {issue.expected}
                          </p>
                        )}
                        {issue.actual && (
                          <p className="text-gray-600">
                            Found: {issue.actual}
                          </p>
                        )}
                        {issue.suggestion && (
                          <p className="text-blue-600 mt-1">
                            💡 {issue.suggestion}
                          </p>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {validationResult.suggestedFields && validationResult.suggestedFields.length > 0 && (
              <div>
                <h4 className="font-medium mb-2">Suggested Auto-Fix Changes</h4>
                <div className="bg-blue-50 p-3 rounded-lg text-sm">
                  <p className="text-blue-800 mb-2">The following changes will be applied:</p>
                  <ul className="list-disc list-inside text-blue-700 space-y-1">
                    {validationResult.suggestedFields.map((field, index) => (
                      <li key={index}>
                        Update "{field.label}" (Cell: {field.excelKey})
                      </li>
                    ))}
                  </ul>
                </div>
              </div>
            )}
          </div>
        )}
      </CardContent>
    </Card>
  );
}