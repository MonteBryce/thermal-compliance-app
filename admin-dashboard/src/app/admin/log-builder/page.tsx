'use client';

import { useState, useEffect, lazy, Suspense } from 'react';
import { useRouter } from 'next/navigation';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { LazyWrapper } from '@/components/lazy/lazy-wrapper';

const Table = lazy(() => import('@/components/ui/table').then(mod => ({ default: mod.Table })));
const TableBody = lazy(() => import('@/components/ui/table').then(mod => ({ default: mod.TableBody })));
const TableCell = lazy(() => import('@/components/ui/table').then(mod => ({ default: mod.TableCell })));
const TableHead = lazy(() => import('@/components/ui/table').then(mod => ({ default: mod.TableHead })));
const TableHeader = lazy(() => import('@/components/ui/table').then(mod => ({ default: mod.TableHeader })));
const TableRow = lazy(() => import('@/components/ui/table').then(mod => ({ default: mod.TableRow })));

const Dialog = lazy(() => import('@/components/ui/dialog').then(mod => ({ default: mod.Dialog })));
const DialogContent = lazy(() => import('@/components/ui/dialog').then(mod => ({ default: mod.DialogContent })));
const DialogDescription = lazy(() => import('@/components/ui/dialog').then(mod => ({ default: mod.DialogDescription })));
const DialogFooter = lazy(() => import('@/components/ui/dialog').then(mod => ({ default: mod.DialogFooter })));
const DialogHeader = lazy(() => import('@/components/ui/dialog').then(mod => ({ default: mod.DialogHeader })));
const DialogTitle = lazy(() => import('@/components/ui/dialog').then(mod => ({ default: mod.DialogTitle })));
const DialogTrigger = lazy(() => import('@/components/ui/dialog').then(mod => ({ default: mod.DialogTrigger })));

const DropdownMenu = lazy(() => import('@/components/ui/dropdown-menu').then(mod => ({ default: mod.DropdownMenu })));
const DropdownMenuContent = lazy(() => import('@/components/ui/dropdown-menu').then(mod => ({ default: mod.DropdownMenuContent })));
const DropdownMenuItem = lazy(() => import('@/components/ui/dropdown-menu').then(mod => ({ default: mod.DropdownMenuItem })));
const DropdownMenuTrigger = lazy(() => import('@/components/ui/dropdown-menu').then(mod => ({ default: mod.DropdownMenuTrigger })));

const Select = lazy(() => import('@/components/ui/select').then(mod => ({ default: mod.Select })));
const SelectContent = lazy(() => import('@/components/ui/select').then(mod => ({ default: mod.SelectContent })));
const SelectItem = lazy(() => import('@/components/ui/select').then(mod => ({ default: mod.SelectItem })));
const SelectTrigger = lazy(() => import('@/components/ui/select').then(mod => ({ default: mod.SelectTrigger })));
const SelectValue = lazy(() => import('@/components/ui/select').then(mod => ({ default: mod.SelectValue })));

const Label = lazy(() => import('@/components/ui/label').then(mod => ({ default: mod.Label })));

import {
  Plus,
  Search,
  MoreVertical,
  Edit,
  Eye,
  History,
  Copy,
  Archive,
  FileText,
  RefreshCw,
} from 'lucide-react';
import { LogTemplate } from '@/lib/types/logbuilder';
import { TemplateService } from '@/lib/firestore/templates';
import { formatDistanceToNow } from 'date-fns';

const LOG_TYPES = [
  { value: 'methane_hourly', label: 'Methane Hourly' },
  { value: 'benzene_12hr', label: 'Benzene 12-Hour' },
  { value: 'combined_monitoring', label: 'Combined Monitoring' },
  { value: 'thermal_oxidizer', label: 'Thermal Oxidizer' },
  { value: 'custom', label: 'Custom' },
];

