'use client';

import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Label } from '@/components/ui/label';
import { Input } from '@/components/ui/input';
import { 
  Download, 
  FileText, 
  Calendar, 
  Clock, 
  CheckCircle, 
  AlertTriangle,
  RefreshCw,
  Filter,
  Mail,
  Settings,
  Database,
  FileSpreadsheet,
  History
} from 'lucide-react';
import { Project } from '@/lib/firestore/projects';
import { formatDistanceToNow, format } from 'date-fns';

interface ExportsTabProps {
  project: Project;
}

// Mock export history data
const mockExportHistory = [
  {
    id: '1',
    filename: 'thermal-log-2024-01-15-to-2024-01-20.xlsx',
    type: 'Excel Report',
    dateRange: {
      from: new Date('2024-01-15'),
      to: new Date('2024-01-20')
    },
    createdAt: new Date(Date.now() - 2 * 60 * 60 * 1000),
    createdBy: 'admin@company.com',
    status: 'completed',
    size: '2.4 MB',
    downloadCount: 3
  },
  {
    id: '2',
    filename: 'thermal-log-2024-01-10-to-2024-01-14.xlsx',
    type: 'Excel Report',
    dateRange: {
      from: new Date('2024-01-10'),
      to: new Date('2024-01-14')
    },
    createdAt: new Date(Date.now() - 24 * 60 * 60 * 1000),
    createdBy: 'supervisor@company.com',
    status: 'completed',
    size: '1.8 MB',
    downloadCount: 5
  },
  {
    id: '3',
    filename: 'compliance-report-2024-01.pdf',
    type: 'Compliance Report',
    dateRange: {
      from: new Date('2024-01-01'),
      to: new Date('2024-01-31')
    },
    createdAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000),
    createdBy: 'compliance@company.com',
    status: 'processing',
    size: 'Processing...',
    downloadCount: 0
  },
  {
    id: '4',
    filename: 'data-backup-2024-01-01.csv',
    type: 'Data Backup',
    dateRange: {
      from: new Date('2024-01-01'),
      to: new Date('2024-01-31')
    },
    createdAt: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000),
    createdBy: 'admin@company.com',
    status: 'failed',
    size: 'Failed',
    downloadCount: 0
  }
];

// Available export templates
const exportTemplates = [
  {
    id: 'excel-standard',
    name: 'Standard Excel Report',
    description: 'Complete thermal log data with calculations',
    format: 'xlsx',
    icon: FileSpreadsheet,
    color: 'text-green-400'
  },
  {
    id: 'compliance-pdf',
    name: 'Compliance Report',
    description: 'Formatted PDF for regulatory submission',
    format: 'pdf',
    icon: FileText,
    color: 'text-red-400'
  },
  {
    id: 'data-csv',
    name: 'Raw Data Export',
    description: 'CSV format for data analysis',
    format: 'csv',
    icon: Database,
    color: 'text-blue-400'
  }
];

