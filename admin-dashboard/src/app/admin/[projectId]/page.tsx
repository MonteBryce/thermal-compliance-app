'use client';

import React, { useState, useEffect, Suspense } from 'react';
import { useParams, useSearchParams } from 'next/navigation';
import { TabsContent } from '@/components/ui/tabs';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import {
  Breadcrumb,
  BreadcrumbItem,
  BreadcrumbLink,
  BreadcrumbList,
  BreadcrumbPage,
  BreadcrumbSeparator,
} from '@/components/ui/breadcrumb';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { 
  Building, 
  Calendar, 
  Clock, 
  Users, 
  Activity, 
  TrendingUp, 
  FileText, 
  AlertCircle,
  CheckCircle,
  Download,
  Settings,
  Shield,
  History,
  Cog,
  Eye,
  UserCheck,
  BarChart3,
  ArrowLeft,
  Database,
  Layers
} from 'lucide-react';

import { ProjectTabs, PlaceholderTab, TabContentSkeleton, type TabValue } from './_components/project-tabs';
import { Project } from '@/lib/firestore/projects';
import { ProjectService } from '@/lib/firestore/projects';

// Import existing tab components (we'll create these next)
import { OverviewTab } from './_components/overview-tab';
import { LogsTab } from './_components/logs-tab';
import { ExportsTab } from './_components/exports-tab';
import { AssignTab } from './_components/assign-tab';

// Mock project data for now (replace with real Firestore data)
const mockProject = {
  id: 'PROJ-001',
  projectNumber: 'TF-ALPHA-001',
  facility: 'Tank Farm Alpha',
  tankId: 'TANK-A1',
  startDate: new Date('2024-01-15'),
  endDate: new Date('2024-02-15'),
  status: 'active',
  assignedTemplateId: 'template-001',
  assignedVersion: 2,
  assignedAt: new Date('2024-01-16'),
  assignedBy: 'admin@company.com',
  usedTemplates: [],
  createdAt: new Date('2024-01-15'),
  updatedAt: new Date(),
  createdBy: 'admin@company.com'
};

