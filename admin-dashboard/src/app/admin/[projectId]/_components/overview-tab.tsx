'use client';

import React from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { 
  Activity, 
  Clock, 
  Users, 
  FileText, 
  Download, 
  AlertTriangle, 
  CheckCircle, 
  TrendingUp,
  Calendar,
  Database,
  Settings,
  Eye,
  ArrowRight
} from 'lucide-react';
import { Project } from '@/lib/firestore/projects';
import { formatDistanceToNow } from 'date-fns';

interface OverviewTabProps {
  project: Project;
}

// Quick action shortcuts
const QUICK_ACTIONS = [
  {
    title: 'Add Log Entry',
    description: 'Record new thermal reading',
    icon: FileText,
    href: '?tab=logs',
    variant: 'default' as const
  },
  {
    title: 'Export Data',
    description: 'Download Excel report',
    icon: Download,
    href: '?tab=exports',
    variant: 'outline' as const
  },
  {
    title: 'Assign Template',
    description: 'Update log template',
    icon: Settings,
    href: '?tab=assign',
    variant: 'outline' as const
  },
  {
    title: 'View Compliance',
    description: 'Check validation status',
    icon: CheckCircle,
    href: '?tab=compliance',
    variant: 'outline' as const
  }
];

// Mock KPI data (replace with real calculations)
const mockKPIs = {
  totalEntries: 156,
  completionRate: 87.5,
  validationErrors: 3,
  lastEntry: new Date(Date.now() - 2 * 60 * 60 * 1000), // 2 hours ago
  operatorsActive: 4,
  exportsPending: 2
};

// Mock recent activity (replace with real data)
const mockActivity = [
  {
    id: '1',
    type: 'entry',
    message: 'New thermal reading recorded by J.Smith',
    timestamp: new Date(Date.now() - 30 * 60 * 1000),
    icon: FileText,
    iconColor: 'text-blue-400'
  },
  {
    id: '2',
    type: 'export',
    message: 'Excel report exported for Jan 15-20',
    timestamp: new Date(Date.now() - 2 * 60 * 60 * 1000),
    icon: Download,
    iconColor: 'text-green-400'
  },
  {
    id: '3',
    type: 'validation',
    message: 'Validation warning: Temperature outlier detected',
    timestamp: new Date(Date.now() - 4 * 60 * 60 * 1000),
    icon: AlertTriangle,
    iconColor: 'text-amber-400'
  },
  {
    id: '4',
    type: 'assignment',
    message: 'Template v2.1 assigned by Admin',
    timestamp: new Date(Date.now() - 6 * 60 * 60 * 1000),
    icon: Settings,
    iconColor: 'text-purple-400'
  }
];

