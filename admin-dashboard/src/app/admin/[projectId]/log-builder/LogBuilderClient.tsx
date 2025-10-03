'use client';

import { useState, useTransition, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { LogTemplate } from '@/lib/logs/templates/types';
import { ExcelPreview } from '@/components/logbuilder/ExcelPreview';
import { Button } from '@/components/ui/button';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { 
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Badge } from '@/components/ui/badge';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Checkbox } from '@/components/ui/checkbox';
import { collection, getDocs, query, where, doc, getDoc, runTransaction, Timestamp } from 'firebase/firestore';
import { db, auth } from '@/lib/firebase';
import { ArrowLeft, FileText, Calendar } from 'lucide-react';

interface LogBuilderClientProps {
  projectId: string;
}

export function LogBuilderClient({ projectId }: LogBuilderClientProps) {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();
  const [templates, setTemplates] = useState<LogTemplate[]>([]);
  const [selectedTemplate, setSelectedTemplate] = useState<string>('');
  const [currentTemplate, setCurrentTemplate] = useState<string | null>(null);
  const [reason, setReason] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [previewData, setPreviewData] = useState<any>(null);
  
  useEffect(() => {
    loadData();
  }, [projectId]);
  
  useEffect(() => {
    if (selectedTemplate) {
      generatePreview();
    }
  }, [selectedTemplate]);
  
  const loadData = async () => {
    try {
      setLoading(true);
      
      // Load published templates
      const templatesQuery = query(
        collection(db, 'logTemplates'),
        where('status', '==', 'published')
      );
      const templatesSnapshot = await getDocs(templatesQuery);
      const templatesList = templatesSnapshot.docs.map(doc => {
        const data = doc.data();
        return {
          key: data.key || doc.id,
          title: data.title || '',
          frequency: 'hourly' as const,
          version: data.version || 0,
          status: data.status || 'draft' as const,
          fields: data.fields || [],
          editableAreas: data.editableAreas || [],
          sourceXlsxPath: data.sourceXlsxPath || '',
          ...data,
          id: doc.id
        } as LogTemplate;
      });
      setTemplates(templatesList);
      
      // Load current project metadata
      const projectDoc = await getDoc(doc(db, `projects/${projectId}/metadata`));
      if (projectDoc.exists()) {
        const data = projectDoc.data();
        setCurrentTemplate(data.logType);
        setSelectedTemplate(data.logType);
      }
      
    } catch (error) {
      console.error('Error loading data:', error);
      setError('Failed to load templates');
    } finally {
      setLoading(false);
    }
  };
  
  const generatePreview = async () => {
    const template = templates.find(t => t.key === selectedTemplate);
    if (!template?.sourceXlsxPath) return;
    
    try {
      const response = await fetch('/api/templates/preview', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ templatePath: template.sourceXlsxPath })
      });
      
      if (response.ok) {
        const data = await response.json();
        setPreviewData(data);
      }
    } catch (error) {
      console.error('Error generating preview:', error);
    }
  };
  
  // Find the selected template details
  const template = templates.find(t => t.key === selectedTemplate);
  const isChanging = currentTemplate && currentTemplate !== selectedTemplate;
  
  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setError(null);
    setSuccess(null);
    
    if (!selectedTemplate) {
      setError('Please select a template');
      return;
    }
    
    if (isChanging && !reason.trim()) {
      setError('Please provide a reason for changing the template');
      return;
    }
    
    startTransition(async () => {
      try {
        await runTransaction(db, async (transaction) => {
          const metadataRef = doc(db, `projects/${projectId}/metadata`);
          const historyRef = doc(collection(db, `projects/${projectId}/logTypeHistory`));
          
          // Update project metadata
          transaction.set(metadataRef, {
            logType: selectedTemplate,
            updatedBy: auth.currentUser?.uid || 'admin',
            updatedAt: Timestamp.now()
          });
          
          // Add history record
          transaction.set(historyRef, {
            from: currentTemplate ? { logType: currentTemplate } : null,
            to: { logType: selectedTemplate },
            reason: reason || 'Initial assignment',
            userId: auth.currentUser?.uid || 'admin',
            ts: Timestamp.now()
          });
        });
        
        setSuccess('Template assigned successfully');
        setCurrentTemplate(selectedTemplate);
        
      } catch (error) {
        console.error('Error assigning template:', error);
        setError('Failed to assign template. Please try again.');
      }
    });
  };
  
  if (loading) {
    return <div className="flex items-center justify-center py-12">Loading...</div>;
  }
  
  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle>Select Log Template</CardTitle>
          <CardDescription>
            Choose the appropriate template for this project. The operator app will use this to render the correct data entry form.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleSubmit} className="space-y-6">
            {/* Template Selection */}
            <div className="space-y-2">
              <Label htmlFor="template">Template</Label>
              <Select
                value={selectedTemplate}
                onValueChange={setSelectedTemplate}
                disabled={isPending}
              >
                <SelectTrigger id="template">
                  <SelectValue placeholder="Select a template..." />
                </SelectTrigger>
                <SelectContent>
                  {templates.map(t => (
                    <SelectItem key={t.key} value={t.key}>
                      {t.title} (v{t.version})
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            
            {/* Reason for Change */}
            {isChanging && (
              <div className="space-y-2">
                <Label htmlFor="reason">
                  Reason for Change <span className="text-red-500">*</span>
                </Label>
                <Textarea
                  id="reason"
                  value={reason}
                  onChange={(e) => setReason(e.target.value)}
                  placeholder="Explain why the template is being changed..."
                  rows={3}
                  disabled={isPending}
                  required
                />
              </div>
            )}
            
            
            {/* Error/Success Messages */}
            {error && (
              <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
                {error}
              </div>
            )}
            {success && (
              <div className="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded">
                {success}
              </div>
            )}
            
            {/* Submit Button */}
            <Button 
              type="submit" 
              disabled={isPending || !selectedTemplate}
              className="w-full"
            >
              {isPending ? 'Saving...' : isChanging ? 'Change Template' : 'Assign Template'}
            </Button>
          </form>
        </CardContent>
      </Card>
      
      {/* Template Preview */}
      {template && (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <FileText className="w-5 h-5" />
                {template.title}
              </CardTitle>
              <CardDescription>
                Fields that operators will see in the mobile app
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="grid gap-4">
                {template.fields.map(field => (
                  <div key={field.id} className="flex items-center justify-between p-3 bg-gray-50 rounded">
                    <div>
                      <p className="text-sm font-medium text-gray-900">
                        {field.label}
                      </p>
                      <p className="text-xs text-gray-500">
                        Type: {field.type}
                        {field.unit && ` (${field.unit})`}
                        {field.excelKey && ` • Cell: ${field.excelKey}`}
                      </p>
                    </div>
                    <div className="flex gap-2">
                      {field.required && (
                        <Badge variant="destructive" className="text-xs">
                          Required
                        </Badge>
                      )}
                      {!field.visible && (
                        <Badge variant="secondary" className="text-xs">
                          Hidden
                        </Badge>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
          
          {/* Excel Preview */}
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center gap-2">
                <Calendar className="w-5 h-5" />
                Excel Preview
              </CardTitle>
              <CardDescription>
                How the log will appear in Excel format
              </CardDescription>
            </CardHeader>
            <CardContent>
              {previewData ? (
                <ExcelPreview
                  html={previewData.html}
                  css={previewData.css}
                  operationRange={template.editableAreas[0]}
                  fields={template.fields}
                  className="border rounded-lg overflow-hidden"
                />
              ) : (
                <div className="bg-gray-50 border-2 border-dashed border-gray-300 rounded-lg p-12 text-center">
                  <FileText className="w-12 h-12 text-gray-400 mx-auto mb-4" />
                  <p className="text-gray-500">Excel preview not available</p>
                  <p className="text-sm text-gray-400 mt-1">Template file not found or invalid</p>
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      )}
    </div>
  );
}