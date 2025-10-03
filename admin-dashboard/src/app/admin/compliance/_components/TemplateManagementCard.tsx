'use client';

import { useEffect, useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { 
  RefreshCw, 
  FileText, 
  Smartphone, 
  CheckCircle, 
  AlertCircle, 
  Settings,
  Download,
  Upload,
  Eye,
  Zap
} from 'lucide-react';
import { formatDistanceToNow } from 'date-fns';

interface ExcelTemplate {
  id: string;
  displayName: string;
  fileName: string;
  logType: string;
  status: 'active' | 'inactive' | 'error';
  lastValidated?: Date;
  requiredFields: number;
  compatibleJobs: number;
  autoExportJobs: number;
  filePath: string;
  fileSize: number;
  checksum: string;
}

// Mock data for demonstration
const mockTemplates: ExcelTemplate[] = [
  {
    id: 'texas_methane_h2s_benzene',
    displayName: 'Texas Methane H2S & Benzene',
    fileName: 'Texas - BLANK Thermal Log - 10-60MMBTU (METHANE) 8.14.17 H2S & Benzene.xlsx',
    logType: 'thermal',
    status: 'active',
    lastValidated: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000),
    requiredFields: 12,
    compatibleJobs: 2,
    autoExportJobs: 1,
    filePath: 'reports/templates/Texas - BLANK Thermal Log - 10-60MMBTU (METHANE) 8.14.17 H2S & Benzene.xlsx',
    fileSize: 45632,
    checksum: 'a1b2c3d4e5f6...',
  },
  {
    id: 'texas_pentane_h2s_benzene',
    displayName: 'Texas Pentane H2S & Benzene',
    fileName: 'Texas - BLANK Thermal Log - 10-60MMBTU (PENTANE) 8.14.17 H2S & Benzene.xlsx',
    logType: 'thermal',
    status: 'active',
    lastValidated: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000),
    requiredFields: 14,
    compatibleJobs: 1,
    autoExportJobs: 0,
    filePath: 'reports/templates/Texas - BLANK Thermal Log - 10-60MMBTU (PENTANE) 8.14.17 H2S & Benzene.xlsx',
    fileSize: 47821,
    checksum: 'f6e5d4c3b2a1...',
  },
  {
    id: 'texas_methane_standard',
    displayName: 'Texas Methane Standard',
    fileName: 'Texas - BLANK Thermal Log - 10-60MMBTU (METHANE) 8.14.17.xlsx',
    logType: 'thermal',
    status: 'inactive',
    lastValidated: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
    requiredFields: 8,
    compatibleJobs: 0,
    autoExportJobs: 0,
    filePath: 'reports/templates/Texas - BLANK Thermal Log - 10-60MMBTU (METHANE) 8.14.17.xlsx',
    fileSize: 38291,
    checksum: '123abc456def...',
  },
];

interface TemplateManagementCardProps {
  onStatusChange?: (status: 'red' | 'amber' | 'green', delta: number) => void;
}

