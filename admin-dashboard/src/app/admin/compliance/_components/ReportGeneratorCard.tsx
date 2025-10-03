'use client';

import { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { 
  FileSpreadsheet, 
  Download, 
  Calendar, 
  CheckCircle, 
  AlertCircle, 
  Clock,
  FileText,
  Smartphone,
  Zap
} from 'lucide-react';
import { generateExcelReport } from '../actions/generateExcelReport';
import { ActiveJob } from '@/lib/compliance-utils';

interface ReportGeneratorCardProps {
  jobId?: string | null;
  selectedJob?: ActiveJob | null;
}

export function ReportGeneratorCard({ jobId, selectedJob }: ReportGeneratorCardProps) {
  const [generating, setGenerating] = useState(false);
  const [lastReport, setLastReport] = useState<{
    fileName: string;
    url: string;
    generatedAt: Date;
    bytes: number;
  } | null>(null);
  const [dateRange, setDateRange] = useState({
    startDate: new Date().toISOString().split('T')[0],
    endDate: new Date().toISOString().split('T')[0],
  });
  const [error, setError] = useState<string | null>(null);
  const [exportType, setExportType] = useState<'flutter' | 'excel'>('excel');

  const handleGenerateReport = async () => {
    if (!jobId) return;
    
    try {
      setGenerating(true);
      setError(null);
      
      const [projectId, logId] = jobId.split('-');
      const startDate = new Date(dateRange.startDate);
      const endDate = new Date(dateRange.endDate);
      
      const result = await generateExcelReport(projectId, logId, startDate, endDate);
      
      setLastReport({
        fileName: result.fileName,
        url: result.url,
        generatedAt: new Date(),
        bytes: result.bytes,
      });
      
      // Automatically download the file
      const link = document.createElement('a');
      link.href = result.url;
      link.download = result.fileName;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
      
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to generate report');
    } finally {
      setGenerating(false);
    }
  };

  const formatFileSize = (bytes: number) => {
    const kb = bytes / 1024;
    const mb = kb / 1024;
    
    if (mb >= 1) {
      return `${mb.toFixed(1)} MB`;
    } else {
      return `${kb.toFixed(0)} KB`;
    }
  };

  const getDaysDifference = () => {
    const start = new Date(dateRange.startDate);
    const end = new Date(dateRange.endDate);
    const diffTime = Math.abs(end.getTime() - start.getTime());
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24)) + 1;
    return diffDays;
  };

  const isValidDateRange = () => {
    const start = new Date(dateRange.startDate);
    const end = new Date(dateRange.endDate);
    const today = new Date();
    today.setHours(23, 59, 59, 999);
    
    return start <= end && end <= today;
  };

  return (
    <Card className="col-span-1">
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <FileSpreadsheet className="h-5 w-5" />
          Report Generator
          {lastReport && (
            <Badge variant="outline" className="text-xs">
              <CheckCircle className="h-3 w-3 mr-1" />
              Ready
            </Badge>
          )}
        </CardTitle>
      </CardHeader>
      <CardContent>
        {!jobId && (
          <div className="text-center py-8 text-muted-foreground">
            Select a job to generate reports
          </div>
        )}
        
        {jobId && (
          <div className="space-y-4">
            {/* Template Configuration Display */}
            {selectedJob?.templateConfig && (
              <div className="p-3 bg-muted/30 rounded-lg border">
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center gap-2">
                    {selectedJob.templateConfig.hasExcelTemplate ? (
                      <FileText className="h-4 w-4 text-green-600" />
                    ) : (
                      <Smartphone className="h-4 w-4 text-blue-600" />
                    )}
                    <span className="text-sm font-medium">
                      {selectedJob.templateConfig.hasExcelTemplate ? 'Excel Template' : 'Flutter Forms'}
                    </span>
                    {selectedJob.templateConfig.autoExportEnabled && (
                      <Zap className="h-3 w-3 text-amber-500" title="Auto-export enabled" />
                    )}
                  </div>
                </div>
                {selectedJob.templateConfig.templateName && (
                  <div className="text-xs text-muted-foreground">
                    {selectedJob.templateConfig.templateName}
                  </div>
                )}
              </div>
            )}

            {/* Export Type Selection */}
            <div className="space-y-2">
              <Label className="text-xs">Export Format</Label>
              <div className="grid grid-cols-2 gap-2">
                <Button
                  variant={exportType === 'flutter' ? 'default' : 'outline'}
                  size="sm"
                  onClick={() => setExportType('flutter')}
                  className="h-8"
                >
                  <Smartphone className="h-3 w-3 mr-2" />
                  Standard
                </Button>
                <Button
                  variant={exportType === 'excel' ? 'default' : 'outline'}
                  size="sm"
                  onClick={() => setExportType('excel')}
                  className="h-8"
                  disabled={!selectedJob?.templateConfig?.hasExcelTemplate}
                >
                  <FileText className="h-3 w-3 mr-2" />
                  Excel Template
                </Button>
              </div>
              {exportType === 'excel' && !selectedJob?.templateConfig?.hasExcelTemplate && (
                <div className="text-xs text-muted-foreground">
                  No Excel template configured for this job
                </div>
              )}
            </div>

            {/* Date Range Selection */}
            <div className="space-y-3">
              <div className="grid grid-cols-2 gap-2">
                <div>
                  <Label htmlFor="startDate" className="text-xs">Start Date</Label>
                  <Input
                    id="startDate"
                    type="date"
                    value={dateRange.startDate}
                    onChange={(e) => setDateRange(prev => ({ ...prev, startDate: e.target.value }))}
                    className="text-sm"
                  />
                </div>
                <div>
                  <Label htmlFor="endDate" className="text-xs">End Date</Label>
                  <Input
                    id="endDate"
                    type="date"
                    value={dateRange.endDate}
                    onChange={(e) => setDateRange(prev => ({ ...prev, endDate: e.target.value }))}
                    className="text-sm"
                  />
                </div>
              </div>
              
              {isValidDateRange() ? (
                <div className="text-xs text-green-600 flex items-center gap-1">
                  <CheckCircle className="h-3 w-3" />
                  {getDaysDifference()} day{getDaysDifference() !== 1 ? 's' : ''} selected
                </div>
              ) : (
                <div className="text-xs text-destructive flex items-center gap-1">
                  <AlertCircle className="h-3 w-3" />
                  Invalid date range
                </div>
              )}
            </div>
            
            {/* Generate Button */}
            <Button
              onClick={handleGenerateReport}
              disabled={generating || !isValidDateRange() || (exportType === 'excel' && !selectedJob?.templateConfig?.hasExcelTemplate)}
              className="w-full"
            >
              {generating ? (
                <>
                  <Clock className="h-4 w-4 mr-2 animate-spin" />
                  Generating {exportType === 'excel' ? 'Excel' : 'Standard'} Report...
                </>
              ) : (
                <>
                  {exportType === 'excel' ? (
                    <FileText className="h-4 w-4 mr-2" />
                  ) : (
                    <FileSpreadsheet className="h-4 w-4 mr-2" />
                  )}
                  Generate {exportType === 'excel' ? 'Excel Template' : 'Standard'} Report
                </>
              )}
            </Button>
            
            {/* Error Display */}
            {error && (
              <div className="p-3 bg-destructive/10 border border-destructive/20 rounded-lg">
                <div className="flex items-center gap-2 text-destructive">
                  <AlertCircle className="h-4 w-4" />
                  <span className="text-sm font-medium">Generation Failed</span>
                </div>
                <div className="text-xs text-destructive/80 mt-1">{error}</div>
              </div>
            )}
            
            {/* Last Generated Report */}
            {lastReport && (
              <div className="p-3 bg-green-50 border border-green-200 rounded-lg">
                <div className="flex items-center justify-between mb-2">
                  <div className="flex items-center gap-2">
                    <CheckCircle className="h-4 w-4 text-green-600" />
                    <span className="text-sm font-medium text-green-800">Report Generated</span>
                  </div>
                  <Badge variant="outline" className="text-xs">
                    {formatFileSize(lastReport.bytes)}
                  </Badge>
                </div>
                
                <div className="text-xs text-green-700 space-y-1">
                  <div className="truncate">{lastReport.fileName}</div>
                  <div>Generated: {lastReport.generatedAt.toLocaleString()}</div>
                </div>
                
                <Button
                  size="sm"
                  variant="outline"
                  className="w-full mt-2"
                  onClick={() => {
                    const link = document.createElement('a');
                    link.href = lastReport.url;
                    link.download = lastReport.fileName;
                    document.body.appendChild(link);
                    link.click();
                    document.body.removeChild(link);
                  }}
                >
                  <Download className="h-3 w-3 mr-1" />
                  Download Again
                </Button>
              </div>
            )}
            
            {/* Report Info */}
            <div className="text-xs text-muted-foreground space-y-1 border-t pt-3">
              {exportType === 'excel' ? (
                <>
                  <div>• Excel format using job template</div>
                  <div>• Compliance-grade export</div>
                  <div>• Template validation included</div>
                  <div>• Audit trail embedded</div>
                </>
              ) : (
                <>
                  <div>• Standard Excel format</div>
                  <div>• Includes hourly data and summary</div>
                  <div>• Auto-calculated emissions</div>
                  <div>• Deviations included if any</div>
                </>
              )}
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  );
}