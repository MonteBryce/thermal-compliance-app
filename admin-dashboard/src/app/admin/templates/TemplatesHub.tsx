'use client';

import React, { useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Badge } from '@/components/ui/badge';
import { 
  FileText, 
  Settings, 
  Library, 
  Building2, 
  PlusCircle, 
  Zap,
  Star,
  TrendingUp,
  Users,
  ArrowRight
} from 'lucide-react';
import { TemplatesListClient } from './TemplatesListClient';
import { TemplateLibrary } from './library/TemplateLibrary';
import { FacilityPresetsManager } from '../presets/FacilityPresetsManager';
import { LIBRARY_TEMPLATES } from '@/lib/logs/templates/library-seed';

export function TemplatesHub() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [activeTab, setActiveTab] = useState(searchParams.get('tab') || 'library');

  const handleTabChange = (value: string) => {
    setActiveTab(value);
    // Update URL without causing a page reload
    const newUrl = new URL(window.location.href);
    newUrl.searchParams.set('tab', value);
    window.history.pushState({}, '', newUrl.toString());
  };

  const popularTemplates = LIBRARY_TEMPLATES
    .sort((a, b) => b.popularity - a.popularity)
    .slice(0, 3);

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold text-white">Template Management</h1>
          <p className="text-gray-400 mt-1">
            Manage template library, create custom templates, and configure facility presets
          </p>
        </div>
        <div className="flex items-center gap-3">
          <Badge className="bg-green-600 text-white">
            {LIBRARY_TEMPLATES.length} Library Templates
          </Badge>
          <Button 
            onClick={() => router.push('/admin/templates/builder')}
            className="bg-orange-600 hover:bg-orange-700"
          >
            <PlusCircle className="w-4 h-4 mr-2" />
            Create Template
          </Button>
        </div>
      </div>

      {/* Quick Actions */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <Card 
          className="bg-gradient-to-br from-orange-900 to-orange-950 border-orange-500 cursor-pointer hover:from-orange-800 hover:to-orange-900 transition-all"
          onClick={() => router.push('/admin/templates/builder')}
        >
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <Settings className="w-10 h-10 text-orange-400" />
                <div>
                  <h3 className="text-lg font-bold text-white">Template Builder</h3>
                  <p className="text-orange-200 text-sm">Visual drag-drop editor</p>
                </div>
              </div>
              <ArrowRight className="w-5 h-5 text-orange-300" />
            </div>
          </CardContent>
        </Card>

        <Card 
          className="bg-gradient-to-br from-blue-900 to-blue-950 border-blue-500 cursor-pointer hover:from-blue-800 hover:to-blue-900 transition-all"
          onClick={() => handleTabChange('library')}
        >
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <Library className="w-10 h-10 text-blue-400" />
                <div>
                  <h3 className="text-lg font-bold text-white">Template Library</h3>
                  <p className="text-blue-200 text-sm">{LIBRARY_TEMPLATES.length} ready-to-use templates</p>
                </div>
              </div>
              <ArrowRight className="w-5 h-5 text-blue-300" />
            </div>
          </CardContent>
        </Card>

        <Card 
          className="bg-gradient-to-br from-green-900 to-green-950 border-green-500 cursor-pointer hover:from-green-800 hover:to-green-900 transition-all"
          onClick={() => handleTabChange('presets')}
        >
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <Building2 className="w-10 h-10 text-green-400" />
                <div>
                  <h3 className="text-lg font-bold text-white">Facility Presets</h3>
                  <p className="text-green-200 text-sm">Default configurations</p>
                </div>
              </div>
              <ArrowRight className="w-5 h-5 text-green-300" />
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Popular Templates Preview */}
      <div className="bg-[#1E1E1E] border border-gray-800 rounded-lg p-6">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <TrendingUp className="w-5 h-5 text-orange-400" />
            <h2 className="text-xl font-bold text-white">Most Popular Templates</h2>
          </div>
          <Button 
            variant="outline" 
            size="sm"
            onClick={() => handleTabChange('library')}
            className="border-gray-600 text-gray-300 hover:bg-gray-700"
          >
            View All Library
          </Button>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {popularTemplates.map(template => (
            <Card key={template.id} className="bg-[#2A2A2A] border-gray-700 hover:border-gray-600 transition-colors">
              <CardContent className="p-4">
                <div className="flex items-center justify-between mb-2">
                  <h3 className="font-medium text-white text-sm">{template.name}</h3>
                  <div className="flex items-center gap-1 text-yellow-400">
                    <Star className="w-3 h-3 fill-current" />
                    <span className="text-xs">{template.popularity}</span>
                  </div>
                </div>
                <p className="text-gray-400 text-xs mb-3 line-clamp-2">{template.description}</p>
                <div className="flex items-center justify-between">
                  <Badge className="bg-blue-600 text-white text-xs">
                    {template.gasType.toUpperCase()}
                  </Badge>
                  <div className="flex gap-1">
                    <Button 
                      size="sm" 
                      variant="outline"
                      className="h-6 px-2 text-xs border-gray-600 text-gray-300 hover:bg-gray-700"
                      onClick={() => router.push(`/admin/jobs/assign?templateId=${template.id}&sourceType=library`)}
                    >
                      <Users className="w-3 h-3 mr-1" />
                      Assign
                    </Button>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      </div>

      {/* Main Content Tabs */}
      <Tabs value={activeTab} onValueChange={handleTabChange} className="w-full">
        <TabsList className="grid w-full grid-cols-3 bg-[#2A2A2A]">
          <TabsTrigger 
            value="library" 
            className="data-[state=active]:bg-blue-600 data-[state=active]:text-white"
          >
            <Library className="w-4 h-4 mr-2" />
            Template Library
          </TabsTrigger>
          <TabsTrigger 
            value="custom" 
            className="data-[state=active]:bg-orange-600 data-[state=active]:text-white"
          >
            <FileText className="w-4 h-4 mr-2" />
            Custom Templates
          </TabsTrigger>
          <TabsTrigger 
            value="presets" 
            className="data-[state=active]:bg-green-600 data-[state=active]:text-white"
          >
            <Building2 className="w-4 h-4 mr-2" />
            Facility Presets
          </TabsTrigger>
        </TabsList>

        <TabsContent value="library" className="mt-6">
          <TemplateLibrary />
        </TabsContent>

        <TabsContent value="custom" className="mt-6">
          <TemplatesListClient />
        </TabsContent>

        <TabsContent value="presets" className="mt-6">
          <FacilityPresetsManager />
        </TabsContent>
      </Tabs>
    </div>
  );
}