export function TemplateManagementCard({ onStatusChange }: TemplateManagementCardProps) {
  const [templates, setTemplates] = useState<ExcelTemplate[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const loadTemplates = async () => {
    try {
      setLoading(true);
      setError(null);
      
      // Simulate loading delay
      await new Promise(resolve => setTimeout(resolve, 500));
      
      setTemplates(mockTemplates);
      
      // Calculate status counts for parent dashboard
      if (onStatusChange) {
        mockTemplates.forEach(template => {
          const daysSinceValidation = template.lastValidated 
            ? (Date.now() - template.lastValidated.getTime()) / (1000 * 60 * 60 * 24)
            : 30;
          
          let status: 'red' | 'amber' | 'green' = 'green';
          
          if (template.status === 'error' || daysSinceValidation > 30) {
            status = 'red';
          } else if (template.status === 'inactive' || daysSinceValidation > 7) {
            status = 'amber';
          }
          
          onStatusChange(status, 1);
        });
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load templates');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadTemplates();
  }, []);

  const getStatusBadge = (template: ExcelTemplate) => {
    const daysSinceValidation = template.lastValidated 
      ? (Date.now() - template.lastValidated.getTime()) / (1000 * 60 * 60 * 24)
      : 30;

    if (template.status === 'error') {
      return <Badge variant="destructive">Error</Badge>;
    } else if (template.status === 'inactive') {
      return <Badge variant="outline" className="border-gray-400">Inactive</Badge>;
    } else if (daysSinceValidation > 30) {
      return <Badge variant="destructive">Validation Expired</Badge>;
    } else if (daysSinceValidation > 7) {
      return <Badge className="bg-amber-500">Needs Validation</Badge>;
    } else {
      return <Badge variant="outline" className="border-green-500 text-green-600">Active</Badge>;
    }
  };

  const getStatusIcon = (template: ExcelTemplate) => {
    if (template.status === 'error') {
      return <AlertCircle className="h-4 w-4 text-red-500" />;
    } else if (template.status === 'active') {
      return <CheckCircle className="h-4 w-4 text-green-500" />;
    } else {
      return <AlertCircle className="h-4 w-4 text-gray-400" />;
    }
  };

  const formatFileSize = (bytes: number) => {
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  };

  const handleValidateTemplate = (templateId: string) => {
    console.log('Validating template:', templateId);
    // This would trigger validation of the Excel template
  };

  const handlePreviewTemplate = (templateId: string) => {
    console.log('Previewing template:', templateId);
    // This would show a preview of the Excel template
  };

  const handleDownloadTemplate = (templateId: string) => {
    console.log('Downloading template:', templateId);
    // This would download the Excel template file
  };

  return (
    <Card className="col-span-1 lg:col-span-2">
      <CardHeader className="flex flex-row items-center justify-between">
        <CardTitle className="flex items-center gap-2">
          <FileText className="h-5 w-5" />
          Excel Templates
          <Badge variant="secondary">{templates.length}</Badge>
        </CardTitle>
        <div className="flex items-center gap-2">
          <Button
            variant="outline"
            size="sm"
            onClick={() => console.log('Upload new template')}
          >
            <Upload className="h-4 w-4 mr-2" />
            Upload
          </Button>
          <Button
            variant="ghost"
            size="icon"
            onClick={loadTemplates}
            disabled={loading}
          >
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          </Button>
        </div>
      </CardHeader>
      <CardContent>
        {error && (
          <div className="flex items-center gap-2 text-destructive mb-4">
            <AlertCircle className="h-4 w-4" />
            <span className="text-sm">{error}</span>
          </div>
        )}
        
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Template</TableHead>
              <TableHead>Type</TableHead>
              <TableHead>Status</TableHead>
              <TableHead>Usage</TableHead>
              <TableHead>Last Validated</TableHead>
              <TableHead>Size</TableHead>
              <TableHead>Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {templates.map(template => (
              <TableRow key={template.id}>
                <TableCell>
                  <div className="flex items-start gap-3">
                    {getStatusIcon(template)}
                    <div>
                      <div className="font-medium text-sm">{template.displayName}</div>
                      <div className="text-xs text-muted-foreground max-w-[200px] truncate" title={template.fileName}>
                        {template.fileName}
                      </div>
                      <div className="text-xs text-muted-foreground">
                        {template.requiredFields} required fields
                      </div>
                    </div>
                  </div>
                </TableCell>
                <TableCell>
                  <div className="flex items-center gap-1.5">
                    <Smartphone className="h-3.5 w-3.5 text-blue-600" />
                    <span className="text-sm">{template.logType}</span>
                  </div>
                </TableCell>
                <TableCell>{getStatusBadge(template)}</TableCell>
                <TableCell>
                  <div className="space-y-1">
                    <div className="text-sm">
                      {template.compatibleJobs} jobs using
                    </div>
                    {template.autoExportJobs > 0 && (
                      <div className="flex items-center gap-1 text-xs text-amber-600">
                        <Zap className="h-3 w-3" />
                        {template.autoExportJobs} auto-export
                      </div>
                    )}
                  </div>
                </TableCell>
                <TableCell>
                  {template.lastValidated ? (
                    <span className="text-sm">
                      {formatDistanceToNow(template.lastValidated, { addSuffix: true })}
                    </span>
                  ) : (
                    <span className="text-sm text-muted-foreground">Never</span>
                  )}
                </TableCell>
                <TableCell>
                  <span className="text-sm text-muted-foreground">
                    {formatFileSize(template.fileSize)}
                  </span>
                </TableCell>
                <TableCell>
                  <div className="flex items-center gap-1">
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => handlePreviewTemplate(template.id)}
                      title="Preview template"
                    >
                      <Eye className="h-3 w-3" />
                    </Button>
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => handleValidateTemplate(template.id)}
                      title="Validate template"
                    >
                      <CheckCircle className="h-3 w-3" />
                    </Button>
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => handleDownloadTemplate(template.id)}
                      title="Download template"
                    >
                      <Download className="h-3 w-3" />
                    </Button>
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => console.log('Configure template', template.id)}
                      title="Configure template"
                    >
                      <Settings className="h-3 w-3" />
                    </Button>
                  </div>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
        
        {templates.length === 0 && !loading && (
          <div className="text-center py-8 text-muted-foreground">
            <FileText className="h-12 w-12 mx-auto mb-4 text-muted-foreground/50" />
            <div className="text-lg font-medium mb-2">No Excel templates configured</div>
            <div className="text-sm mb-4">Upload Excel templates to enable compliance-grade exports</div>
            <Button onClick={() => console.log('Upload first template')}>
              <Upload className="h-4 w-4 mr-2" />
              Upload Template
            </Button>
          </div>
        )}
      </CardContent>
    </Card>
  );
}