// Project Header Component
function ProjectHeader({ project }: { project: any }) {
  return (
    <div className="bg-[#1E1E1E] border-b border-gray-800 px-6 py-4">
      {/* Breadcrumbs */}
      <Breadcrumb className="mb-4">
        <BreadcrumbList>
          <BreadcrumbItem>
            <BreadcrumbLink href="/admin" className="text-gray-400 hover:text-white">
              Admin
            </BreadcrumbLink>
          </BreadcrumbItem>
          <BreadcrumbSeparator className="text-gray-600" />
          <BreadcrumbItem>
            <BreadcrumbLink href="/admin/projects" className="text-gray-400 hover:text-white">
              Projects
            </BreadcrumbLink>
          </BreadcrumbItem>
          <BreadcrumbSeparator className="text-gray-600" />
          <BreadcrumbItem>
            <BreadcrumbPage className="text-white font-medium">
              {project.projectNumber}
            </BreadcrumbPage>
          </BreadcrumbItem>
        </BreadcrumbList>
      </Breadcrumb>

      {/* Project Info & Switcher */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-6">
          {/* Project Details */}
          <div>
            <div className="flex items-center gap-3 mb-2">
              <h1 className="text-2xl font-bold text-white">{project.projectNumber}</h1>
              <Badge 
                className={
                  project.status === 'active' 
                    ? 'bg-green-600 text-white' 
                    : 'bg-gray-600 text-white'
                }
              >
                {project.status}
              </Badge>
            </div>
            <div className="flex items-center gap-4 text-sm text-gray-400">
              <div className="flex items-center gap-1">
                <Building className="h-4 w-4" />
                <span>{project.facility}</span>
              </div>
              <div className="flex items-center gap-1">
                <Database className="h-4 w-4" />
                <span>{project.tankId}</span>
              </div>
              <div className="flex items-center gap-1">
                <Calendar className="h-4 w-4" />
                <span>{project.startDate.toLocaleDateString()}</span>
              </div>
            </div>
          </div>
        </div>

        {/* Project Switcher & Actions */}
        <div className="flex items-center gap-3">
          <Select defaultValue={project.id}>
            <SelectTrigger className="w-48 bg-gray-800 border-gray-600">
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value={project.id}>
                <div className="flex flex-col items-start">
                  <span className="font-medium">{project.projectNumber}</span>
                  <span className="text-xs text-gray-400">{project.facility}</span>
                </div>
              </SelectItem>
              {/* Add more projects here */}
            </SelectContent>
          </Select>
          
          <Button variant="outline" size="sm" className="border-gray-600 text-gray-300">
            <ArrowLeft className="h-4 w-4 mr-2" />
            Back to Projects
          </Button>
        </div>
      </div>
    </div>
  );
}

// Main Project Portal Page
function ProjectPortalContent() {
  const params = useParams();
  const searchParams = useSearchParams();
  const projectId = params.projectId as string;
  const currentTab = (searchParams.get('tab') as TabValue) || 'overview';
  
  const [project, setProject] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // TODO: Replace with real Firestore call
    const loadProject = async () => {
      try {
        setLoading(true);
        // Simulate API call
        await new Promise(resolve => setTimeout(resolve, 500));
        setProject(mockProject);
      } catch (error) {
        console.error('Error loading project:', error);
      } finally {
        setLoading(false);
      }
    };

    loadProject();
  }, [projectId]);

  if (loading) {
    return (
      <div className="min-h-screen bg-[#111111] text-white">
        <div className="h-24 bg-[#1E1E1E] border-b border-gray-800 animate-pulse" />
        <TabContentSkeleton />
      </div>
    );
  }

  if (!project) {
    return (
      <div className="min-h-screen bg-[#111111] text-white flex items-center justify-center">
        <Card className="bg-[#1E1E1E] border-gray-800 p-8 text-center">
          <AlertCircle className="h-12 w-12 text-red-400 mx-auto mb-4" />
          <h2 className="text-xl font-semibold mb-2">Project Not Found</h2>
          <p className="text-gray-400">
            The project you're looking for doesn't exist or you don't have permission to view it.
          </p>
        </Card>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#111111] text-white">
      {/* Project Header */}
      <ProjectHeader project={project} />

      {/* Tabbed Content */}
      <ProjectTabs projectId={projectId} defaultTab="overview">
        {/* Overview Tab */}
        <TabsContent value="overview" className="mt-0">
          <OverviewTab project={project} />
        </TabsContent>

        {/* Logs Tab */}
        <TabsContent value="logs" className="mt-0">
          <LogsTab project={project} />
        </TabsContent>

        {/* Exports Tab */}
        <TabsContent value="exports" className="mt-0">
          <ExportsTab project={project} />
        </TabsContent>

        {/* Assign Tab */}
        <TabsContent value="assign" className="mt-0">
          <AssignTab project={project} />
        </TabsContent>

        {/* Log Builder Tab - Placeholder */}
        <TabsContent value="log-builder" className="mt-0">
          <PlaceholderTab
            icon={Settings}
            title="Log Builder"
            description="Build and customize log templates specifically for this project"
            features={[
              'Drag-and-drop template designer',
              'Field validation rules',
              'Preview operator interface',
              'Version control and publishing',
              'Custom field types and calculations'
            ]}
          />
        </TabsContent>

        {/* Compliance Tab - Placeholder */}
        <TabsContent value="compliance" className="mt-0">
          <PlaceholderTab
            icon={Shield}
            title="Compliance Monitoring"
            description="Monitor compliance status and validation for this project"
            features={[
              'Real-time compliance status',
              'Validation rule management',
              'Missing data detection',
              'Outlier identification',
              'Regulatory reporting'
            ]}
          />
        </TabsContent>

        {/* Audit Tab - Placeholder */}
        <TabsContent value="audit" className="mt-0">
          <PlaceholderTab
            icon={History}
            title="Audit Trail"
            description="Complete audit trail and change history for this project"
            features={[
              'User activity logs',
              'Data change tracking',
              'Template assignment history',
              'Export and download logs',
              'Compliance audit reports'
            ]}
          />
        </TabsContent>

        {/* Operators Tab - Placeholder */}
        <TabsContent value="operators" className="mt-0">
          <PlaceholderTab
            icon={Users}
            title="Operator Management"
            description="Manage operator assignments and permissions for this project"
            features={[
              'Operator assignment matrix',
              'Shift scheduling',
              'Permission management',
              'Training status tracking',
              'Performance analytics'
            ]}
          />
        </TabsContent>

        {/* Reports Tab - Placeholder */}
        <TabsContent value="reports" className="mt-0">
          <PlaceholderTab
            icon={BarChart3}
            title="Advanced Reports"
            description="Generate comprehensive reports and analytics for this project"
            features={[
              'Custom report builder',
              'Scheduled report delivery',
              'Multi-format exports (PDF, Excel, CSV)',
              'Data visualization dashboards',
              'Compliance reporting templates'
            ]}
          />
        </TabsContent>

        {/* Settings Tab - Placeholder */}
        <TabsContent value="settings" className="mt-0">
          <PlaceholderTab
            icon={Cog}
            title="Project Settings"
            description="Configure project-specific settings and preferences"
            features={[
              'Project metadata management',
              'Notification preferences',
              'Data retention policies',
              'Integration settings',
              'Backup and recovery options'
            ]}
          />
        </TabsContent>
      </ProjectTabs>
    </div>
  );
}

// Main component with Suspense wrapper
export default function ProjectPortalPage() {
  return (
    <Suspense fallback={
      <div className="min-h-screen bg-[#111111] text-white">
        <div className="h-24 bg-[#1E1E1E] border-b border-gray-800 animate-pulse" />
        <TabContentSkeleton />
      </div>
    }>
      <ProjectPortalContent />
    </Suspense>
  );
}