export default function LogBuilderPage() {
  const router = useRouter();
  const [templates, setTemplates] = useState<LogTemplate[]>([]);
  const [filteredTemplates, setFilteredTemplates] = useState<LogTemplate[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [loading, setLoading] = useState(true);
  const [showCreateDialog, setShowCreateDialog] = useState(false);
  const [newTemplateName, setNewTemplateName] = useState('');
  const [newTemplateLogType, setNewTemplateLogType] = useState('');

  const templateService = new TemplateService();

  useEffect(() => {
    loadTemplates();
  }, []);

  useEffect(() => {
    filterTemplates();
  }, [templates, searchTerm, statusFilter]);

  const loadTemplates = async () => {
    try {
      setLoading(true);
      const templatesData = await templateService.getTemplates();
      setTemplates(templatesData);
    } catch (error) {
      console.error('Error loading templates:', error);
      
      // Fallback to mock data for testing Variable Palette
      const mockTemplates: LogTemplate[] = [
        {
          id: 'template-1',
          name: 'Hourly Thermal Oxidizer Log',
          logType: 'thermal_hourly',
          status: 'published',
          latestVersion: 1,
          createdBy: 'admin@thermallog.com',
          createdAt: { toDate: () => new Date() } as any,
          updatedAt: { toDate: () => new Date() } as any,
          draftSchema: {
            fields: [
              {
                id: 'field-1',
                key: 'jobNumber',
                label: 'Job Number',
                type: 'text',
                required: true,
                validation: { maxLength: 20 },
              },
              {
                id: 'field-2',
                key: 'temperatureReading',
                label: 'Temperature (°F)',
                type: 'number',
                unit: '°F',
                required: true,
                validation: { min: 32, max: 2000 },
              },
            ],
            layout: [
              {
                id: 'section-1',
                title: 'Job Information',
                rows: [
                  {
                    id: 'row-1',
                    columns: [
                      { fieldId: 'field-1', width: 6 },
                      { fieldId: 'field-2', width: 6 },
                    ],
                  },
                ],
              },
            ],
            meta: {
              description: 'Standard hourly thermal oxidizer monitoring log',
              hourFormat: '24h',
            },
          },
        },
        {
          id: 'template-2',
          name: 'Daily Maintenance Log',
          logType: 'thermal_maintenance',
          status: 'draft',
          latestVersion: 0,
          createdBy: 'admin@thermallog.com',
          createdAt: { toDate: () => new Date() } as any,
          updatedAt: { toDate: () => new Date() } as any,
          draftSchema: {
            fields: [
              {
                id: 'field-1',
                key: 'equipmentId',
                label: 'Equipment ID',
                type: 'text',
                required: true,
              },
              {
                id: 'field-2',
                key: 'complianceStatus',
                label: 'Compliance Status',
                type: 'select',
                required: true,
                options: [
                  { label: 'Compliant', value: 'compliant' },
                  { label: 'Non-Compliant', value: 'non_compliant' },
                  { label: 'Under Review', value: 'under_review' },
                ],
              },
            ],
            layout: [
              {
                id: 'section-1',
                title: 'Equipment Information',
                rows: [
                  {
                    id: 'row-1',
                    columns: [
                      { fieldId: 'field-1', width: 6 },
                      { fieldId: 'field-2', width: 6 },
                    ],
                  },
                ],
              },
            ],
            meta: {
              description: 'Daily maintenance and compliance check log',
            },
          },
        },
        {
          id: 'template-3',
          name: 'Weekly Thermal Summary',
          logType: 'thermal_weekly',
          status: 'published',
          latestVersion: 2,
          createdBy: 'admin@thermallog.com',
          createdAt: { toDate: () => new Date() } as any,
          updatedAt: { toDate: () => new Date() } as any,
          draftSchema: {
            fields: [
              {
                id: 'field-1',
                key: 'averageTemp',
                label: 'Average Temperature (°F)',
                type: 'number',
                unit: '°F',
                required: true,
              },
              {
                id: 'field-2',
                key: 'flowRate',
                label: 'Average Flow Rate (CFM)',
                type: 'number',
                unit: 'CFM',
                required: true,
              },
            ],
            layout: [
              {
                id: 'section-1',
                title: 'Weekly Summary',
                rows: [
                  {
                    id: 'row-1',
                    columns: [
                      { fieldId: 'field-1', width: 6 },
                      { fieldId: 'field-2', width: 6 },
                    ],
                  },
                ],
              },
            ],
            meta: {
              description: 'Weekly thermal performance summary report',
            },
          },
        },
      ];
      
      setTemplates(mockTemplates);
      console.log('✅ Loaded mock templates for testing Variable Palette');
    } finally {
      setLoading(false);
    }
  };

  const filterTemplates = () => {
    let filtered = templates;

    // Filter by search term
    if (searchTerm) {
      const term = searchTerm.toLowerCase();
      filtered = filtered.filter(
        template =>
          template.name.toLowerCase().includes(term) ||
          template.logType.toLowerCase().includes(term)
      );
    }

    // Filter by status
    if (statusFilter !== 'all') {
      filtered = filtered.filter(template => template.status === statusFilter);
    }

    setFilteredTemplates(filtered);
  };

  const handleCreateTemplate = async () => {
    if (!newTemplateName || !newTemplateLogType) return;

    try {
      const templateId = await templateService.createTemplate(
        newTemplateName,
        newTemplateLogType,
        'current-user'
      );
      
      setShowCreateDialog(false);
      setNewTemplateName('');
      setNewTemplateLogType('');
      
      router.push(`/admin/log-builder/${templateId}/edit`);
    } catch (error) {
      console.error('Error creating template:', error);
    }
  };

  const handleDuplicateTemplate = async (template: LogTemplate) => {
    try {
      const newName = `${template.name} (Copy)`;
      const templateId = await templateService.duplicateTemplate(
        template.id,
        newName,
        'current-user'
      );
      
      await loadTemplates();
      router.push(`/admin/log-builder/${templateId}/edit`);
    } catch (error) {
      console.error('Error duplicating template:', error);
    }
  };

  const handleArchiveTemplate = async (templateId: string) => {
    try {
      await templateService.archiveTemplate(templateId);
      await loadTemplates();
    } catch (error) {
      console.error('Error archiving template:', error);
    }
  };

  const getStatusBadge = (status: LogTemplate['status']) => {
    switch (status) {
      case 'draft':
        return <Badge className="bg-amber-600 text-white border-0">Draft</Badge>;
      case 'published':
        return <Badge className="bg-green-600 text-white border-0">Published</Badge>;
      case 'archived':
        return <Badge className="border-gray-600 text-gray-400">Archived</Badge>;
      default:
        return <Badge className="border-gray-600 text-gray-400">{status}</Badge>;
    }
  };

  const getLogTypeLabel = (logType: string) => {
    const type = LOG_TYPES.find(t => t.value === logType);
    return type?.label || logType;
  };

  return (
    <div className="min-h-screen bg-[#111111] text-white">
      {/* Header Bar */}
      <div className="bg-[#1E1E1E] border-b border-gray-800 px-6 py-4">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-semibold text-white">Template Builder</h1>
            <p className="text-gray-400 text-sm">
              Create and manage operator form templates
            </p>
          </div>
          <div className="flex gap-2">
            <Button variant="outline" onClick={loadTemplates} disabled={loading} className="border-gray-600 text-gray-300 hover:bg-gray-700">
              <RefreshCw className={`h-4 w-4 mr-2 ${loading ? 'animate-spin' : ''}`} />
              Refresh
            </Button>
            <LazyWrapper>
              <Dialog open={showCreateDialog} onOpenChange={setShowCreateDialog}>
                <DialogTrigger asChild>
                  <Button className="bg-blue-600 hover:bg-blue-700 text-white border-0">
                    <Plus className="h-4 w-4 mr-2" />
                    New Template
                  </Button>
                </DialogTrigger>
                <DialogContent className="bg-[#1E1E1E] border-gray-800">
                <DialogHeader>
                  <DialogTitle className="text-white">Create New Template</DialogTitle>
                  <DialogDescription className="text-gray-400">
                    Create a new form template for operators to fill out
                  </DialogDescription>
                </DialogHeader>
                <div className="space-y-4">
                  <div>
                    <Label htmlFor="template-name" className="text-gray-300">Template Name</Label>
                    <Input
                      id="template-name"
                      value={newTemplateName}
                      onChange={(e) => setNewTemplateName(e.target.value)}
                      placeholder="Enter template name"
                      className="bg-gray-800 border-gray-600 text-white"
                    />
                  </div>
                  <div>
                    <Label htmlFor="log-type" className="text-gray-300">Log Type</Label>
                    <Select value={newTemplateLogType} onValueChange={setNewTemplateLogType}>
                      <SelectTrigger className="bg-gray-800 border-gray-600 text-white">
                        <SelectValue placeholder="Select log type" />
                      </SelectTrigger>
                      <SelectContent className="bg-[#1E1E1E] border-gray-800">
                        {LOG_TYPES.map((type) => (
                          <SelectItem key={type.value} value={type.value} className="text-white hover:bg-gray-700">
                            {type.label}
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </div>
                </div>
                <DialogFooter>
                  <Button
                    variant="outline"
                    onClick={() => setShowCreateDialog(false)}
                    className="border-gray-600 text-gray-300 hover:bg-gray-700"
                  >
                    Cancel
                  </Button>
                  <Button
                    onClick={handleCreateTemplate}
                    disabled={!newTemplateName || !newTemplateLogType}
                    className="bg-blue-600 hover:bg-blue-700 text-white border-0"
                  >
                    Create Template
                  </Button>
                </DialogFooter>
              </DialogContent>
              </Dialog>
            </LazyWrapper>
          </div>
        </div>
      </div>

      <div className="px-6 py-6 space-y-6">
        {/* Filters */}
        <Card className="bg-[#1E1E1E] border-gray-800">
          <CardContent className="pt-6">
            <div className="flex gap-4">
              <div className="flex-1">
                <div className="relative">
                  <Search className="absolute left-2 top-2.5 h-4 w-4 text-gray-400" />
                  <Input
                    placeholder="Search templates..."
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                    className="pl-8 bg-gray-800 border-gray-600 text-white"
                  />
                </div>
              </div>
              <Select value={statusFilter} onValueChange={setStatusFilter}>
                <SelectTrigger className="w-40 bg-gray-800 border-gray-600 text-white">
                  <SelectValue placeholder="Filter by status" />
                </SelectTrigger>
                <SelectContent className="bg-[#1E1E1E] border-gray-800">
                  <SelectItem value="all" className="text-white hover:bg-gray-700">All Status</SelectItem>
                  <SelectItem value="draft" className="text-white hover:bg-gray-700">Draft</SelectItem>
                  <SelectItem value="published" className="text-white hover:bg-gray-700">Published</SelectItem>
                  <SelectItem value="archived" className="text-white hover:bg-gray-700">Archived</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </CardContent>
        </Card>

        {/* Templates Table */}
        <Card className="bg-[#1E1E1E] border-gray-800">
          <CardHeader>
            <CardTitle className="flex items-center gap-2 text-white">
              <FileText className="h-5 w-5" />
              Templates
              <Badge className="bg-gray-700 text-gray-300">{filteredTemplates.length}</Badge>
            </CardTitle>
          </CardHeader>
          <CardContent>
            <LazyWrapper>
              <Table>
                <TableHeader>
                  <TableRow className="border-gray-700 hover:bg-gray-800/50">
                    <TableHead className="text-gray-300">Name</TableHead>
                    <TableHead className="text-gray-300">Log Type</TableHead>
                    <TableHead className="text-gray-300">Status</TableHead>
                    <TableHead className="text-gray-300">Version</TableHead>
                    <TableHead className="text-gray-300">Updated</TableHead>
                    <TableHead className="text-gray-300">Created By</TableHead>
                    <TableHead className="w-20 text-gray-300">Actions</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                {loading ? (
                  <TableRow className="border-gray-700 hover:bg-gray-800/50">
                    <TableCell colSpan={7} className="text-center py-8 text-gray-400">
                      Loading templates...
                    </TableCell>
                  </TableRow>
                ) : filteredTemplates.length === 0 ? (
                  <TableRow className="border-gray-700 hover:bg-gray-800/50">
                    <TableCell colSpan={7} className="text-center py-8 text-gray-400">
                      {searchTerm || statusFilter !== 'all' 
                        ? 'No templates match your filters'
                        : 'No templates created yet'
                      }
                    </TableCell>
                  </TableRow>
                ) : (
                  filteredTemplates.map((template) => (
                    <TableRow key={template.id} className="border-gray-700 hover:bg-gray-800/50">
                      <TableCell className="font-medium text-white">{template.name}</TableCell>
                      <TableCell className="text-gray-300">{getLogTypeLabel(template.logType)}</TableCell>
                      <TableCell>{getStatusBadge(template.status)}</TableCell>
                      <TableCell className="text-gray-300">
                        v{template.latestVersion}
                        {template.status === 'draft' && template.latestVersion === 0 && (
                          <span className="text-gray-500 ml-1">(unpublished)</span>
                        )}
                      </TableCell>
                      <TableCell className="text-gray-300">
                        {formatDistanceToNow(
                          template.updatedAt?.toDate ? template.updatedAt.toDate() : new Date(template.updatedAt), 
                          { addSuffix: true }
                        )}
                      </TableCell>
                      <TableCell className="text-gray-300">{template.createdBy}</TableCell>
                      <TableCell>
                        <DropdownMenu>
                          <DropdownMenuTrigger asChild>
                            <Button variant="ghost" size="sm" className="hover:bg-gray-700 text-gray-300">
                              <MoreVertical className="h-4 w-4" />
                            </Button>
                          </DropdownMenuTrigger>
                          <DropdownMenuContent align="end" className="bg-[#1E1E1E] border-gray-800">
                            <DropdownMenuItem
                              onClick={() => router.push(`/admin/log-builder/${template.id}/edit`)}
                              className="text-white hover:bg-gray-700"
                            >
                              <Edit className="h-4 w-4 mr-2" />
                              Edit
                            </DropdownMenuItem>
                            <DropdownMenuItem
                              onClick={() => router.push(`/admin/log-builder/${template.id}/preview`)}
                              className="text-white hover:bg-gray-700"
                            >
                              <Eye className="h-4 w-4 mr-2" />
                              Preview
                            </DropdownMenuItem>
                            <DropdownMenuItem
                              onClick={() => router.push(`/admin/log-builder/${template.id}/history`)}
                              className="text-white hover:bg-gray-700"
                            >
                              <History className="h-4 w-4 mr-2" />
                              History
                            </DropdownMenuItem>
                            <DropdownMenuItem
                              onClick={() => handleDuplicateTemplate(template)}
                              className="text-white hover:bg-gray-700"
                            >
                              <Copy className="h-4 w-4 mr-2" />
                              Duplicate
                            </DropdownMenuItem>
                            {template.status !== 'archived' && (
                              <DropdownMenuItem
                                onClick={() => handleArchiveTemplate(template.id)}
                                className="text-red-400 hover:bg-gray-700"
                              >
                                <Archive className="h-4 w-4 mr-2" />
                                Archive
                              </DropdownMenuItem>
                            )}
                          </DropdownMenuContent>
                        </DropdownMenu>
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
              </Table>
            </LazyWrapper>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}