export function ExportsTab({ project }: ExportsTabProps) {
  const [selectedTemplate, setSelectedTemplate] = useState('excel-standard');
  const [dateFrom, setDateFrom] = useState('');
  const [dateTo, setDateTo] = useState('');
  const [isExporting, setIsExporting] = useState(false);
  const [exportProgress, setExportProgress] = useState(0);

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'completed':
        return <Badge className="bg-green-600">Completed</Badge>;
      case 'processing':
        return <Badge className="bg-blue-600">Processing</Badge>;
      case 'failed':
        return <Badge variant="destructive">Failed</Badge>;
      default:
        return <Badge variant="outline">Unknown</Badge>;
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'completed':
        return <CheckCircle className="h-4 w-4 text-green-400" />;
      case 'processing':
        return <RefreshCw className="h-4 w-4 text-blue-400 animate-spin" />;
      case 'failed':
        return <AlertTriangle className="h-4 w-4 text-red-400" />;
      default:
        return <Clock className="h-4 w-4 text-gray-400" />;
    }
  };

  const handleExport = async () => {
    setIsExporting(true);
    setExportProgress(0);

    // Simulate export progress
    const progressInterval = setInterval(() => {
      setExportProgress(prev => {
        if (prev >= 100) {
          clearInterval(progressInterval);
          setIsExporting(false);
          return 100;
        }
        return prev + 10;
      });
    }, 300);
  };

  const selectedTemplateInfo = exportTemplates.find(t => t.id === selectedTemplate);

  return (
    <div className="p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-2xl font-bold text-white">Data Exports</h2>
          <p className="text-gray-400">
            Export thermal log data in various formats for analysis and compliance
          </p>
        </div>
        <div className="flex items-center gap-3">
          <Button variant="outline" className="border-gray-600 text-gray-300">
            <Settings className="h-4 w-4 mr-2" />
            Configure
          </Button>
          <Button variant="outline" className="border-gray-600 text-gray-300">
            <Mail className="h-4 w-4 mr-2" />
            Schedule
          </Button>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Export Configuration */}
        <div className="lg:col-span-2 space-y-6">
          {/* Export Templates */}
          <Card className="bg-[#1E1E1E] border-gray-800">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <FileText className="h-5 w-5" />
                Export Templates
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                {exportTemplates.map((template) => {
                  const Icon = template.icon;
                  return (
                    <div
                      key={template.id}
                      className={`p-4 border-2 rounded-lg cursor-pointer transition-all ${
                        selectedTemplate === template.id
                          ? 'border-orange-500 bg-orange-500/10'
                          : 'border-gray-700 hover:border-gray-600'
                      }`}
                      onClick={() => setSelectedTemplate(template.id)}
                    >
                      <div className="flex items-center gap-3 mb-2">
                        <Icon className={`h-5 w-5 ${template.color}`} />
                        <span className="font-medium text-white">{template.name}</span>
                      </div>
                      <p className="text-sm text-gray-400">{template.description}</p>
                      <Badge variant="outline" className="mt-2 text-xs">
                        {template.format.toUpperCase()}
                      </Badge>
                    </div>
                  );
                })}
              </div>
            </CardContent>
          </Card>

          {/* Export Configuration */}
          <Card className="bg-[#1E1E1E] border-gray-800">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Settings className="h-5 w-5" />
                Export Configuration
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <Label htmlFor="date-from">From Date</Label>
                  <Input
                    id="date-from"
                    type="date"
                    value={dateFrom}
                    onChange={(e) => setDateFrom(e.target.value)}
                    className="bg-gray-800 border-gray-600"
                  />
                </div>
                <div>
                  <Label htmlFor="date-to">To Date</Label>
                  <Input
                    id="date-to"
                    type="date"
                    value={dateTo}
                    onChange={(e) => setDateTo(e.target.value)}
                    className="bg-gray-800 border-gray-600"
                  />
                </div>
              </div>

              <div>
                <Label htmlFor="data-filter">Data Filter</Label>
                <Select defaultValue="all">
                  <SelectTrigger className="bg-gray-800 border-gray-600">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Data</SelectItem>
                    <SelectItem value="validated">Validated Only</SelectItem>
                    <SelectItem value="flagged">Flagged Only</SelectItem>
                    <SelectItem value="recent">Last 7 Days</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              {selectedTemplateInfo && (
                <div className="p-4 bg-gray-800/50 rounded-lg">
                  <div className="flex items-center gap-2 mb-2">
                    <selectedTemplateInfo.icon className={`h-4 w-4 ${selectedTemplateInfo.color}`} />
                    <span className="font-medium text-white">{selectedTemplateInfo.name}</span>
                  </div>
                  <p className="text-sm text-gray-400">{selectedTemplateInfo.description}</p>
                </div>
              )}

              {isExporting && (
                <div className="space-y-2">
                  <div className="flex items-center justify-between">
                    <span className="text-sm font-medium text-white">Exporting...</span>
                    <span className="text-sm text-gray-400">{exportProgress}%</span>
                  </div>
                  <Progress value={exportProgress} className="h-2" />
                </div>
              )}

              <Button 
                onClick={handleExport} 
                disabled={isExporting || !dateFrom || !dateTo}
                className="w-full bg-orange-600 hover:bg-orange-700"
              >
                <Download className="h-4 w-4 mr-2" />
                {isExporting ? 'Exporting...' : 'Export Data'}
              </Button>
            </CardContent>
          </Card>
        </div>

        {/* Quick Stats & Recent Exports */}
        <div className="space-y-6">
          {/* Export Statistics */}
          <Card className="bg-[#1E1E1E] border-gray-800">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Database className="h-5 w-5" />
                Export Statistics
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-gray-400">Total Exports</span>
                  <span className="text-lg font-bold text-white">24</span>
                </div>
              </div>
              <div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-gray-400">This Month</span>
                  <span className="text-lg font-bold text-white">8</span>
                </div>
              </div>
              <div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-gray-400">Data Volume</span>
                  <span className="text-lg font-bold text-white">15.2 MB</span>
                </div>
              </div>
              <div>
                <div className="flex items-center justify-between">
                  <span className="text-sm text-gray-400">Last Export</span>
                  <span className="text-sm text-white">2h ago</span>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Scheduled Exports */}
          <Card className="bg-[#1E1E1E] border-gray-800">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Calendar className="h-5 w-5" />
                Scheduled Exports
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-3">
                <div className="flex items-center justify-between p-3 bg-gray-800/50 rounded-lg">
                  <div>
                    <div className="text-sm font-medium text-white">Weekly Report</div>
                    <div className="text-xs text-gray-400">Every Monday 9:00 AM</div>
                  </div>
                  <Badge className="bg-green-600">Active</Badge>
                </div>
                <div className="flex items-center justify-between p-3 bg-gray-800/50 rounded-lg">
                  <div>
                    <div className="text-sm font-medium text-white">Compliance Backup</div>
                    <div className="text-xs text-gray-400">Last day of month</div>
                  </div>
                  <Badge className="bg-green-600">Active</Badge>
                </div>
              </div>
              <Button variant="outline" size="sm" className="w-full mt-4">
                Manage Schedules
              </Button>
            </CardContent>
          </Card>
        </div>
      </div>

      {/* Export History */}
      <Card className="bg-[#1E1E1E] border-gray-800">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <History className="h-5 w-5" />
            Export History
          </CardTitle>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>File</TableHead>
                <TableHead>Type</TableHead>
                <TableHead>Date Range</TableHead>
                <TableHead>Created</TableHead>
                <TableHead>Status</TableHead>
                <TableHead>Size</TableHead>
                <TableHead>Downloads</TableHead>
                <TableHead>Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {mockExportHistory.map((exportItem) => (
                <TableRow key={exportItem.id}>
                  <TableCell>
                    <div className="flex items-center gap-2">
                      {getStatusIcon(exportItem.status)}
                      <span className="font-medium text-white">{exportItem.filename}</span>
                    </div>
                  </TableCell>
                  <TableCell>
                    <Badge variant="outline">{exportItem.type}</Badge>
                  </TableCell>
                  <TableCell>
                    <div className="text-sm text-gray-300">
                      {format(exportItem.dateRange.from, 'MMM dd')} - {format(exportItem.dateRange.to, 'MMM dd')}
                    </div>
                  </TableCell>
                  <TableCell>
                    <div>
                      <div className="text-sm text-white">
                        {formatDistanceToNow(exportItem.createdAt, { addSuffix: true })}
                      </div>
                      <div className="text-xs text-gray-400">{exportItem.createdBy}</div>
                    </div>
                  </TableCell>
                  <TableCell>{getStatusBadge(exportItem.status)}</TableCell>
                  <TableCell>
                    <span className="font-mono text-sm">{exportItem.size}</span>
                  </TableCell>
                  <TableCell>
                    <span className="text-sm">{exportItem.downloadCount}</span>
                  </TableCell>
                  <TableCell>
                    <div className="flex items-center gap-2">
                      <Button
                        variant="ghost"
                        size="sm"
                        disabled={exportItem.status !== 'completed'}
                      >
                        <Download className="h-3 w-3" />
                      </Button>
                      {exportItem.status === 'failed' && (
                        <Button variant="ghost" size="sm">
                          <RefreshCw className="h-3 w-3" />
                        </Button>
                      )}
                    </div>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  );
}