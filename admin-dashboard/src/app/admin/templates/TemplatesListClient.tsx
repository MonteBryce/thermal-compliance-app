'use client';

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu';
import { Plus, Edit, Copy, Trash2, FileText, MoreVertical, Search, Filter } from 'lucide-react';
import { collection, getDocs, query, where, orderBy, deleteDoc, doc } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { LogTemplate } from '@/lib/logs/templates/types';
import { format } from 'date-fns';

export function TemplatesListClient() {
  const router = useRouter();
  const [templates, setTemplates] = useState<LogTemplate[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<'all' | 'draft' | 'published'>('all');

  useEffect(() => {
    loadTemplates();
  }, [statusFilter]);

  const loadTemplates = async () => {
    try {
      setLoading(true);
      const templatesRef = collection(db, 'logTemplates');
      let q = query(templatesRef, orderBy('updatedAt', 'desc'));
      
      if (statusFilter !== 'all') {
        q = query(templatesRef, where('status', '==', statusFilter), orderBy('updatedAt', 'desc'));
      }
      
      const snapshot = await getDocs(q);
      const templatesList = snapshot.docs.map(doc => ({
        ...doc.data(),
        id: doc.id
      } as LogTemplate));
      
      setTemplates(templatesList);
    } catch (error) {
      console.error('Error loading templates:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (templateId: string) => {
    if (confirm('Are you sure you want to delete this template?')) {
      try {
        await deleteDoc(doc(db, 'logTemplates', templateId));
        await loadTemplates();
      } catch (error) {
        console.error('Error deleting template:', error);
      }
    }
  };

  const handleDuplicate = async (template: LogTemplate) => {
    router.push(`/admin/templates/new?duplicate=${template.id}`);
  };

  const handlePublish = async (templateId: string) => {
    router.push(`/admin/templates/${templateId}?action=publish`);
  };

  const filteredTemplates = templates.filter(template =>
    template.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
    template.key.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold">Log Templates</h1>
          <p className="text-gray-600 mt-1">Manage and configure thermal log templates</p>
        </div>
        <Button onClick={() => router.push('/admin/templates/new')}>
          <Plus className="w-4 h-4 mr-2" />
          New Template
        </Button>
      </div>

      <div className="flex gap-4 items-center">
        <div className="relative flex-1 max-w-md">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
          <Input
            placeholder="Search templates..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="pl-10"
          />
        </div>
        <div className="flex gap-2">
          <Button
            variant={statusFilter === 'all' ? 'default' : 'outline'}
            size="sm"
            onClick={() => setStatusFilter('all')}
          >
            All
          </Button>
          <Button
            variant={statusFilter === 'draft' ? 'default' : 'outline'}
            size="sm"
            onClick={() => setStatusFilter('draft')}
          >
            Draft
          </Button>
          <Button
            variant={statusFilter === 'published' ? 'default' : 'outline'}
            size="sm"
            onClick={() => setStatusFilter('published')}
          >
            Published
          </Button>
        </div>
      </div>

      {loading ? (
        <div className="text-center py-12">Loading templates...</div>
      ) : filteredTemplates.length === 0 ? (
        <div className="text-center py-12 bg-[#1E1E1E] border border-gray-800 rounded-lg">
          <FileText className="w-12 h-12 text-gray-500 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-white">No templates found</h3>
          <p className="text-gray-400 mt-1">Get started by creating your first template</p>
          <Button className="mt-4 bg-orange-600 hover:bg-orange-700" onClick={() => router.push('/admin/templates/new')}>
            <Plus className="w-4 h-4 mr-2" />
            Create Template
          </Button>
        </div>
      ) : (
        <div className="bg-[#1E1E1E] border border-gray-800 shadow rounded-lg overflow-hidden">
          <table className="min-w-full divide-y divide-gray-700">
            <thead className="bg-[#2A2A2A]">
              <tr>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">
                  Template
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Key
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Status
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Version
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Fields
                </th>
                <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                  Updated
                </th>
                <th className="relative px-6 py-3">
                  <span className="sr-only">Actions</span>
                </th>
              </tr>
            </thead>
            <tbody className="bg-[#1E1E1E] divide-y divide-gray-700">
              {filteredTemplates.map((template) => (
                <tr key={template.key} className="hover:bg-gray-50">
                  <td className="px-6 py-4 whitespace-nowrap">
                    <div>
                      <div className="text-sm font-medium text-gray-900">{template.title}</div>
                      <div className="text-sm text-gray-500">{template.frequency}</div>
                    </div>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {template.key}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap">
                    <Badge variant={template.status === 'published' ? 'default' : 'secondary'}>
                      {template.status}
                    </Badge>
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    v{template.version}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-900">
                    {template.fields.length}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-500">
                    {template.updatedAt ? format(new Date(template.updatedAt), 'MMM d, yyyy') : '-'}
                  </td>
                  <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                    <DropdownMenu>
                      <DropdownMenuTrigger asChild>
                        <Button variant="ghost" size="icon">
                          <MoreVertical className="w-4 h-4" />
                        </Button>
                      </DropdownMenuTrigger>
                      <DropdownMenuContent align="end">
                        <DropdownMenuItem onClick={() => router.push(`/admin/templates/${template.key}`)}>
                          <Edit className="w-4 h-4 mr-2" />
                          Edit
                        </DropdownMenuItem>
                        <DropdownMenuItem onClick={() => handleDuplicate(template)}>
                          <Copy className="w-4 h-4 mr-2" />
                          Duplicate
                        </DropdownMenuItem>
                        {template.status === 'draft' && (
                          <DropdownMenuItem onClick={() => handlePublish(template.key)}>
                            <FileText className="w-4 h-4 mr-2" />
                            Publish
                          </DropdownMenuItem>
                        )}
                        <DropdownMenuItem 
                          onClick={() => handleDelete(template.key)}
                          className="text-red-600"
                        >
                          <Trash2 className="w-4 h-4 mr-2" />
                          Delete
                        </DropdownMenuItem>
                      </DropdownMenuContent>
                    </DropdownMenu>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}