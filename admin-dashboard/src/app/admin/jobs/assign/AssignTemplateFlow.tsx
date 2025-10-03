'use client';

import React, { useState, useMemo } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { 
  Search, 
  Filter, 
  Copy, 
  Eye, 
  Star, 
  ArrowLeft, 
  PlusCircle,
  CheckCircle,
  Pin,
  Zap,
  Settings,
  FileText,
  Building2,
  TrendingUp
} from 'lucide-react';
import { 
  LIBRARY_TEMPLATES, 
  TEMPLATE_TAGS, 
  getTemplatesByTags, 
  getTemplatesByCategory, 
  searchTemplates,
  LibraryTemplate
} from '@/lib/logs/templates/library-seed';
import { VersionedTemplateService } from '@/lib/logs/templates/versioned-service';
import { ExcelPreview } from '@/components/excel/ExcelPreview';

const CATEGORY_ICONS = {
  thermal: 'Flame',
  environmental: 'Beaker',
  safety: 'Shield',
  operations: 'Gauge',
};

const CATEGORY_COLORS = {
  thermal: 'bg-orange-600',
  environmental: 'bg-green-600',
  safety: 'bg-red-600',
  operations: 'bg-blue-600',
};

interface JobInfo {
  id: string;
  name: string;
  location?: string;
  clientName?: string;
}

