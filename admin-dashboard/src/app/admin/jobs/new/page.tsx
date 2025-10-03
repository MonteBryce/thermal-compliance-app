'use client';

import { useState, useTransition } from 'react';
import { useRouter } from 'next/navigation';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { 
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { ArrowLeft } from 'lucide-react';
import Link from 'next/link';

export default function NewJobPage() {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    location: '',
    status: 'active',
    clientName: '',
    projectManager: '',
    startDate: '',
    expectedEndDate: '',
  });

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setError(null);
    setSuccess(null);
    
    if (!formData.name.trim()) {
      setError('Job name is required');
      return;
    }
    
    startTransition(async () => {
      try {
        const response = await fetch('/api/admin/jobs', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            ...formData,
            createdAt: new Date().toISOString(),
          }),
        });
        
        const result = await response.json();
        
        if (result.success) {
          setSuccess(`Job created successfully! ID: ${result.jobId}`);
          // Redirect to the new job's template assignment page
          setTimeout(() => {
            router.push(`/admin/jobs/assign?jobId=${result.jobId}`);
          }, 2000);
        } else {
          setError(result.message || 'Failed to create job');
        }
      } catch (error) {
        setError('Failed to create job. Please try again.');
      }
    });
  };

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="mb-8">
          <div className="flex items-center gap-4 mb-4">
            <Button asChild variant="outline" size="sm">
              <Link href="/admin/jobs">
                <ArrowLeft className="h-4 w-4 mr-2" />
                Back to Jobs
              </Link>
            </Button>
          </div>
          <h1 className="text-3xl font-bold text-gray-900">Create New Job</h1>
          <p className="mt-2 text-gray-600">
            Set up a new thermal logging job and assign a template
          </p>
        </div>

        <Card>
          <CardHeader>
            <CardTitle>Job Details</CardTitle>
            <CardDescription>
              Enter the basic information for this thermal logging job
            </CardDescription>
          </CardHeader>
          <CardContent>
            <form onSubmit={handleSubmit} className="space-y-6">
              {/* Basic Information */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="space-y-2">
                  <Label htmlFor="name">
                    Job Name <span className="text-red-500">*</span>
                  </Label>
                  <Input
                    id="name"
                    value={formData.name}
                    onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
                    placeholder="e.g., North Sea Platform A Degas"
                    required
                    disabled={isPending}
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="location">Location</Label>
                  <Input
                    id="location"
                    value={formData.location}
                    onChange={(e) => setFormData(prev => ({ ...prev, location: e.target.value }))}
                    placeholder="e.g., Gulf of Mexico, Platform A"
                    disabled={isPending}
                  />
                </div>
              </div>

              <div className="space-y-2">
                <Label htmlFor="description">Description</Label>
                <Textarea
                  id="description"
                  value={formData.description}
                  onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
                  placeholder="Brief description of the thermal logging operation..."
                  rows={3}
                  disabled={isPending}
                />
              </div>

              {/* Project Information */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div className="space-y-2">
                  <Label htmlFor="clientName">Client Name</Label>
                  <Input
                    id="clientName"
                    value={formData.clientName}
                    onChange={(e) => setFormData(prev => ({ ...prev, clientName: e.target.value }))}
                    placeholder="e.g., Shell Oil Company"
                    disabled={isPending}
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="projectManager">Project Manager</Label>
                  <Input
                    id="projectManager"
                    value={formData.projectManager}
                    onChange={(e) => setFormData(prev => ({ ...prev, projectManager: e.target.value }))}
                    placeholder="e.g., John Smith"
                    disabled={isPending}
                  />
                </div>
              </div>

              {/* Dates */}
              <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <div className="space-y-2">
                  <Label htmlFor="startDate">Start Date</Label>
                  <Input
                    id="startDate"
                    type="date"
                    value={formData.startDate}
                    onChange={(e) => setFormData(prev => ({ ...prev, startDate: e.target.value }))}
                    disabled={isPending}
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="expectedEndDate">Expected End Date</Label>
                  <Input
                    id="expectedEndDate"
                    type="date"
                    value={formData.expectedEndDate}
                    onChange={(e) => setFormData(prev => ({ ...prev, expectedEndDate: e.target.value }))}
                    disabled={isPending}
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="status">Initial Status</Label>
                  <Select
                    value={formData.status}
                    onValueChange={(value) => setFormData(prev => ({ ...prev, status: value }))}
                    disabled={isPending}
                  >
                    <SelectTrigger id="status">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="pending">Pending</SelectItem>
                      <SelectItem value="active">Active</SelectItem>
                      <SelectItem value="planning">Planning</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>

              {/* Error/Success Messages */}
              {error && (
                <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded">
                  {error}
                </div>
              )}
              {success && (
                <div className="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded">
                  {success}
                  <p className="text-sm mt-1">Redirecting to template assignment...</p>
                </div>
              )}

              {/* Submit Buttons */}
              <div className="flex gap-4 pt-6">
                <Button 
                  type="submit" 
                  disabled={isPending}
                  className="flex-1"
                >
                  {isPending ? 'Creating Job...' : 'Create Job'}
                </Button>
                <Button 
                  type="button" 
                  variant="outline"
                  onClick={() => router.push('/admin/jobs')}
                  disabled={isPending}
                >
                  Cancel
                </Button>
              </div>
            </form>
          </CardContent>
        </Card>

        {/* Next Steps Info */}
        <Card className="mt-6">
          <CardHeader>
            <CardTitle className="text-lg">Next Steps</CardTitle>
          </CardHeader>
          <CardContent>
            <ol className="list-decimal list-inside space-y-2 text-sm text-gray-600">
              <li>Job will be created with a unique ID</li>
              <li>You'll be redirected to assign a log template</li>
              <li>Operators can then see the job and begin logging</li>
              <li>Monitor progress from the jobs dashboard</li>
            </ol>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}