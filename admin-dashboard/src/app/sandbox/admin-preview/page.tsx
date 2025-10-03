'use client';

import React, { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { Input } from '@/components/ui/input';
import { Checkbox } from '@/components/ui/checkbox';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { 
  FileText, 
  Users, 
  CheckCircle, 
  Clock, 
  AlertCircle, 
  Download,
  Activity,
  TrendingUp,
  Search,
  Filter,
  X,
  AlertTriangle,
  Building,
  Settings,
  RefreshCw,
  Eye,
  User,
  Smartphone,
  Zap,
  Calendar,
  Minus,
  XCircle,
  TrendingDown
} from 'lucide-react';
import { cn } from '@/lib/utils';

// Enhanced Table Components
const EnhancedTable = React.forwardRef<
  HTMLTableElement,
  React.HTMLAttributes<HTMLTableElement> & { stickyHeader?: boolean }
>(({ className, stickyHeader = false, ...props }, ref) => (
  <div className="relative w-full overflow-auto">
    <table
      ref={ref}
      className={cn("w-full caption-bottom text-sm", className)}
      {...props}
    />
  </div>
));
EnhancedTable.displayName = "EnhancedTable";

const EnhancedTableHeader = React.forwardRef<
  HTMLTableSectionElement,
  React.HTMLAttributes<HTMLTableSectionElement> & { sticky?: boolean }
>(({ className, sticky = false, ...props }, ref) => (
  <thead 
    ref={ref} 
    className={cn(
      "[&_tr]:border-b-2 [&_tr]:border-gray-700",
      sticky && "sticky top-0 bg-[#1E1E1E] z-10 shadow-lg",
      className
    )} 
    {...props} 
  />
));
EnhancedTableHeader.displayName = "EnhancedTableHeader";

const EnhancedTableBody = React.forwardRef<
  HTMLTableSectionElement,
  React.HTMLAttributes<HTMLTableSectionElement>
>(({ className, ...props }, ref) => (
  <tbody
    ref={ref}
    className={cn("[&_tr:last-child]:border-0", className)}
    {...props}
  />
));
EnhancedTableBody.displayName = "EnhancedTableBody";

const EnhancedTableRow = React.forwardRef<
  HTMLTableRowElement,
  React.HTMLAttributes<HTMLTableRowElement> & { 
    status?: 'normal' | 'warning' | 'critical' | 'missing';
    clickable?: boolean;
  }
>(({ className, status = 'normal', clickable = false, ...props }, ref) => {
  const statusClasses = {
    normal: '',
    warning: 'bg-amber-950/20 border-l-4 border-amber-500',
    critical: 'bg-red-950/20 border-l-4 border-red-500',
    missing: 'bg-red-950/30 border-l-4 border-red-600'
  };

  return (
    <tr
      ref={ref}
      className={cn(
        "border-b transition-colors hover:bg-gray-800/50",
        clickable && "cursor-pointer",
        statusClasses[status],
        className
      )}
      {...props}
    />
  );
});
EnhancedTableRow.displayName = "EnhancedTableRow";

const EnhancedTableHead = React.forwardRef<
  HTMLTableCellElement,
  React.ThHTMLAttributes<HTMLTableCellElement> & { 
    sortable?: boolean;
    align?: 'left' | 'center' | 'right';
  }
>(({ className, sortable = false, align = 'left', ...props }, ref) => {
  const alignClasses = {
    left: 'text-left',
    center: 'text-center', 
    right: 'text-right'
  };

  return (
    <th
      ref={ref}
      className={cn(
        "h-12 px-4 align-middle font-bold text-gray-200 uppercase tracking-wider text-xs",
        alignClasses[align],
        sortable && "cursor-pointer hover:text-white",
        "[&:has([role=checkbox])]:pr-0",
        className
      )}
      {...props}
    />
  );
});
EnhancedTableHead.displayName = "EnhancedTableHead";

const EnhancedTableCell = React.forwardRef<
  HTMLTableCellElement,
  React.TdHTMLAttributes<HTMLTableCellElement> & {
    align?: 'left' | 'center' | 'right';
    mono?: boolean;
  }
>(({ className, align = 'left', mono = false, ...props }, ref) => {
  const alignClasses = {
    left: 'text-left',
    center: 'text-center',
    right: 'text-right'
  };

  return (
    <td
      ref={ref}
      className={cn(
        "p-3 align-middle text-sm",
        alignClasses[align],
        mono && "font-mono",
        "[&:has([role=checkbox])]:pr-0",
        className
      )}
      {...props}
    />
  );
});
EnhancedTableCell.displayName = "EnhancedTableCell";

// Mock Data
interface ProjectData {
  id: string;
  facility: string;
  tankId: string;
  logType: string;
  template: {
    name: string;
    version: string;
    hasExcel: boolean;
  };
  progress: {
    completed: number;
    total: number;
  };
  lastEntry: {
    timestamp: Date;
    operator: string;
  };
  status: 'on-time' | 'delayed' | 'missing' | 'critical';
  completeness: number;
  validationErrors: number;
  exportReady: boolean;
  lastModified: {
    user: string;
    timestamp: Date;
  };
}

const mockProjects: ProjectData[] = [
  {
    id: 'PROJ-001',
    facility: 'Tank Farm Alpha',
    tankId: 'TANK-A1',
    logType: 'H2S',
    template: {
      name: 'TX-METHANE',
      version: 'v2.1',
      hasExcel: true
    },
    progress: { completed: 18, total: 24 },
    lastEntry: {
      timestamp: new Date(Date.now() - 30 * 60 * 1000),
      operator: 'J.Smith'
    },
    status: 'on-time',
    completeness: 88.5,
    validationErrors: 0,
    exportReady: true,
    lastModified: {
      user: 'J.Smith',
      timestamp: new Date(Date.now() - 45 * 60 * 1000)
    }
  },
  {
    id: 'PROJ-002',
    facility: 'Tank Farm Beta',
    tankId: 'TANK-B2',
    logType: 'Combined',
    template: {
      name: 'Flutter Mobile',
      version: 'native',
      hasExcel: false
    },
    progress: { completed: 22, total: 24 },
    lastEntry: {
      timestamp: new Date(Date.now() - 2 * 60 * 60 * 1000),
      operator: 'M.Wilson'
    },
    status: 'delayed',
    completeness: 91.7,
    validationErrors: 1,
    exportReady: false,
    lastModified: {
      user: 'M.Wilson',
      timestamp: new Date(Date.now() - 2.5 * 60 * 60 * 1000)
    }
  },
  {
    id: 'PROJ-003',
    facility: 'Tank Farm Gamma',
    tankId: 'TANK-C3',
    logType: 'Benzene',
    template: {
      name: 'TX-PENTANE',
      version: 'v1.8',
      hasExcel: true
    },
    progress: { completed: 8, total: 24 },
    lastEntry: {
      timestamp: new Date(Date.now() - 4 * 60 * 60 * 1000),
      operator: 'S.Jones'
    },
    status: 'missing',
    completeness: 33.3,
    validationErrors: 3,
    exportReady: false,
    lastModified: {
      user: 'S.Jones',
      timestamp: new Date(Date.now() - 4.5 * 60 * 60 * 1000)
    }
  },
  {
    id: 'PROJ-004',
    facility: 'Tank Farm Delta',
    tankId: 'TANK-D4',
    logType: 'H2S+LEL',
    template: {
      name: 'TX-PENTANE-LEL',
      version: 'v3.0',
      hasExcel: true
    },
    progress: { completed: 12, total: 24 },
    lastEntry: {
      timestamp: new Date(Date.now() - 6 * 60 * 60 * 1000),
      operator: 'R.Davis'
    },
    status: 'critical',
    completeness: 50.0,
    validationErrors: 5,
    exportReady: false,
    lastModified: {
      user: 'R.Davis',
      timestamp: new Date(Date.now() - 6.2 * 60 * 60 * 1000)
    }
  },
  {
    id: 'PROJ-005',
    facility: 'Tank Farm Echo',
    tankId: 'TANK-E5',
    logType: 'Hourly',
    template: {
      name: 'TX-METHANE-STD',
      version: 'v2.3',
      hasExcel: true
    },
    progress: { completed: 24, total: 24 },
    lastEntry: {
      timestamp: new Date(Date.now() - 15 * 60 * 1000),
      operator: 'L.Brown'
    },
    status: 'on-time',
    completeness: 100.0,
    validationErrors: 0,
    exportReady: true,
    lastModified: {
      user: 'L.Brown',
      timestamp: new Date(Date.now() - 20 * 60 * 1000)
    }
  }
];

// Helper Functions
function getStatusBadge(status: ProjectData['status']) {
  switch (status) {
    case 'on-time':
      return <Badge className="bg-green-600 text-white border-0">✅ On Time</Badge>;
    case 'delayed':
      return <Badge className="bg-amber-500 text-white border-0">🟡 Delayed</Badge>;
    case 'missing':
      return <Badge variant="destructive">🚫 Missing</Badge>;
    case 'critical':
      return <Badge variant="destructive">🔴 Critical</Badge>;
    default:
      return <Badge variant="outline">❓ Unknown</Badge>;
  }
}

function getValidationBadge(errors: number) {
  if (errors === 0) return <Badge className="bg-green-600 text-xs">✅ Valid</Badge>;
  if (errors <= 2) return <Badge className="bg-amber-500 text-xs">⚠️ {errors}</Badge>;
  return <Badge variant="destructive" className="text-xs">❌ {errors}</Badge>;
}

function getExportBadge(ready: boolean) {
  return ready ? 
    <Badge className="bg-green-600 text-xs">✅ Ready</Badge> : 
    <Badge className="bg-amber-500 text-xs">⏳ Pending</Badge>;
}

function getTemplateIndicator(template: ProjectData['template']) {
  if (!template.hasExcel) {
    return (
      <div className="flex items-center gap-1.5 text-blue-400">
        <div className="w-2 h-2 bg-blue-400 rounded-full"></div>
        <span className="text-xs font-medium">Flutter</span>
      </div>
    );
  }

  return (
    <div className="flex items-center gap-1.5 text-green-400">
      <div className="w-2 h-2 bg-green-400 rounded-full"></div>
      <span className="text-xs font-medium">Excel {template.version}</span>
    </div>
  );
}

function formatTimeAgo(date: Date): string {
  const now = new Date();
  const diffInMinutes = Math.floor((now.getTime() - date.getTime()) / (1000 * 60));
  
  if (diffInMinutes < 60) {
    return `${diffInMinutes}m ago`;
  } else if (diffInMinutes < 1440) {
    return `${Math.floor(diffInMinutes / 60)}h ago`;
  } else {
    return `${Math.floor(diffInMinutes / 1440)}d ago`;
  }
}

// Enhanced Project Table Component
function EnhancedProjectTable() {
  const [projects] = useState<ProjectData[]>(mockProjects);

  const getRowStatus = (project: ProjectData) => {
    switch (project.status) {
      case 'critical': return 'critical';
      case 'missing': return 'missing';
      case 'delayed': return 'warning';
      default: return 'normal';
    }
  };

  return (
    <div className="w-full space-y-4">
      <div className="bg-[#1E1E1E] border border-gray-800 rounded-lg overflow-hidden">
        <EnhancedTable>
          <EnhancedTableHeader sticky>
            <EnhancedTableRow>
              <EnhancedTableHead>Project ID</EnhancedTableHead>
              <EnhancedTableHead>Facility/Tank</EnhancedTableHead>
              <EnhancedTableHead>Type</EnhancedTableHead>
              <EnhancedTableHead>Template</EnhancedTableHead>
              <EnhancedTableHead align="right">Progress</EnhancedTableHead>
              <EnhancedTableHead>Last Entry</EnhancedTableHead>
              <EnhancedTableHead align="right">Complete %</EnhancedTableHead>
              <EnhancedTableHead align="center">Validation</EnhancedTableHead>
              <EnhancedTableHead align="center">Export</EnhancedTableHead>
              <EnhancedTableHead>Modified By</EnhancedTableHead>
              <EnhancedTableHead align="center">Actions</EnhancedTableHead>
            </EnhancedTableRow>
          </EnhancedTableHeader>
          <EnhancedTableBody>
            {projects.map((project) => (
              <EnhancedTableRow 
                key={project.id} 
                status={getRowStatus(project)}
                clickable
              >
                <EnhancedTableCell mono className="font-bold text-white">
                  {project.id}
                </EnhancedTableCell>
                <EnhancedTableCell>
                  <div>
                    <div className="font-medium text-white">{project.facility}</div>
                    <div className="text-xs text-gray-400 font-mono">{project.tankId}</div>
                  </div>
                </EnhancedTableCell>
                <EnhancedTableCell>
                  <Badge variant="outline" className="text-xs border-gray-600">
                    {project.logType}
                  </Badge>
                </EnhancedTableCell>
                <EnhancedTableCell>
                  <div className="space-y-1">
                    {getTemplateIndicator(project.template)}
                    <div className="text-xs text-gray-400">{project.template.name}</div>
                  </div>
                </EnhancedTableCell>
                <EnhancedTableCell align="right">
                  <div className="space-y-1">
                    <div className="text-sm font-mono text-white">
                      {project.progress.completed}/{project.progress.total} hrs
                    </div>
                    <Progress 
                      value={(project.progress.completed / project.progress.total) * 100} 
                      className="w-20 h-2"
                    />
                  </div>
                </EnhancedTableCell>
                <EnhancedTableCell>
                  <div>
                    <div className="text-sm text-white">{formatTimeAgo(project.lastEntry.timestamp)}</div>
                    <div>{getStatusBadge(project.status)}</div>
                  </div>
                </EnhancedTableCell>
                <EnhancedTableCell align="right" mono className="text-white font-semibold">
                  {project.completeness.toFixed(1)}%
                </EnhancedTableCell>
                <EnhancedTableCell align="center">
                  {getValidationBadge(project.validationErrors)}
                </EnhancedTableCell>
                <EnhancedTableCell align="center">
                  {getExportBadge(project.exportReady)}
                </EnhancedTableCell>
                <EnhancedTableCell>
                  <div className="flex items-center gap-1 text-gray-300">
                    <User className="h-3 w-3" />
                    <span className="text-xs">{project.lastModified.user}</span>
                  </div>
                  <div className="text-xs text-gray-500">
                    {formatTimeAgo(project.lastModified.timestamp)}
                  </div>
                </EnhancedTableCell>
                <EnhancedTableCell align="center">
                  <div className="flex items-center gap-1">
                    <Button variant="ghost" size="sm" className="h-8 w-8 p-0">
                      <Eye className="h-3 w-3" />
                    </Button>
                    <Button variant="ghost" size="sm" className="h-8 w-8 p-0">
                      <Settings className="h-3 w-3" />
                    </Button>
                    <Button variant="ghost" size="sm" className="h-8 w-8 p-0">
                      <Download className="h-3 w-3" />
                    </Button>
                  </div>
                </EnhancedTableCell>
              </EnhancedTableRow>
            ))}
          </EnhancedTableBody>
        </EnhancedTable>
      </div>
    </div>
  );
}

// Compliance Filters Interface
interface ComplianceFilters {
  search: string;
  missingHours: boolean;
  failedChecks: boolean;
  needsExport: boolean;
  facility: string[];
  logType: string[];
  template: string[];
  dateRange: {
    from: Date | null;
    to: Date | null;
  };
  status: string[];
  operator: string[];
}

// Quick Filter Component
interface QuickFilterProps {
  label: string;
  icon: React.ReactNode;
  active: boolean;
  count?: number;
  onClick: () => void;
  variant?: 'default' | 'critical' | 'warning';
}

function QuickFilter({ label, icon, active, count, onClick, variant = 'default' }: QuickFilterProps) {
  const variantClasses = {
    default: active ? 'bg-blue-600 text-white border-blue-600' : 'border-gray-600 text-gray-300 hover:bg-gray-700',
    critical: active ? 'bg-red-600 text-white border-red-600' : 'border-red-800 text-red-400 hover:bg-red-950',
    warning: active ? 'bg-amber-500 text-white border-amber-500' : 'border-amber-700 text-amber-400 hover:bg-amber-950'
  };

  return (
    <Button
      variant="outline"
      size="sm"
      onClick={onClick}
      className={cn(
        'flex items-center gap-2 h-8 px-3 transition-all',
        variantClasses[variant]
      )}
    >
      {icon}
      <span className="text-xs font-medium">{label}</span>
      {count !== undefined && (
        <Badge 
          variant="secondary" 
          className={cn(
            'ml-1 h-4 px-1.5 text-xs',
            active ? 'bg-white/20 text-white' : 'bg-gray-600'
          )}
        >
          {count}
        </Badge>
      )}
    </Button>
  );
}

// Compliance Filters Component
function ComplianceFiltersBar({ 
  filters, 
  onFiltersChange, 
  className 
}: {
  filters: ComplianceFilters;
  onFiltersChange: (filters: ComplianceFilters) => void;
  className?: string;
}) {
  const [isAdvancedOpen, setIsAdvancedOpen] = useState(false);

  const mockCounts = {
    missingHours: 8,
    failedChecks: 3,
    needsExport: 12
  };

  const updateFilters = (updates: Partial<ComplianceFilters>) => {
    onFiltersChange({ ...filters, ...updates });
  };

  const clearFilters = () => {
    onFiltersChange({
      search: '',
      missingHours: false,
      failedChecks: false,
      needsExport: false,
      facility: [],
      logType: [],
      template: [],
      dateRange: { from: null, to: null },
      status: [],
      operator: []
    });
  };

  const activeFilterCount = [
    filters.missingHours,
    filters.failedChecks,
    filters.needsExport,
    filters.facility.length > 0,
    filters.logType.length > 0,
    filters.template.length > 0,
    filters.status.length > 0,
    filters.operator.length > 0,
    filters.search.length > 0
  ].filter(Boolean).length;

  return (
    <div className={cn('space-y-4', className)}>
      <Card className="bg-[#1E1E1E] border-gray-800">
        <CardContent className="p-4">
          <div className="flex flex-wrap items-center gap-3">
            <QuickFilter
              label="Missing Hours"
              icon={<Clock className="h-3 w-3" />}
              active={filters.missingHours}
              count={mockCounts.missingHours}
              onClick={() => updateFilters({ missingHours: !filters.missingHours })}
              variant="critical"
            />
            
            <QuickFilter
              label="Failed Checks"
              icon={<AlertTriangle className="h-3 w-3" />}
              active={filters.failedChecks}
              count={mockCounts.failedChecks}
              onClick={() => updateFilters({ failedChecks: !filters.failedChecks })}
              variant="critical"
            />
            
            <QuickFilter
              label="Needs Export"
              icon={<Download className="h-3 w-3" />}
              active={filters.needsExport}
              count={mockCounts.needsExport}
              onClick={() => updateFilters({ needsExport: !filters.needsExport })}
              variant="warning"
            />

            <div className="w-px h-6 bg-gray-600" />

            <Button
              variant="outline"
              size="sm"
              onClick={() => setIsAdvancedOpen(!isAdvancedOpen)}
              className={cn(
                'border-gray-600 text-gray-300 hover:bg-gray-700',
                isAdvancedOpen && 'bg-gray-700'
              )}
            >
              <Filter className="h-3 w-3 mr-2" />
              Advanced
              {activeFilterCount > 3 && (
                <Badge variant="secondary" className="ml-2 h-4 px-1.5">
                  {activeFilterCount - 3}
                </Badge>
              )}
            </Button>

            <div className="flex-1 min-w-64">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
                <Input
                  placeholder="Search projects, tanks, operators..."
                  value={filters.search}
                  onChange={(e) => updateFilters({ search: e.target.value })}
                  className="pl-10 bg-gray-800 border-gray-600 text-white placeholder-gray-400"
                />
              </div>
            </div>

            {activeFilterCount > 0 && (
              <Button
                variant="ghost"
                size="sm"
                onClick={clearFilters}
                className="text-gray-400 hover:text-white"
              >
                <X className="h-3 w-3 mr-1" />
                Clear All
              </Button>
            )}

            <Button
              variant="ghost"
              size="sm"
              className="text-gray-400 hover:text-white"
            >
              <RefreshCw className="h-3 w-3" />
            </Button>
          </div>
        </CardContent>
      </Card>

      {isAdvancedOpen && (
        <Card className="bg-[#1E1E1E] border-gray-800">
          <CardContent className="p-4">
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
              <div>
                <label className="text-sm font-medium text-gray-300 mb-2 block">
                  <Building className="h-3 w-3 inline mr-1" />
                  Facility
                </label>
                <Select>
                  <SelectTrigger className="bg-gray-800 border-gray-600">
                    <SelectValue placeholder="Select facilities..." />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="alpha">Tank Farm Alpha</SelectItem>
                    <SelectItem value="beta">Tank Farm Beta</SelectItem>
                    <SelectItem value="gamma">Tank Farm Gamma</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div>
                <label className="text-sm font-medium text-gray-300 mb-2 block">
                  <Settings className="h-3 w-3 inline mr-1" />
                  Log Type
                </label>
                <Select>
                  <SelectTrigger className="bg-gray-800 border-gray-600">
                    <SelectValue placeholder="Select types..." />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="h2s">H2S</SelectItem>
                    <SelectItem value="benzene">Benzene</SelectItem>
                    <SelectItem value="combined">Combined</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div>
                <label className="text-sm font-medium text-gray-300 mb-2 block">
                  Status
                </label>
                <Select>
                  <SelectTrigger className="bg-gray-800 border-gray-600">
                    <SelectValue placeholder="Select status..." />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="on-time">On Time</SelectItem>
                    <SelectItem value="delayed">Delayed</SelectItem>
                    <SelectItem value="missing">Missing</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div>
                <label className="text-sm font-medium text-gray-300 mb-2 block">
                  <Calendar className="h-3 w-3 inline mr-1" />
                  Date Range
                </label>
                <div className="flex gap-2">
                  <Input
                    type="date"
                    className="bg-gray-800 border-gray-600 text-white"
                  />
                  <Input
                    type="date"
                    className="bg-gray-800 border-gray-600 text-white"
                  />
                </div>
              </div>
            </div>
          </CardContent>
        </Card>
      )}
    </div>
  );
}

// Status Badge Components (simplified for inline use)
function StatusBadgeShowcase() {
  return (
    <div className="space-y-6">
      <div>
        <h3 className="text-sm font-medium mb-3 text-gray-400">Compliance Status</h3>
        <div className="flex flex-wrap gap-2">
          <Badge className="bg-green-600 text-white border-0">
            <CheckCircle className="w-3 h-3 mr-1" />
            Compliant
          </Badge>
          <Badge className="bg-amber-500 text-white border-0">
            <Clock className="w-3 h-3 mr-1" />
            Pending Review
          </Badge>
          <Badge className="bg-orange-600 text-white border-0">
            <AlertTriangle className="w-3 h-3 mr-1" />
            Overdue
          </Badge>
          <Badge className="bg-red-600 text-white border-0">
            <XCircle className="w-3 h-3 mr-1" />
            Failed
          </Badge>
        </div>
      </div>

      <div>
        <h3 className="text-sm font-medium mb-3 text-gray-400">Progress Status</h3>
        <div className="flex flex-wrap gap-2">
          <Badge className="bg-green-600 text-white border-0">
            <TrendingUp className="w-3 h-3 mr-1" />
            On Track (85.5%)
          </Badge>
          <Badge className="bg-amber-500 text-white border-0">
            <TrendingDown className="w-3 h-3 mr-1" />
            Behind (64.2%)
          </Badge>
          <Badge className="bg-red-600 text-white border-0 animate-pulse">
            <AlertTriangle className="w-3 h-3 mr-1" />
            Critical (23.1%)
          </Badge>
          <Badge className="bg-green-700 text-white border-0">
            <CheckCircle className="w-3 h-3 mr-1" />
            Complete (100%)
          </Badge>
        </div>
      </div>

      <div>
        <h3 className="text-sm font-medium mb-3 text-gray-400">Template Types</h3>
        <div className="flex flex-wrap gap-2">
          <div className="flex items-center gap-1">
            <Badge className="bg-green-600 text-white border-0 text-xs">
              <FileText className="w-3 h-3 mr-1" />
              Excel v2.1
            </Badge>
          </div>
          <div className="flex items-center gap-1">
            <Badge className="bg-blue-600 text-white border-0 text-xs">
              <Smartphone className="w-3 h-3 mr-1" />
              Flutter
            </Badge>
          </div>
          <div className="flex items-center gap-2">
            <Badge className="bg-green-600 text-white border-0 text-xs">
              <FileText className="w-3 h-3 mr-1" />
              Excel v3.0
            </Badge>
            <Badge className="bg-amber-500 text-white border-0 text-xs">
              <Zap className="w-3 h-3 mr-1" />
              Auto
            </Badge>
          </div>
        </div>
      </div>

      <div>
        <h3 className="text-sm font-medium mb-3 text-gray-400">Priority Levels</h3>
        <div className="flex flex-wrap gap-2">
          <Badge className="bg-gray-600 text-white border-0 text-xs">
            <Minus className="w-3 h-3 mr-1" />
            Low
          </Badge>
          <Badge className="bg-blue-600 text-white border-0 text-xs">
            <Clock className="w-3 h-3 mr-1" />
            Medium
          </Badge>
          <Badge className="bg-amber-500 text-white border-0 text-xs">
            <AlertTriangle className="w-3 h-3 mr-1" />
            High
          </Badge>
          <Badge className="bg-red-600 text-white border-0 text-xs animate-pulse">
            <XCircle className="w-3 h-3 mr-1" />
            Critical
          </Badge>
        </div>
      </div>
    </div>
  );
}

// Mock KPI data
const mockKPIs = [
  {
    title: 'Total Projects',
    value: '247',
    change: '+2 this month',
    icon: FileText,
    color: 'blue' as const
  },
  {
    title: 'Completed',
    value: '189',
    change: '76.5%',
    icon: CheckCircle,
    color: 'green' as const
  },
  {
    title: 'Pending',
    value: '43',
    change: '17.4%',
    icon: Clock,
    color: 'amber' as const
  },
  {
    title: 'Failed',
    value: '15',
    change: '6.1%',
    icon: AlertCircle,
    color: 'red' as const
  },
  {
    title: 'Export Ready',
    value: '156',
    change: '63.2%',
    icon: Download,
    color: 'blue' as const
  },
  {
    title: 'Active Ops',
    value: '24',
    change: 'Live',
    icon: Users,
    color: 'green' as const
  }
];

function KPICard({ title, value, change, icon: Icon, color }: typeof mockKPIs[0]) {
  const colorClasses = {
    blue: 'text-blue-400',
    green: 'text-green-400',
    amber: 'text-amber-400',
    red: 'text-red-400'
  };

  const changeColorClasses = {
    blue: 'text-blue-400',
    green: 'text-green-400',
    amber: 'text-amber-400',
    red: 'text-red-400'
  };

  return (
    <Card className="bg-[#1E1E1E] border-gray-800">
      <CardContent className="p-4">
        <div className="flex items-center justify-between">
          <div>
            <div className="text-2xl font-bold text-white">{value}</div>
            <div className="text-xs text-gray-400">{title}</div>
            <div className={`text-xs ${changeColorClasses[color]}`}>{change}</div>
          </div>
          <Icon className={`h-6 w-6 ${colorClasses[color]}`} />
        </div>
      </CardContent>
    </Card>
  );
}

// Main Component
export default function AdminPreviewPage() {
  const [filters, setFilters] = useState<ComplianceFilters>({
    search: '',
    missingHours: false,
    failedChecks: false,
    needsExport: false,
    facility: [],
    logType: [],
    template: [],
    dateRange: { from: null, to: null },
    status: [],
    operator: []
  });

  return (
    <div className="min-h-screen bg-[#111111] text-white">
      {/* Header */}
      <div className="bg-[#1E1E1E] border-b border-gray-800 px-6 py-4">
        <div className="flex justify-between items-center">
          <div>
            <h1 className="text-2xl font-semibold">Thermal Log Admin Preview</h1>
            <p className="text-gray-400 text-sm">
              Compliance-grade dashboard components with enhanced design
            </p>
          </div>
          <div className="flex items-center gap-3">
            <Badge className="bg-green-600 border-0">
              🟢 System Online
            </Badge>
            <Button variant="outline" size="sm" className="border-gray-600 text-gray-300">
              Template Builder
            </Button>
          </div>
        </div>
      </div>

      <div className="px-6 py-6">
        <Tabs defaultValue="dashboard" className="space-y-6">
          <TabsList className="bg-[#1E1E1E] border border-gray-800">
            <TabsTrigger value="dashboard" className="data-[state=active]:bg-gray-700">
              Enhanced Dashboard
            </TabsTrigger>
            <TabsTrigger value="badges" className="data-[state=active]:bg-gray-700">
              Status Badges
            </TabsTrigger>
          </TabsList>

          {/* Enhanced Dashboard Tab */}
          <TabsContent value="dashboard" className="space-y-6">
            {/* KPI Cards */}
            <div>
              <h2 className="text-lg font-semibold mb-4">High-Density KPI Dashboard</h2>
              <div className="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-6 gap-4">
                {mockKPIs.map((kpi, index) => (
                  <KPICard key={index} {...kpi} />
                ))}
              </div>
            </div>

            {/* Filters */}
            <div>
              <h2 className="text-lg font-semibold mb-4">Compliance Filters</h2>
              <ComplianceFiltersBar
                filters={filters}
                onFiltersChange={setFilters}
              />
            </div>

            {/* Enhanced Table */}
            <div>
              <h2 className="text-lg font-semibold mb-4">Enhanced Project Table</h2>
              <p className="text-sm text-gray-400 mb-4">
                High-density table with sticky headers, status indicators, and audit signals
              </p>
              <EnhancedProjectTable />
            </div>

            {/* Design Notes */}
            <Card className="bg-[#1E1E1E] border-gray-800">
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <TrendingUp className="h-5 w-5 text-blue-400" />
                  Design Improvements
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
                  <div>
                    <h4 className="font-medium text-white mb-2">Enhanced Features</h4>
                    <ul className="space-y-1 text-gray-300">
                      <li>✅ Sticky table headers during scroll</li>
                      <li>✅ 10+ data points per row (vs 3-4 current)</li>
                      <li>✅ Right-aligned numeric columns</li>
                      <li>✅ Status-based row highlighting</li>
                      <li>✅ Progress bars with completion %</li>
                      <li>✅ Validation error indicators</li>
                      <li>✅ Export readiness status</li>
                      <li>✅ Last modified user & timestamp</li>
                    </ul>
                  </div>
                  <div>
                    <h4 className="font-medium text-white mb-2">Compliance Features</h4>
                    <ul className="space-y-1 text-gray-300">
                      <li>🔴 Critical status highlighting</li>
                      <li>⚠️ Warning states for delayed items</li>
                      <li>🟢 Clear success indicators</li>
                      <li>📊 Data completeness percentage</li>
                      <li>🔍 Quick filter for common issues</li>
                      <li>📋 Audit trail with timestamps</li>
                      <li>⚡ Real-time status updates</li>
                      <li>📱 Template type indicators</li>
                    </ul>
                  </div>
                </div>
              </CardContent>
            </Card>
          </TabsContent>

          {/* Status Badges Tab */}
          <TabsContent value="badges">
            <div className="space-y-6">
              <div>
                <h2 className="text-xl font-bold mb-2">Compliance Status Badges</h2>
                <p className="text-gray-400 text-sm mb-6">
                  Standardized status indicators for compliance teams
                </p>
              </div>
              <StatusBadgeShowcase />
            </div>
          </TabsContent>
        </Tabs>
      </div>
    </div>
  );
}