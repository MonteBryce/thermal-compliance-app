'use client';

import React, { Suspense } from 'react';
import { useSearchParams, useRouter, usePathname } from 'next/navigation';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Card, CardContent } from '@/components/ui/card';
import { 
  BarChart3, 
  FileText, 
  Download, 
  UserCheck, 
  Settings, 
  Shield, 
  History, 
  Users, 
  TrendingUp, 
  Cog,
  Eye,
  Activity,
  Database
} from 'lucide-react';
import { cn } from '@/lib/utils';

// Tab definitions with icons and metadata
export const TAB_DEFINITIONS = [
  { 
    value: 'overview', 
    label: 'Overview', 
    icon: BarChart3,
    description: 'Project summary and key metrics'
  },
  { 
    value: 'logs', 
    label: 'Logs', 
    icon: FileText,
    description: 'View and manage log entries'
  },
  { 
    value: 'exports', 
    label: 'Exports', 
    icon: Download,
    description: 'Export data and reports'
  },
  { 
    value: 'assign', 
    label: 'Assign', 
    icon: UserCheck,
    description: 'Assign templates and operators'
  },
  { 
    value: 'log-builder', 
    label: 'Log Builder', 
    icon: Settings,
    description: 'Build and customize log templates'
  },
  { 
    value: 'compliance', 
    label: 'Compliance', 
    icon: Shield,
    description: 'Compliance monitoring and validation'
  },
  { 
    value: 'audit', 
    label: 'Audit', 
    icon: History,
    description: 'Audit trail and change history'
  },
  { 
    value: 'operators', 
    label: 'Operators', 
    icon: Users,
    description: 'Manage operator assignments'
  },
  { 
    value: 'reports', 
    label: 'Reports', 
    icon: TrendingUp,
    description: 'Generate and view reports'
  },
  { 
    value: 'settings', 
    label: 'Settings', 
    icon: Cog,
    description: 'Project configuration and settings'
  }
] as const;

export type TabValue = typeof TAB_DEFINITIONS[number]['value'];

interface ProjectTabsProps {
  projectId: string;
  children: React.ReactNode;
  defaultTab?: TabValue;
}

function ProjectTabsContent({ projectId, children, defaultTab = 'overview' }: ProjectTabsProps) {
  const router = useRouter();
  const pathname = usePathname();
  const searchParams = useSearchParams();
  
  const currentTab = (searchParams.get('tab') as TabValue) || defaultTab;

  const handleTabChange = (value: string) => {
    const newSearchParams = new URLSearchParams(searchParams.toString());
    newSearchParams.set('tab', value);
    router.push(`${pathname}?${newSearchParams.toString()}`);
  };

  return (
    <div className="h-full flex flex-col">
      <Tabs value={currentTab} onValueChange={handleTabChange} className="flex-1 flex flex-col">
        {/* Sticky Tab Navigation */}
        <div className="sticky top-0 z-30 bg-[#111111] border-b border-gray-800">
          <div className="px-6 py-4">
            <TabsList className="grid w-full grid-cols-10 lg:grid-cols-10 bg-[#1E1E1E] border border-gray-800 h-auto p-1">
              {TAB_DEFINITIONS.map((tab) => {
                const Icon = tab.icon;
                return (
                  <TabsTrigger
                    key={tab.value}
                    value={tab.value}
                    className={cn(
                      "flex flex-col items-center gap-1 px-2 py-3 text-xs font-medium transition-all",
                      "data-[state=active]:bg-orange-600 data-[state=active]:text-white",
                      "data-[state=inactive]:text-gray-400 data-[state=inactive]:hover:text-gray-200",
                      "lg:flex-row lg:gap-2 lg:px-4 lg:text-sm"
                    )}
                    title={tab.description}
                  >
                    <Icon className="h-4 w-4 flex-shrink-0" />
                    <span className="truncate">{tab.label}</span>
                  </TabsTrigger>
                );
              })}
            </TabsList>
          </div>
        </div>

        {/* Tab Content Area */}
        <div className="flex-1 overflow-auto">
          {children}
        </div>
      </Tabs>
    </div>
  );
}

// Wrapper with Suspense boundary for useSearchParams
export function ProjectTabs(props: ProjectTabsProps) {
  return (
    <Suspense fallback={
      <div className="h-full flex flex-col">
        <div className="sticky top-0 z-30 bg-[#111111] border-b border-gray-800">
          <div className="px-6 py-4">
            <div className="h-16 bg-[#1E1E1E] border border-gray-800 rounded-lg animate-pulse" />
          </div>
        </div>
        <div className="flex-1 p-6">
          <div className="h-96 bg-[#1E1E1E] border border-gray-800 rounded-lg animate-pulse" />
        </div>
      </div>
    }>
      <ProjectTabsContent {...props} />
    </Suspense>
  );
}

// Loading skeleton for tab content
export function TabContentSkeleton() {
  return (
    <div className="p-6 space-y-6">
      <div className="h-8 bg-[#1E1E1E] rounded animate-pulse" />
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="h-64 bg-[#1E1E1E] rounded animate-pulse" />
        <div className="h-64 bg-[#1E1E1E] rounded animate-pulse" />
      </div>
      <div className="h-96 bg-[#1E1E1E] rounded animate-pulse" />
    </div>
  );
}

// Placeholder component for unimplemented tabs
interface PlaceholderTabProps {
  icon: React.ComponentType<{ className?: string }>;
  title: string;
  description: string;
  features?: string[];
  comingSoon?: boolean;
}

export function PlaceholderTab({ 
  icon: Icon, 
  title, 
  description, 
  features = [], 
  comingSoon = true 
}: PlaceholderTabProps) {
  return (
    <div className="p-6">
      <Card className="bg-[#1E1E1E] border-gray-800">
        <CardContent className="flex flex-col items-center justify-center py-16 text-center">
          <div className="w-16 h-16 rounded-lg bg-orange-600/20 flex items-center justify-center mb-6">
            <Icon className="h-8 w-8 text-orange-400" />
          </div>
          
          <h2 className="text-2xl font-bold text-white mb-2">{title}</h2>
          <p className="text-gray-400 mb-6 max-w-md">{description}</p>
          
          {features.length > 0 && (
            <div className="w-full max-w-md mb-6">
              <h3 className="text-sm font-medium text-gray-300 mb-3">Planned Features:</h3>
              <ul className="space-y-2 text-sm text-gray-400">
                {features.map((feature, index) => (
                  <li key={index} className="flex items-center gap-2">
                    <div className="w-1.5 h-1.5 bg-orange-400 rounded-full" />
                    {feature}
                  </li>
                ))}
              </ul>
            </div>
          )}
          
          {comingSoon && (
            <div className="px-4 py-2 bg-amber-600/20 border border-amber-600/30 rounded-lg">
              <span className="text-amber-400 font-medium text-sm">Coming Soon</span>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}

// Helper to get tab information
export function getTabInfo(tabValue: TabValue) {
  return TAB_DEFINITIONS.find(tab => tab.value === tabValue);
}

// Hook for accessing current tab state
export function useCurrentTab() {
  const searchParams = useSearchParams();
  const currentTab = (searchParams.get('tab') as TabValue) || 'overview';
  const tabInfo = getTabInfo(currentTab);
  
  return {
    currentTab,
    tabInfo,
    isValidTab: !!tabInfo
  };
}