export function OverviewTab({ project }: OverviewTabProps) {
  return (
    <div className="p-6 space-y-6">
      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card className="bg-[#1E1E1E] border-gray-800">
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-400">Total Entries</p>
                <p className="text-3xl font-bold text-white">{mockKPIs.totalEntries}</p>
                <p className="text-xs text-green-400 mt-1">+12 this week</p>
              </div>
              <FileText className="h-8 w-8 text-blue-400" />
            </div>
          </CardContent>
        </Card>

        <Card className="bg-[#1E1E1E] border-gray-800">
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-400">Completion</p>
                <p className="text-3xl font-bold text-white">{mockKPIs.completionRate}%</p>
                <Progress value={mockKPIs.completionRate} className="mt-2 h-2" />
              </div>
              <TrendingUp className="h-8 w-8 text-green-400" />
            </div>
          </CardContent>
        </Card>

        <Card className="bg-[#1E1E1E] border-gray-800">
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-400">Validation Errors</p>
                <p className="text-3xl font-bold text-white">{mockKPIs.validationErrors}</p>
                <p className="text-xs text-amber-400 mt-1">Needs attention</p>
              </div>
              <AlertTriangle className="h-8 w-8 text-amber-400" />
            </div>
          </CardContent>
        </Card>

        <Card className="bg-[#1E1E1E] border-gray-800">
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm font-medium text-gray-400">Active Operators</p>
                <p className="text-3xl font-bold text-white">{mockKPIs.operatorsActive}</p>
                <p className="text-xs text-blue-400 mt-1">Online now</p>
              </div>
              <Users className="h-8 w-8 text-blue-400" />
            </div>
          </CardContent>
        </Card>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Project Status */}
        <div className="lg:col-span-2 space-y-6">
          {/* Current Status */}
          <Card className="bg-[#1E1E1E] border-gray-800">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Activity className="h-5 w-5" />
                Project Status
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <p className="text-sm font-medium text-gray-400">Last Entry</p>
                  <p className="text-white">
                    {formatDistanceToNow(mockKPIs.lastEntry, { addSuffix: true })}
                  </p>
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-400">Template Version</p>
                  <div className="flex items-center gap-2">
                    <span className="text-white">v{project.assignedVersion}</span>
                    <Badge className="bg-green-600">Active</Badge>
                  </div>
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-400">Data Quality</p>
                  <div className="flex items-center gap-2">
                    <span className="text-white">Good</span>
                    <CheckCircle className="h-4 w-4 text-green-400" />
                  </div>
                </div>
                <div>
                  <p className="text-sm font-medium text-gray-400">Export Status</p>
                  <div className="flex items-center gap-2">
                    <span className="text-white">{mockKPIs.exportsPending} pending</span>
                    <Clock className="h-4 w-4 text-amber-400" />
                  </div>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Recent Activity */}
          <Card className="bg-[#1E1E1E] border-gray-800">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Clock className="h-5 w-5" />
                Recent Activity
              </CardTitle>
            </CardHeader>
            <CardContent>
              <div className="space-y-4">
                {mockActivity.map((activity) => {
                  const Icon = activity.icon;
                  return (
                    <div key={activity.id} className="flex items-start gap-3 p-3 rounded-lg hover:bg-gray-800/50 transition-colors">
                      <div className={`w-8 h-8 rounded-lg bg-gray-800 flex items-center justify-center`}>
                        <Icon className={`h-4 w-4 ${activity.iconColor}`} />
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-sm text-white">{activity.message}</p>
                        <p className="text-xs text-gray-400 mt-1">
                          {formatDistanceToNow(activity.timestamp, { addSuffix: true })}
                        </p>
                      </div>
                    </div>
                  );
                })}
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Quick Actions */}
        <div className="space-y-6">
          <Card className="bg-[#1E1E1E] border-gray-800">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Database className="h-5 w-5" />
                Quick Actions
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              {QUICK_ACTIONS.map((action) => {
                const Icon = action.icon;
                return (
                  <Button
                    key={action.title}
                    variant={action.variant}
                    className="w-full justify-start h-auto p-4 text-left"
                    asChild
                  >
                    <a href={action.href}>
                      <div className="flex items-center gap-3">
                        <Icon className="h-5 w-5 flex-shrink-0" />
                        <div className="flex-1 min-w-0">
                          <p className="font-medium">{action.title}</p>
                          <p className="text-xs text-gray-400">{action.description}</p>
                        </div>
                        <ArrowRight className="h-4 w-4 flex-shrink-0" />
                      </div>
                    </a>
                  </Button>
                );
              })}
            </CardContent>
          </Card>

          {/* Project Information */}
          <Card className="bg-[#1E1E1E] border-gray-800">
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Database className="h-5 w-5" />
                Project Details
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-3">
              <div>
                <p className="text-sm font-medium text-gray-400">Project Number</p>
                <p className="text-white font-mono">{project.projectNumber}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-gray-400">Facility</p>
                <p className="text-white">{project.facility}</p>
              </div>
              <div>
                <p className="text-sm font-medium text-gray-400">Tank ID</p>
                <p className="text-white font-mono">{project.tankId}</p>
              </div>
              {(project as any).startDate && (
                <div>
                  <p className="text-sm font-medium text-gray-400">Start Date</p>
                  <p className="text-white">{(project as any).startDate.toLocaleDateString()}</p>
                </div>
              )}
              {(project as any).endDate && (
                <div>
                  <p className="text-sm font-medium text-gray-400">End Date</p>
                  <p className="text-white">{(project as any).endDate.toLocaleDateString()}</p>
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}