export function AssignTemplateFlow() {
  const router = useRouter();
  const searchParams = useSearchParams();
  
  // Parse URL parameters
  const templateId = searchParams.get('templateId');
  const sourceType = searchParams.get('sourceType');
  const jobId = searchParams.get('jobId');
  
  // State management
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedTags, setSelectedTags] = useState<string[]>([]);
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [sortBy, setSortBy] = useState<'popularity' | 'recent' | 'name'>('popularity');
  const [activeTab, setActiveTab] = useState<'library' | 'custom'>('library');
  const [previewTemplate, setPreviewTemplate] = useState<LibraryTemplate | null>(null);
  const [assigningTemplate, setAssigningTemplate] = useState<string | null>(null);
  
  // Mock job data - in real app, fetch from Firestore
  const jobInfo: JobInfo = {
    id: jobId || 'PROJ-001',
    name: 'Marathon GBR Platform A Degas',
    location: 'Gulf of Mexico',
    clientName: 'Marathon Oil',
  };

  // Filter and sort templates
  const filteredTemplates = useMemo(() => {
    let templates = LIBRARY_TEMPLATES;

    // Apply search
    if (searchQuery) {
      templates = searchTemplates(searchQuery);
    }

    // Apply category filter
    if (selectedCategory !== 'all') {
      templates = getTemplatesByCategory(selectedCategory);
    }

    // Apply tag filter
    if (selectedTags.length > 0) {
      templates = getTemplatesByTags(selectedTags);
    }

    // Apply sorting
    templates.sort((a, b) => {
      switch (sortBy) {
        case 'popularity':
          return b.popularity - a.popularity;
        case 'recent':
          return new Date(b.lastUpdated).getTime() - new Date(a.lastUpdated).getTime();
        case 'name':
          return a.name.localeCompare(b.name);
        default:
          return 0;
      }
    });

    return templates;
  }, [searchQuery, selectedTags, selectedCategory, sortBy]);

  const handleTagToggle = (tagId: string) => {
    setSelectedTags(prev => 
      prev.includes(tagId) 
        ? prev.filter(id => id !== tagId)
        : [...prev, tagId]
    );
  };

  const handleDuplicate = (template: LibraryTemplate) => {
    // Navigate to template builder with pre-filled data
    const params = new URLSearchParams({
      mode: 'duplicate',
      sourceId: template.id,
      sourceType: 'library',
      jobId: jobInfo.id,
    });
    router.push(`/admin/templates/builder?${params.toString()}`);
  };

  const handleAssignDirect = async (template: LibraryTemplate) => {
    setAssigningTemplate(template.id);
    try {
      // Pin template to job - in real app, make API call
      console.log('Assigning template', template.id, 'to job', jobInfo.id);
      
      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 1000));
      
      // Navigate back to job management or dashboard
      router.push(`/admin/${jobInfo.id}?assigned=${template.id}`);
    } catch (error) {
      console.error('Failed to assign template:', error);
    } finally {
      setAssigningTemplate(null);
    }
  };

  const getTagColor = (tagId: string) => {
    const tag = TEMPLATE_TAGS.find(t => t.id === tagId);
    return tag?.color || 'gray';
  };

  const popularTemplates = LIBRARY_TEMPLATES
    .sort((a, b) => b.popularity - a.popularity)
    .slice(0, 3);

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4 mb-6">
        <Button 
          variant="outline" 
          onClick={() => router.back()}
          className="border-gray-600 text-gray-300 hover:bg-gray-700"
        >
          <ArrowLeft className="w-4 h-4 mr-2" />
          Back
        </Button>
        <div className="flex-1">
          <h1 className="text-3xl font-bold text-white">Assign Template</h1>
          <div className="flex items-center gap-4 mt-2">
            <div className="flex items-center gap-2 text-gray-400">
              <Building2 className="w-4 h-4" />
              <span>{jobInfo.name}</span>
            </div>
            {jobInfo.location && (
              <div className="text-gray-500">
                📍 {jobInfo.location}
              </div>
            )}
          </div>
        </div>
      </div>

      {/* Template Source Tabs */}
      <Tabs value={activeTab} onValueChange={(value: any) => setActiveTab(value)} className="w-full">
        <TabsList className="grid w-full grid-cols-2 bg-[#2A2A2A]">
          <TabsTrigger value="library" className="data-[state=active]:bg-orange-600">
            <FileText className="w-4 h-4 mr-2" />
            Template Library ({LIBRARY_TEMPLATES.length})
          </TabsTrigger>
          <TabsTrigger value="custom" className="data-[state=active]:bg-blue-600">
            <PlusCircle className="w-4 h-4 mr-2" />
            Create Custom
          </TabsTrigger>
        </TabsList>

        {/* Library Templates Tab */}
        <TabsContent value="library" className="space-y-6">
          {/* Quick Actions */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <Card className="bg-gradient-to-br from-orange-900 to-orange-950 border-orange-500">
              <CardContent className="p-4">
                <div className="flex items-center gap-3">
                  <TrendingUp className="w-8 h-8 text-orange-400" />
                  <div>
                    <h3 className="font-medium text-white">Most Popular</h3>
                    <p className="text-orange-200 text-sm">Top-rated templates</p>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card className="bg-gradient-to-br from-blue-900 to-blue-950 border-blue-500">
              <CardContent className="p-4">
                <div className="flex items-center gap-3">
                  <Zap className="w-8 h-8 text-blue-400" />
                  <div>
                    <h3 className="font-medium text-white">Quick Start</h3>
                    <p className="text-blue-200 text-sm">Ready-to-use configs</p>
                  </div>
                </div>
              </CardContent>
            </Card>

            <Card className="bg-gradient-to-br from-green-900 to-green-950 border-green-500">
              <CardContent className="p-4">
                <div className="flex items-center gap-3">
                  <CheckCircle className="w-8 h-8 text-green-400" />
                  <div>
                    <h3 className="font-medium text-white">Validated</h3>
                    <p className="text-green-200 text-sm">Field-tested templates</p>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Filters and Search */}
          <div className="space-y-4">
            {/* Search and Controls */}
            <div className="flex gap-4 items-center">
              <div className="relative flex-1 max-w-md">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
                <Input
                  placeholder="Search templates, descriptions, or tags..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="pl-10 bg-[#2A2A2A] border-gray-600 text-white"
                />
              </div>
              
              <Select value={selectedCategory} onValueChange={setSelectedCategory}>
                <SelectTrigger className="w-48 bg-[#2A2A2A] border-gray-600 text-white">
                  <SelectValue placeholder="All Categories" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All Categories</SelectItem>
                  <SelectItem value="thermal">Thermal</SelectItem>
                  <SelectItem value="environmental">Environmental</SelectItem>
                  <SelectItem value="safety">Safety</SelectItem>
                  <SelectItem value="operations">Operations</SelectItem>
                </SelectContent>
              </Select>

              <Select value={sortBy} onValueChange={(value: any) => setSortBy(value)}>
                <SelectTrigger className="w-48 bg-[#2A2A2A] border-gray-600 text-white">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="popularity">Most Popular</SelectItem>
                  <SelectItem value="recent">Recently Updated</SelectItem>
                  <SelectItem value="name">Name A-Z</SelectItem>
                </SelectContent>
              </Select>
            </div>

            {/* Tag Filters */}
            <div className="space-y-2">
              <div className="flex items-center gap-2">
                <Filter className="w-4 h-4 text-gray-400" />
                <span className="text-sm text-gray-400">Filter by tags:</span>
                {selectedTags.length > 0 && (
                  <Button 
                    variant="ghost" 
                    size="sm" 
                    onClick={() => setSelectedTags([])}
                    className="text-gray-400 hover:text-white"
                  >
                    Clear all
                  </Button>
                )}
              </div>
              <div className="flex flex-wrap gap-2">
                {TEMPLATE_TAGS.map(tag => (
                  <Button
                    key={tag.id}
                    variant={selectedTags.includes(tag.id) ? 'default' : 'outline'}
                    size="sm"
                    onClick={() => handleTagToggle(tag.id)}
                    className={`${
                      selectedTags.includes(tag.id)
                        ? `bg-${tag.color}-600 text-white`
                        : 'border-gray-600 text-gray-300 hover:bg-gray-700'
                    }`}
                  >
                    {tag.label}
                  </Button>
                ))}
              </div>
            </div>
          </div>

          {/* Results Summary */}
          <div className="flex justify-between items-center">
            <div className="text-sm text-gray-400">
              Showing {filteredTemplates.length} of {LIBRARY_TEMPLATES.length} templates
            </div>
          </div>

          {/* Templates Grid */}
          {filteredTemplates.length === 0 ? (
            <Card className="bg-[#1E1E1E] border border-gray-800">
              <CardContent className="text-center py-12">
                <FileText className="w-12 h-12 text-gray-400 mx-auto mb-4" />
                <h3 className="text-lg font-medium text-white mb-2">No templates found</h3>
                <p className="text-gray-400 mb-4">
                  Try adjusting your search or filter criteria.
                </p>
                <Button 
                  onClick={() => {
                    setSearchQuery('');
                    setSelectedTags([]);
                    setSelectedCategory('all');
                  }}
                  variant="outline"
                  className="border-gray-600 text-gray-300 hover:bg-gray-700"
                >
                  Clear Filters
                </Button>
              </CardContent>
            </Card>
          ) : (
            <div className="grid grid-cols-1 lg:grid-cols-2 xl:grid-cols-3 gap-6">
              {filteredTemplates.map(template => {
                const isAssigning = assigningTemplate === template.id;
                
                return (
                  <Card 
                    key={template.id} 
                    className="bg-[#1E1E1E] border border-gray-800 hover:border-gray-600 transition-all group"
                  >
                    <CardHeader className="pb-3">
                      <div className="flex items-start justify-between">
                        <div className="flex items-center gap-3">
                          <div className={`p-2 rounded-lg ${CATEGORY_COLORS[template.category]} text-white`}>
                            <FileText className="w-5 h-5" />
                          </div>
                          <div>
                            <CardTitle className="text-white text-lg group-hover:text-orange-400 transition-colors">
                              {template.name}
                            </CardTitle>
                            <div className="flex items-center gap-2 mt-1">
                              <Badge className="bg-blue-600 text-white text-xs">
                                {template.gasType.toUpperCase()}
                              </Badge>
                              <div className="flex items-center gap-1 text-yellow-400">
                                <Star className="w-3 h-3 fill-current" />
                                <span className="text-xs">{template.popularity}</span>
                              </div>
                            </div>
                          </div>
                        </div>
                      </div>
                    </CardHeader>
                    
                    <CardContent className="space-y-4">
                      <CardDescription className="text-gray-400">
                        {template.description}
                      </CardDescription>
                      
                      {/* Tags */}
                      <div className="flex flex-wrap gap-1">
                        {template.tags.slice(0, 4).map(tag => {
                          const tagData = TEMPLATE_TAGS.find(t => t.label === tag);
                          return (
                            <Badge 
                              key={tag} 
                              variant="outline" 
                              className={`text-xs border-${tagData?.color || 'gray'}-500 text-${tagData?.color || 'gray'}-300`}
                            >
                              {tag}
                            </Badge>
                          );
                        })}
                        {template.tags.length > 4 && (
                          <Badge variant="outline" className="text-xs text-gray-400">
                            +{template.tags.length - 4} more
                          </Badge>
                        )}
                      </div>

                      {/* Metrics */}
                      <div className="grid grid-cols-3 gap-3 text-center">
                        <div>
                          <div className="text-lg font-bold text-white">
                            {template.version.fields.length}
                          </div>
                          <div className="text-xs text-gray-400">Fields</div>
                        </div>
                        <div>
                          <div className="text-lg font-bold text-orange-400">
                            {Object.keys(template.version.targets).length}
                          </div>
                          <div className="text-xs text-gray-400">Targets</div>
                        </div>
                        <div>
                          <div className="text-lg font-bold text-blue-400">
                            {template.facilityType.length}
                          </div>
                          <div className="text-xs text-gray-400">Facilities</div>
                        </div>
                      </div>

                      {/* Actions */}
                      <div className="flex gap-2">
                        <Dialog>
                          <DialogTrigger asChild>
                            <Button 
                              variant="outline" 
                              size="sm"
                              className="flex-1 border-gray-600 text-gray-300 hover:bg-gray-700"
                              onClick={() => setPreviewTemplate(template)}
                            >
                              <Eye className="w-4 h-4 mr-2" />
                              Preview
                            </Button>
                          </DialogTrigger>
                          <DialogContent className="max-w-6xl max-h-[90vh] overflow-hidden">
                            <DialogHeader>
                              <DialogTitle className="text-white">{template.name}</DialogTitle>
                              <DialogDescription className="text-gray-400">
                                Live Excel preview - ready for assignment to {jobInfo.name}
                              </DialogDescription>
                            </DialogHeader>
                            
                            <div className="space-y-4">
                              {/* Assignment Action */}
                              <div className="bg-gradient-to-r from-orange-900 to-orange-950 border border-orange-500 rounded-lg p-4">
                                <div className="flex items-center justify-between">
                                  <div>
                                    <h4 className="text-white font-medium">Ready for Assignment</h4>
                                    <p className="text-orange-200 text-sm">This template will be assigned to {jobInfo.name}</p>
                                  </div>
                                  <Button 
                                    onClick={() => handleAssignDirect(template)}
                                    disabled={isAssigning}
                                    className="bg-orange-600 hover:bg-orange-700"
                                  >
                                    {isAssigning ? 'Assigning...' : 'Assign Now'}
                                  </Button>
                                </div>
                              </div>

                              {/* Template Details */}
                              <div className="grid grid-cols-2 gap-4">
                                <div className="bg-[#2A2A2A] rounded-lg p-4">
                                  <h4 className="text-white font-medium mb-2">Template Details</h4>
                                  <div className="space-y-2 text-sm">
                                    <div className="flex justify-between">
                                      <span className="text-gray-400">Gas Type:</span>
                                      <Badge className="bg-blue-600 text-white">
                                        {template.gasType.toUpperCase()}
                                      </Badge>
                                    </div>
                                    <div className="flex justify-between">
                                      <span className="text-gray-400">Fields:</span>
                                      <span className="text-white">{template.version.fields.length}</span>
                                    </div>
                                    <div className="flex justify-between">
                                      <span className="text-gray-400">Popularity:</span>
                                      <div className="flex items-center gap-1 text-yellow-400">
                                        <Star className="w-3 h-3 fill-current" />
                                        <span className="text-white">{template.popularity}</span>
                                      </div>
                                    </div>
                                  </div>
                                </div>
                                
                                <div className="bg-[#2A2A2A] rounded-lg p-4">
                                  <h4 className="text-white font-medium mb-2">Active Features</h4>
                                  <div className="flex flex-wrap gap-1">
                                    {Object.entries(template.version.toggles)
                                      .filter(([_, enabled]) => enabled)
                                      .map(([key]) => (
                                        <Badge key={key} variant="outline" className="text-xs border-green-500 text-green-300">
                                          {key.replace(/([A-Z])/g, ' $1').replace(/^./, str => str.toUpperCase())}
                                        </Badge>
                                      ))}
                                    {Object.entries(template.version.toggles).filter(([_, enabled]) => enabled).length === 0 && (
                                      <span className="text-gray-400 text-sm">No special features enabled</span>
                                    )}
                                  </div>
                                </div>
                              </div>

                              {/* Excel Preview */}
                              <ExcelPreview
                                excelPath={template.version.excelTemplatePath}
                                operationRange="B12:N28"
                                gasType={template.gasType}
                                toggles={template.version.toggles}
                                targets={template.version.targets}
                                height={350}
                                className="bg-[#2A2A2A] border-gray-600"
                              />
                            </div>
                          </DialogContent>
                        </Dialog>
                        
                        <Button 
                          size="sm"
                          onClick={() => handleDuplicate(template)}
                          className="flex-1 bg-blue-600 hover:bg-blue-700"
                        >
                          <Copy className="w-4 h-4 mr-2" />
                          Duplicate
                        </Button>
                        
                        <Button 
                          size="sm"
                          onClick={() => handleAssignDirect(template)}
                          disabled={isAssigning}
                          className="flex-1 bg-orange-600 hover:bg-orange-700"
                        >
                          {isAssigning ? (
                            <>Assigning...</>
                          ) : (
                            <>
                              <Pin className="w-4 h-4 mr-2" />
                              Assign
                            </>
                          )}
                        </Button>
                      </div>
                    </CardContent>
                  </Card>
                );
              })}
            </div>
          )}
        </TabsContent>

        {/* Custom Template Tab */}
        <TabsContent value="custom" className="space-y-6">
          <Card className="bg-[#1E1E1E] border border-gray-800">
            <CardContent className="text-center py-12">
              <Settings className="w-12 h-12 text-gray-400 mx-auto mb-4" />
              <h3 className="text-lg font-medium text-white mb-2">Create Custom Template</h3>
              <p className="text-gray-400 mb-4">
                Build a new template from scratch using the visual builder.
              </p>
              <Button 
                onClick={() => router.push(`/admin/templates/builder?jobId=${jobInfo.id}`)}
                className="bg-orange-600 hover:bg-orange-700"
              >
                <PlusCircle className="w-4 h-4 mr-2" />
                Open Template Builder
              </Button>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}