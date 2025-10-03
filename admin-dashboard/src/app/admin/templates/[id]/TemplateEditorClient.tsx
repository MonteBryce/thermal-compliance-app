'use client';

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '@/components/ui/dialog';
import { ExcelPreview } from '@/components/logbuilder/ExcelPreview';
import { OperationEditor } from '@/components/logbuilder/OperationEditor';
import { Save, Upload, Download, History, ArrowLeft, FileText } from 'lucide-react';
import { doc, getDoc, updateDoc, collection, addDoc, getDocs, query, orderBy, Timestamp } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { auth } from '@/lib/firebase';
import { LogTemplate, Field, Range, ExcelPreviewData } from '@/lib/logs/templates/types';
import * as XLSX from 'xlsx';

interface TemplateEditorClientProps {
  templateId: string;
  initialAction?: string;
}

export function TemplateEditorClient({ templateId, initialAction }: TemplateEditorClientProps) {
  const router = useRouter();
  const [template, setTemplate] = useState<LogTemplate | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [previewData, setPreviewData] = useState<ExcelPreviewData | null>(null);
  const [showPublishDialog, setShowPublishDialog] = useState(initialAction === 'publish');
  const [publishChangelog, setPublishChangelog] = useState('');
  const [versions, setVersions] = useState<any[]>([]);
  const [showVersionsDialog, setShowVersionsDialog] = useState(false);

  useEffect(() => {
    if (templateId === 'new') {
      createNewTemplate();
    } else {
      loadTemplate();
    }
  }, [templateId]);

  useEffect(() => {
    if (template) {
      generatePreview();
    }
  }, [template]);

  const loadTemplate = async () => {
    try {
      setLoading(true);
      const templateDoc = await getDoc(doc(db, 'logTemplates', templateId));
      
      if (templateDoc.exists()) {
        const data = templateDoc.data() as LogTemplate;
        setTemplate({ ...data, id: templateDoc.id });
        await loadVersions();
      } else {
        console.error('Template not found');
        router.push('/admin/templates');
      }
    } catch (error) {
      console.error('Error loading template:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadVersions = async () => {
    try {
      const versionsRef = collection(db, `logTemplates/${templateId}/history`);
      const q = query(versionsRef, orderBy('version', 'desc'));
      const snapshot = await getDocs(q);
      setVersions(snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() })));
    } catch (error) {
      console.error('Error loading versions:', error);
    }
  };

  const createNewTemplate = () => {
    setTemplate({
      key: '',
      title: 'New Template',
      frequency: 'hourly',
      version: 0,
      status: 'draft',
      fields: [
        {
          id: 'sample-temp-1',
          label: 'Temperature Reading 1',
          type: 'number',
          unit: '°C',
          required: true,
          visible: true,
          excelKey: 'B12'
        },
        {
          id: 'sample-temp-2',
          label: 'Temperature Reading 2',
          type: 'number',
          unit: '°C',
          required: true,
          visible: true,
          excelKey: 'C12'
        },
        {
          id: 'sample-operator',
          label: 'Operator Initials',
          type: 'text',
          required: true,
          visible: true,
          excelKey: 'D12'
        }
      ],
      editableAreas: [{
        sheet: 'Sheet1',
        start: 'B12',
        end: 'N28',
        role: 'operation'
      }],
      sourceXlsxPath: '',
      createdBy: auth.currentUser?.uid || 'admin',
      updatedAt: Date.now()
    });
    setLoading(false);
  };

  const generatePreview = async () => {
    if (!template?.sourceXlsxPath) {
      setPreviewData({
        html: generateSampleExcelPreview(),
        operationRange: template?.editableAreas[0]
      });
      return;
    }

    try {
      const response = await fetch(`/api/templates/preview`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ templatePath: template.sourceXlsxPath })
      });
      
      if (response.ok) {
        const data = await response.json();
        setPreviewData({
          html: data.html,
          css: data.css,
          operationRange: template.editableAreas[0],
          mergedCells: data.mergedCells
        });
      }
    } catch (error) {
      console.error('Error generating preview:', error);
      setPreviewData({
        html: '<div>Error loading preview</div>',
        operationRange: template?.editableAreas[0]
      });
    }
  };

  const handleSave = async () => {
    if (!template) return;
    
    try {
      setSaving(true);
      const updateData = {
        ...template,
        updatedAt: Timestamp.now(),
        updatedBy: auth.currentUser?.uid || 'admin'
      };
      
      if (templateId === 'new') {
        const docRef = await addDoc(collection(db, 'logTemplates'), updateData);
        router.push(`/admin/templates/${docRef.id}`);
      } else {
        await updateDoc(doc(db, 'logTemplates', templateId), updateData);
      }
    } catch (error) {
      console.error('Error saving template:', error);
    } finally {
      setSaving(false);
    }
  };

  const handlePublish = async () => {
    if (!template || !publishChangelog) return;
    
    try {
      setSaving(true);
      const newVersion = template.version + 1;
      
      const versionData = {
        templateId,
        version: newVersion,
        template: { ...template },
        publishedAt: Timestamp.now(),
        publishedBy: auth.currentUser?.uid || 'admin',
        changelog: publishChangelog
      };
      
      await addDoc(collection(db, `logTemplates/${templateId}/history`), versionData);
      
      await updateDoc(doc(db, 'logTemplates', templateId), {
        status: 'published',
        version: newVersion,
        updatedAt: Timestamp.now()
      });
      
      setShowPublishDialog(false);
      setPublishChangelog('');
      await loadTemplate();
    } catch (error) {
      console.error('Error publishing template:', error);
    } finally {
      setSaving(false);
    }
  };

  const handleRollback = async (versionId: string) => {
    const version = versions.find(v => v.id === versionId);
    if (!version) return;
    
    try {
      setSaving(true);
      const rollbackData = {
        ...version.template,
        version: template!.version + 1,
        status: 'draft',
        updatedAt: Timestamp.now(),
        updatedBy: auth.currentUser?.uid || 'admin'
      };
      
      await updateDoc(doc(db, 'logTemplates', templateId), rollbackData);
      await loadTemplate();
      setShowVersionsDialog(false);
    } catch (error) {
      console.error('Error rolling back:', error);
    } finally {
      setSaving(false);
    }
  };

  const handleFieldsChange = (newFields: Field[]) => {
    if (template) {
      setTemplate({ ...template, fields: newFields });
    }
  };

  const generateSampleExcelPreview = () => {
    return `
      <table>
        <tr>
          <th style="background-color: #f0f0f0; padding: 4px; border: 1px solid #ccc;">A</th>
          <th style="background-color: #f0f0f0; padding: 4px; border: 1px solid #ccc;">B</th>
          <th style="background-color: #f0f0f0; padding: 4px; border: 1px solid #ccc;">C</th>
          <th style="background-color: #f0f0f0; padding: 4px; border: 1px solid #ccc;">D</th>
          <th style="background-color: #f0f0f0; padding: 4px; border: 1px solid #ccc;">E</th>
        </tr>
        <tr><td style="padding: 4px; border: 1px solid #ccc;">1</td><td style="padding: 4px; border: 1px solid #ccc;"></td><td style="padding: 4px; border: 1px solid #ccc;"></td><td style="padding: 4px; border: 1px solid #ccc;"></td><td style="padding: 4px; border: 1px solid #ccc;"></td></tr>
        <tr><td style="padding: 4px; border: 1px solid #ccc;">2</td><td style="padding: 4px; border: 1px solid #ccc;"></td><td style="padding: 4px; border: 1px solid #ccc;"></td><td style="padding: 4px; border: 1px solid #ccc;"></td><td style="padding: 4px; border: 1px solid #ccc;"></td></tr>
        <tr><td style="padding: 4px; border: 1px solid #ccc;">3</td><td style="padding: 4px; border: 1px solid #ccc;"></td><td style="padding: 4px; border: 1px solid #ccc;"></td><td style="padding: 4px; border: 1px solid #ccc;"></td><td style="padding: 4px; border: 1px solid #ccc;"></td></tr>
        <tr><td style="padding: 4px; border: 1px solid #ccc;">4</td><td style="padding: 4px; border: 1px solid #ccc;"></td><td style="padding: 4px; border: 1px solid #ccc;"></td><td style="padding: 4px; border: 1px solid #ccc;"></td><td style="padding: 4px; border: 1px solid #ccc;"></td></tr>
        <tr><td style="padding: 4px; border: 1px solid #ccc;">5</td><td style="padding: 4px; border: 1px solid #ccc;"></td><td style="padding: 4px; border: 1px solid #ccc;"></td><td style="padding: 4px; border: 1px solid #ccc;"></td><td style="padding: 4px; border: 1px solid #ccc;"></td></tr>
        <tr><td style="padding: 4px; border: 1px solid #ccc;">6</td><td style="padding: 4px; border: 1px solid #ccc;"></td><td style="padding: 4px; border: 1px solid #ccc;"></td><td style="padding: 4px; border: 1px solid #ccc;"></td><td style="padding: 4px; border: 1px solid #ccc;"></td></tr>
        <tr><td style="padding: 4px; border: 1px solid #ccc;">7</td><td style="padding: 4px; border: 1px solid #ccc;"></td><td style="padding: 4px; border: 1px solid #ccc;"></td><td style="padding: 4px; border: 1px solid #ccc;"></td><td style="padding: 4px; border: 1px solid #ccc;"></td></tr>
        <tr><td style="padding: 4px; border: 1px solid #ccc;">8</td><td style="padding: 4px; border: 1px solid #ccc;"></td><td style="padding: 4px; border: 1px solid #ccc;"></td><td style="padding: 4px; border: 1px solid #ccc;"></td><td style="padding: 4px; border: 1px solid #ccc;"></td></tr>
        <tr><td style="padding: 4px; border: 1px solid #ccc;">9</td><td style="padding: 4px; border: 1px solid #ccc;"></td><td style="padding: 4px; border: 1px solid #ccc;"></td><td style="padding: 4px; border: 1px solid #ccc;"></td><td style="padding: 4px; border: 1px solid #ccc;"></td></tr>
        <tr><td style="padding: 4px; border: 1px solid #ccc;">10</td><td style="padding: 4px; border: 1px solid #ccc;"></td><td style="padding: 4px; border: 1px solid #ccc;"></td><td style="padding: 4px; border: 1px solid #ccc;"></td><td style="padding: 4px; border: 1px solid #ccc;"></td></tr>
        <tr><td style="padding: 4px; border: 1px solid #ccc;">11</td><td style="padding: 4px; border: 1px solid #ccc;"></td><td style="padding: 4px; border: 1px solid #ccc;"></td><td style="padding: 4px; border: 1px solid #ccc;"></td><td style="padding: 4px; border: 1px solid #ccc;"></td></tr>
        <tr><td style="padding: 4px; border: 1px solid #ccc;">12</td><td style="padding: 4px; border: 1px solid #ccc; background-color: rgba(59, 130, 246, 0.1); border-color: #3b82f6;">Temp 1</td><td style="padding: 4px; border: 1px solid #ccc; background-color: rgba(59, 130, 246, 0.1); border-color: #3b82f6;">Temp 2</td><td style="padding: 4px; border: 1px solid #ccc; background-color: rgba(59, 130, 246, 0.1); border-color: #3b82f6;">Operator</td><td style="padding: 4px; border: 1px solid #ccc;"></td></tr>
        <tr><td style="padding: 4px; border: 1px solid #ccc;">13</td><td style="padding: 4px; border: 1px solid #ccc;"></td><td style="padding: 4px; border: 1px solid #ccc;"></td><td style="padding: 4px; border: 1px solid #ccc;"></td><td style="padding: 4px; border: 1px solid #ccc;"></td></tr>
      </table>
      <div style="margin-top: 16px; padding: 12px; background-color: #f0f9ff; border: 1px solid #0284c7; border-radius: 8px; font-size: 14px;">
        <div style="color: #0369a1; margin-bottom: 8px;">📝 Sample Excel Preview</div>
        <div style="color: #374151;">Upload an Excel template to see the actual spreadsheet preview with operation areas highlighted.</div>
      </div>
    `;
  };

  const handleUploadExcel = async (file: File) => {
    const reader = new FileReader();
    reader.onload = async (e) => {
      const data = new Uint8Array(e.target?.result as ArrayBuffer);
      const workbook = XLSX.read(data, { type: 'array' });
      
      const response = await fetch('/api/templates/upload', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          fileName: file.name,
          workbook: JSON.stringify(workbook)
        })
      });
      
      if (response.ok) {
        const result = await response.json();
        if (template) {
          setTemplate({
            ...template,
            sourceXlsxPath: result.path,
            fields: result.fields || template.fields
          });
        }
      }
    };
    reader.readAsArrayBuffer(file);
  };

  if (loading) {
    return <div className="flex items-center justify-center h-screen">Loading...</div>;
  }

  if (!template) {
    return <div className="flex items-center justify-center h-screen">Template not found</div>;
  }

  return (
    <div className="flex flex-col h-full bg-[#111111] text-white">
      <div className="border-b border-gray-800 px-6 py-4 flex items-center justify-between bg-[#1E1E1E]">
        <div className="flex items-center gap-4">
          <Button variant="ghost" size="icon" onClick={() => router.push('/admin/templates')}>
            <ArrowLeft className="w-4 h-4" />
          </Button>
          <div>
            <h1 className="text-2xl font-bold text-white">{template.title}</h1>
            <p className="text-sm text-gray-400">Version {template.version} • {template.status}</p>
          </div>
        </div>
        <div className="flex gap-2">
          <Button variant="outline" onClick={() => setShowVersionsDialog(true)}>
            <History className="w-4 h-4 mr-2" />
            History
          </Button>
          {template.status === 'draft' && (
            <Button variant="outline" onClick={() => setShowPublishDialog(true)}>
              <FileText className="w-4 h-4 mr-2" />
              Publish
            </Button>
          )}
          <Button onClick={handleSave} disabled={saving}>
            <Save className="w-4 h-4 mr-2" />
            {saving ? 'Saving...' : 'Save Draft'}
          </Button>
        </div>
      </div>

      <div className="flex-1 flex overflow-hidden">
        <div className="w-80 border-r border-gray-800 bg-[#1E1E1E] p-6 overflow-y-auto">
          <h2 className="font-semibold mb-4 text-white">Template Settings</h2>
          <div className="space-y-4">
            <div>
              <Label htmlFor="key">Template Key</Label>
              <Input
                id="key"
                value={template.key}
                onChange={(e) => setTemplate({ ...template, key: e.target.value })}
                placeholder="e.g., methane_hourly"
              />
            </div>
            <div>
              <Label htmlFor="title">Template Title</Label>
              <Input
                id="title"
                value={template.title}
                onChange={(e) => setTemplate({ ...template, title: e.target.value })}
              />
            </div>
            <div>
              <Label htmlFor="excel">Excel Template</Label>
              <div className="flex gap-2">
                <Input
                  id="excel"
                  value={template.sourceXlsxPath}
                  onChange={(e) => setTemplate({ ...template, sourceXlsxPath: e.target.value })}
                  placeholder="Path to Excel file"
                />
                <Button variant="outline" size="icon" asChild>
                  <label htmlFor="excel-upload" className="cursor-pointer">
                    <Upload className="w-4 h-4" />
                    <input
                      id="excel-upload"
                      type="file"
                      accept=".xlsx,.xls"
                      className="hidden"
                      onChange={(e) => e.target.files?.[0] && handleUploadExcel(e.target.files[0])}
                    />
                  </label>
                </Button>
              </div>
            </div>
            <div>
              <Label>Operation Range</Label>
              <div className="grid grid-cols-2 gap-2 mt-2">
                <div>
                  <Label htmlFor="range-start" className="text-xs">Start</Label>
                  <Input
                    id="range-start"
                    value={template.editableAreas[0]?.start || ''}
                    onChange={(e) => setTemplate({
                      ...template,
                      editableAreas: [{
                        ...template.editableAreas[0],
                        start: e.target.value
                      }]
                    })}
                    placeholder="B12"
                  />
                </div>
                <div>
                  <Label htmlFor="range-end" className="text-xs">End</Label>
                  <Input
                    id="range-end"
                    value={template.editableAreas[0]?.end || ''}
                    onChange={(e) => setTemplate({
                      ...template,
                      editableAreas: [{
                        ...template.editableAreas[0],
                        end: e.target.value
                      }]
                    })}
                    placeholder="N28"
                  />
                </div>
              </div>
            </div>
          </div>
        </div>

        <div className="flex-1 p-6 overflow-y-auto bg-[#111111]">
          <Tabs defaultValue="fields" className="h-full">
            <TabsList className="mb-4">
              <TabsTrigger value="fields">Operation Fields</TabsTrigger>
              <TabsTrigger value="preview">Live Preview</TabsTrigger>
            </TabsList>
            <TabsContent value="fields" className="h-full">
              <OperationEditor
                fields={template.fields}
                onFieldsChange={handleFieldsChange}
              />
            </TabsContent>
            <TabsContent value="preview" className="h-full">
              {previewData && (
                <ExcelPreview
                  html={previewData.html}
                  css={previewData.css}
                  operationRange={previewData.operationRange}
                  fields={template.fields}
                />
              )}
            </TabsContent>
          </Tabs>
        </div>

        <div className="w-96 border-l border-gray-800 bg-[#1E1E1E] p-6 overflow-y-auto">
          <h2 className="font-semibold mb-4 text-white">Excel Preview</h2>
          {previewData ? (
            <div className="bg-white rounded-lg p-4 border">
              <ExcelPreview
                html={previewData.html}
                css={previewData.css}
                operationRange={previewData.operationRange}
                fields={template.fields}
                className="scale-75 origin-top-left"
              />
            </div>
          ) : (
            <div className="bg-[#1E1E1E] border border-gray-800 rounded-lg p-8 text-center text-gray-400">
              Upload an Excel template to see preview
            </div>
          )}
        </div>
      </div>

      <Dialog open={showPublishDialog} onOpenChange={setShowPublishDialog}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Publish Template</DialogTitle>
          </DialogHeader>
          <div className="space-y-4">
            <div>
              <Label htmlFor="changelog">Changelog</Label>
              <Textarea
                id="changelog"
                value={publishChangelog}
                onChange={(e) => setPublishChangelog(e.target.value)}
                placeholder="Describe what changed in this version..."
                rows={4}
              />
            </div>
            <div className="bg-yellow-50 p-3 rounded-lg text-sm">
              <p className="font-medium text-yellow-800">Publishing will:</p>
              <ul className="list-disc list-inside text-yellow-700 mt-1">
                <li>Create version {template.version + 1}</li>
                <li>Make this template available to operators</li>
                <li>Create an immutable snapshot</li>
              </ul>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowPublishDialog(false)}>Cancel</Button>
            <Button onClick={handlePublish} disabled={!publishChangelog || saving}>
              {saving ? 'Publishing...' : 'Publish'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <Dialog open={showVersionsDialog} onOpenChange={setShowVersionsDialog}>
        <DialogContent className="max-w-3xl">
          <DialogHeader>
            <DialogTitle>Version History</DialogTitle>
          </DialogHeader>
          <div className="space-y-2 max-h-96 overflow-y-auto">
            {versions.map((version) => (
              <div key={version.id} className="border rounded-lg p-4">
                <div className="flex justify-between items-start">
                  <div>
                    <p className="font-medium">Version {version.version}</p>
                    <p className="text-sm text-gray-500">{version.changelog}</p>
                    <p className="text-xs text-gray-400 mt-1">
                      Published by {version.publishedBy} on {version.publishedAt?.toDate().toLocaleDateString()}
                    </p>
                  </div>
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => handleRollback(version.id)}
                  >
                    Rollback
                  </Button>
                </div>
              </div>
            ))}
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}