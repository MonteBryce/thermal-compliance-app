import { Suspense } from 'react';
import { requireAdmin } from '@/lib/auth/rbac';
import { collection, getDocs, orderBy, query, limit } from 'firebase/firestore';
import { db } from '@/lib/firebase';
import Link from 'next/link';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { PlusCircle, Settings, FileText, Calendar } from 'lucide-react';

interface Job {
  id: string;
  name: string;
  status: string;
  createdAt: any;
  description?: string;
  location?: string;
  logType?: string;
  templateVersion?: string;
}

async function getJobs(): Promise<Job[]> {
  try {
    const projectsQuery = query(
      collection(db, 'projects'),
      orderBy('createdAt', 'desc'),
      limit(50)
    );
    
    const snapshot = await getDocs(projectsQuery);
    const jobs: Job[] = [];
    
    for (const doc of snapshot.docs) {
      const data = doc.data();
      
      // Try to get metadata for template info
      let logType, templateVersion;
      try {
        const metadataDoc = await getDocs(collection(db, 'projects', doc.id, 'metadata'));
        if (!metadataDoc.empty) {
          const metadata = metadataDoc.docs[0].data();
          logType = metadata.logType;
          templateVersion = metadata.templateVersion;
        }
      } catch (error) {
        // Metadata doesn't exist yet
      }
      
      jobs.push({
        id: doc.id,
        name: data.name || doc.id,
        status: data.status || 'active',
        createdAt: data.createdAt,
        description: data.description,
        location: data.location,
        logType,
        templateVersion,
      });
    }
    
    return jobs;
  } catch (error) {
    console.error('Error fetching jobs:', error);
    return [];
  }
}

function JobCard({ job }: { job: Job }) {
  const statusColor = {
    'active': 'bg-green-600 text-white border-0',
    'pending': 'bg-yellow-600 text-white border-0',
    'complete': 'bg-blue-600 text-white border-0',
    'cancelled': 'bg-red-600 text-white border-0',
  }[job.status] || 'bg-gray-600 text-white border-0';

  return (
    <Card className="hover:shadow-lg transition-shadow bg-[#1E1E1E] border-gray-800">
      <CardHeader>
        <div className="flex items-start justify-between">
          <div className="flex-1">
            <CardTitle className="text-lg font-semibold text-white">
              {job.name}
            </CardTitle>
            {job.description && (
              <CardDescription className="mt-1 text-gray-300">
                {job.description}
              </CardDescription>
            )}
            {job.location && (
              <p className="text-sm text-gray-400 mt-1">
                📍 {job.location}
              </p>
            )}
          </div>
          <Badge className={statusColor}>
            {job.status}
          </Badge>
        </div>
      </CardHeader>
      <CardContent>
        <div className="space-y-3">
          {/* Template Assignment Status */}
          <div className="flex items-center justify-between">
            <span className="text-sm font-medium text-gray-300">Template:</span>
            {job.logType ? (
              <div className="text-right">
                <Badge className="text-xs bg-blue-600 text-white border-0">
                  {job.logType}
                </Badge>
                {job.templateVersion && (
                  <p className="text-xs text-gray-400 mt-1">v{job.templateVersion}</p>
                )}
              </div>
            ) : (
              <Badge className="text-xs bg-red-600 text-white border-0">
                Not Assigned
              </Badge>
            )}
          </div>
          
          {/* Created Date */}
          <div className="flex items-center justify-between">
            <span className="text-sm font-medium text-gray-300">Created:</span>
            <span className="text-sm text-gray-400">
              {job.createdAt?.toDate?.()?.toLocaleDateString() || 'Unknown'}
            </span>
          </div>
          
          {/* Actions */}
          <div className="flex gap-2 pt-2">
            <Button asChild size="sm" className="flex-1 bg-orange-600 hover:bg-orange-700 text-white border-0">
              <Link href={`/admin/jobs/assign?jobId=${job.id}`}>
                <Settings className="h-4 w-4 mr-2" />
                {job.logType ? 'Change Template' : 'Assign Template'}
              </Link>
            </Button>
            <Button asChild size="sm" className="border-gray-600 text-gray-300 hover:bg-gray-700">
              <Link href={`/admin/${job.id}/details`}>
                <FileText className="h-4 w-4 mr-2" />
                Details
              </Link>
            </Button>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

function CreateJobCard() {
  return (
    <Card className="border-dashed border-2 border-gray-600 hover:border-gray-500 transition-colors bg-[#1E1E1E]">
      <CardContent className="flex flex-col items-center justify-center p-8 text-center">
        <PlusCircle className="h-12 w-12 text-gray-400 mb-4" />
        <h3 className="text-lg font-medium text-white mb-2">Create New Job</h3>
        <p className="text-gray-300 mb-4">Start a new thermal logging project</p>
        <Button asChild className="bg-orange-600 hover:bg-orange-700 text-white border-0">
          <Link href="/admin/jobs/new">
            Create Job
          </Link>
        </Button>
      </CardContent>
    </Card>
  );
}

export default async function JobsPage() {
  // Temporarily disabled auth for debugging
  // await requireAdmin();
  
  const jobs = await getJobs();

  return (
    <div className="min-h-screen bg-[#111111]">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        {/* Header */}
        <div className="mb-8">
          <div className="flex items-center justify-between">
            <div>
              <h1 className="text-3xl font-bold text-white">
                Job Management
              </h1>
              <p className="mt-2 text-gray-300">
                View and manage thermal logging jobs and template assignments
              </p>
            </div>
            <div className="flex items-center gap-4">
              <Button asChild className="border-gray-600 text-gray-300 hover:bg-gray-700">
                <Link href="/admin/PROJ-001">
                  ← Back to Dashboard
                </Link>
              </Button>
              <Button asChild className="bg-orange-600 hover:bg-orange-700 text-white border-0">
                <Link href="/admin/jobs/new">
                  <PlusCircle className="h-4 w-4 mr-2" />
                  New Job
                </Link>
              </Button>
            </div>
          </div>
        </div>

        {/* Stats */}
        <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mb-8">
          <Card className="bg-[#1E1E1E] border-gray-800">
            <CardContent className="p-6">
              <div className="flex items-center">
                <FileText className="h-8 w-8 text-blue-400" />
                <div className="ml-4">
                  <p className="text-sm font-medium text-gray-300">Total Jobs</p>
                  <p className="text-2xl font-bold text-white">{jobs.length}</p>
                </div>
              </div>
            </CardContent>
          </Card>
          
          <Card className="bg-[#1E1E1E] border-gray-800">
            <CardContent className="p-6">
              <div className="flex items-center">
                <Calendar className="h-8 w-8 text-green-400" />
                <div className="ml-4">
                  <p className="text-sm font-medium text-gray-300">Active Jobs</p>
                  <p className="text-2xl font-bold text-white">
                    {jobs.filter(j => j.status === 'active').length}
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>
          
          <Card className="bg-[#1E1E1E] border-gray-800">
            <CardContent className="p-6">
              <div className="flex items-center">
                <Settings className="h-8 w-8 text-orange-500" />
                <div className="ml-4">
                  <p className="text-sm font-medium text-gray-300">With Templates</p>
                  <p className="text-2xl font-bold text-white">
                    {jobs.filter(j => j.logType).length}
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>
          
          <Card className="bg-[#1E1E1E] border-gray-800">
            <CardContent className="p-6">
              <div className="flex items-center">
                <PlusCircle className="h-8 w-8 text-purple-400" />
                <div className="ml-4">
                  <p className="text-sm font-medium text-gray-300">Need Templates</p>
                  <p className="text-2xl font-bold text-white">
                    {jobs.filter(j => !j.logType).length}
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Jobs Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          <CreateJobCard />
          {jobs.map((job) => (
            <JobCard key={job.id} job={job} />
          ))}
        </div>

        {jobs.length === 0 && (
          <div className="text-center py-12">
            <FileText className="h-12 w-12 text-gray-400 mx-auto mb-4" />
            <h3 className="text-lg font-medium text-white mb-2">No jobs found</h3>
            <p className="text-gray-300 mb-4">Get started by creating your first job</p>
            <Button asChild className="bg-orange-600 hover:bg-orange-700 text-white border-0">
              <Link href="/admin/jobs/new">
                Create Your First Job
              </Link>
            </Button>
          </div>
        )}
      </div>
    </div>
  );
}