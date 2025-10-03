'use client';

import { useState, useEffect } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger, DialogFooter } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { PlusCircle, Loader2, Grid, List, Edit, Eye, Archive } from 'lucide-react';
import { ProjectManagementService, ProjectData } from '@/lib/firestore/project-management';
import { useAuth } from '@/lib/auth';

export default function ProjectsPage() {
  const { user } = useAuth();
  const [projects, setProjects] = useState<ProjectData[]>([]);
  
  const [isCreateDialogOpen, setIsCreateDialogOpen] = useState(false);
  const [isEditDialogOpen, setIsEditDialogOpen] = useState(false);
  const [editingProject, setEditingProject] = useState<ProjectData | null>(null);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState(false);
  const [viewMode, setViewMode] = useState<'table' | 'grid'>('grid');
  const [formData, setFormData] = useState({
    projectName: '',
    projectNumber: '',
    location: '',
    unitNumber: '',
    workOrderNumber: '',
    tankType: '',
    facilityTarget: '',
    operatingTemperature: '',
    benzeneTarget: '',
    product: '',
    h2sAmpRequired: false,
  });

  const projectService = new ProjectManagementService();

  // Load projects on component mount
  useEffect(() => {
    loadProjects();
  }, []);

  const loadProjects = async () => {
    try {
      setLoading(true);
      const projectList = await projectService.getProjects();
      setProjects(projectList);
    } catch (error) {
      console.error('Error loading projects:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleInputChange = (field: string, value: string | boolean) => {
    setFormData(prev => ({ ...prev, [field]: value }));
  };

  const resetFormData = () => {
    setFormData({
      projectName: '',
      projectNumber: '',
      location: '',
      unitNumber: '',
      workOrderNumber: '',
      tankType: '',
      facilityTarget: '',
      operatingTemperature: '',
      benzeneTarget: '',
      product: '',
      h2sAmpRequired: false,
    });
  };

  const handleCreateProject = async () => {
    if (!user) {
      console.error('User not authenticated');
      return;
    }

    try {
      setActionLoading(true);
      
      // Validate project number uniqueness
      const isUnique = await projectService.isProjectNumberUnique(formData.projectNumber);
      if (!isUnique) {
        alert('Project number already exists. Please choose a different one.');
        return;
      }

      const newProject = await projectService.createProject({
        projectName: formData.projectName,
        projectNumber: formData.projectNumber,
        location: formData.location,
        unitNumber: formData.unitNumber,
        workOrderNumber: formData.workOrderNumber,
        tankType: formData.tankType,
        facilityTarget: formData.facilityTarget,
        operatingTemperature: formData.operatingTemperature,
        benzeneTarget: formData.benzeneTarget,
        product: formData.product,
        h2sAmpRequired: formData.h2sAmpRequired,
        status: 'Pending',
      }, user.uid);
      
      setProjects(prev => [newProject, ...prev]);
      setIsCreateDialogOpen(false);
      resetFormData();
    } catch (error) {
      console.error('Error creating project:', error);
      alert('Failed to create project. Please try again.');
    } finally {
      setActionLoading(false);
    }
  };

  const handleEditProject = (project: ProjectData) => {
    setEditingProject(project);
    setFormData({
      projectName: project.projectName,
      projectNumber: project.projectNumber,
      location: project.location,
      unitNumber: project.unitNumber,
      workOrderNumber: project.workOrderNumber || '',
      tankType: project.tankType || '',
      facilityTarget: project.facilityTarget || '',
      operatingTemperature: project.operatingTemperature || '',
      benzeneTarget: project.benzeneTarget || '',
      product: project.product || '',
      h2sAmpRequired: project.h2sAmpRequired || false,
    });
    setIsEditDialogOpen(true);
  };

  const handleUpdateProject = async () => {
    if (!editingProject) return;
    
    try {
      setActionLoading(true);
      
      // Check if project number changed and if it's unique
      if (formData.projectNumber !== editingProject.projectNumber) {
        const isUnique = await projectService.isProjectNumberUnique(
          formData.projectNumber, 
          editingProject.id
        );
        if (!isUnique) {
          alert('Project number already exists. Please choose a different one.');
          return;
        }
      }

      await projectService.updateProject(editingProject.id, {
        projectName: formData.projectName,
        projectNumber: formData.projectNumber,
        location: formData.location,
        unitNumber: formData.unitNumber,
        workOrderNumber: formData.workOrderNumber,
        tankType: formData.tankType,
        facilityTarget: formData.facilityTarget,
        operatingTemperature: formData.operatingTemperature,
        benzeneTarget: formData.benzeneTarget,
        product: formData.product,
        h2sAmpRequired: formData.h2sAmpRequired,
        status: editingProject.status,
      });
      
      // Reload projects to get the updated data
      await loadProjects();
      
      setIsEditDialogOpen(false);
      setEditingProject(null);
      resetFormData();
    } catch (error) {
      console.error('Error updating project:', error);
      alert('Failed to update project. Please try again.');
    } finally {
      setActionLoading(false);
    }
  };

  const handleArchiveProject = async (project: ProjectData) => {
    try {
      setActionLoading(true);
      await projectService.toggleArchiveProject(project.id);
      await loadProjects(); // Reload to get updated status
    } catch (error) {
      console.error('Error archiving project:', error);
      alert('Failed to archive project. Please try again.');
    } finally {
      setActionLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#111111] text-white p-4 sm:p-6 lg:p-8">
      <div className="max-w-7xl mx-auto">
        <div className="mb-6 sm:mb-8">
          <a href="/admin" className="text-blue-400 hover:text-blue-300 mb-4 inline-block text-sm sm:text-base">
            ← Back to Dashboard
          </a>
          <div className="flex flex-col sm:flex-row sm:justify-between sm:items-center gap-4">
            <div>
              <h1 className="text-2xl sm:text-3xl font-bold">Projects</h1>
              <p className="text-gray-400 mt-1 sm:mt-2 text-sm sm:text-base">Manage project templates and operator assignments</p>
            </div>
            <Dialog open={isCreateDialogOpen} onOpenChange={setIsCreateDialogOpen}>
              <DialogTrigger asChild>
                <Button className="bg-orange-600 hover:bg-orange-700 text-white border-0 w-full sm:w-auto">
                  <PlusCircle className="h-4 w-4 mr-2" />
                  <span className="sm:hidden">New</span>
                  <span className="hidden sm:inline">New Project</span>
                </Button>
              </DialogTrigger>
              <DialogContent className="bg-[#1E1E1E] border-gray-800 text-white max-w-4xl w-[95vw] sm:w-full max-h-[90vh] overflow-y-auto">
                <DialogHeader>
                  <DialogTitle className="text-xl font-semibold">Create New Project</DialogTitle>
                </DialogHeader>
                
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 py-4">
                  <div className="space-y-2">
                    <Label htmlFor="projectName" className="text-gray-300">Project Name</Label>
                    <Input
                      id="projectName"
                      value={formData.projectName}
                      onChange={(e) => handleInputChange('projectName', e.target.value)}
                      className="bg-gray-800 border-gray-600 text-white"
                      placeholder="Enter project name"
                    />
                  </div>
                  
                  <div className="space-y-2">
                    <Label htmlFor="projectNumber" className="text-gray-300">Project Number</Label>
                    <Input
                      id="projectNumber"
                      value={formData.projectNumber}
                      onChange={(e) => handleInputChange('projectNumber', e.target.value)}
                      className="bg-gray-800 border-gray-600 text-white"
                      placeholder="PRJ-2024-001"
                    />
                  </div>
                  
                  <div className="space-y-2">
                    <Label htmlFor="location" className="text-gray-300">Location</Label>
                    <Input
                      id="location"
                      value={formData.location}
                      onChange={(e) => handleInputChange('location', e.target.value)}
                      className="bg-gray-800 border-gray-600 text-white"
                      placeholder="Project location"
                    />
                  </div>
                  
                  <div className="space-y-2">
                    <Label htmlFor="unitNumber" className="text-gray-300">Unit Number</Label>
                    <Input
                      id="unitNumber"
                      value={formData.unitNumber}
                      onChange={(e) => handleInputChange('unitNumber', e.target.value)}
                      className="bg-gray-800 border-gray-600 text-white"
                      placeholder="Unit-A1"
                    />
                  </div>
                  
                  <div className="space-y-2">
                    <Label htmlFor="workOrderNumber" className="text-gray-300">Work Order Number</Label>
                    <Input
                      id="workOrderNumber"
                      value={formData.workOrderNumber}
                      onChange={(e) => handleInputChange('workOrderNumber', e.target.value)}
                      className="bg-gray-800 border-gray-600 text-white"
                      placeholder="WO-2024-001"
                    />
                  </div>
                  
                  <div className="space-y-2">
                    <Label htmlFor="tankType" className="text-gray-300">Tank Type</Label>
                    <Select onValueChange={(value) => handleInputChange('tankType', value)}>
                      <SelectTrigger className="bg-gray-800 border-gray-600 text-white">
                        <SelectValue placeholder="Select tank type" />
                      </SelectTrigger>
                      <SelectContent className="bg-gray-800 border-gray-600">
                        <SelectItem value="crude">Crude Oil</SelectItem>
                        <SelectItem value="refined">Refined Product</SelectItem>
                        <SelectItem value="water">Water</SelectItem>
                        <SelectItem value="chemical">Chemical</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                  
                  <div className="space-y-2">
                    <Label htmlFor="facilityTarget" className="text-gray-300">Facility Target</Label>
                    <Input
                      id="facilityTarget"
                      value={formData.facilityTarget}
                      onChange={(e) => handleInputChange('facilityTarget', e.target.value)}
                      className="bg-gray-800 border-gray-600 text-white"
                      placeholder="Target facility"
                    />
                  </div>
                  
                  <div className="space-y-2">
                    <Label htmlFor="operatingTemperature" className="text-gray-300">Operating Temperature</Label>
                    <Input
                      id="operatingTemperature"
                      value={formData.operatingTemperature}
                      onChange={(e) => handleInputChange('operatingTemperature', e.target.value)}
                      className="bg-gray-800 border-gray-600 text-white"
                      placeholder="°F or °C"
                    />
                  </div>
                  
                  <div className="space-y-2">
                    <Label htmlFor="benzeneTarget" className="text-gray-300">Benzene Target</Label>
                    <Input
                      id="benzeneTarget"
                      value={formData.benzeneTarget}
                      onChange={(e) => handleInputChange('benzeneTarget', e.target.value)}
                      className="bg-gray-800 border-gray-600 text-white"
                      placeholder="ppm or %"
                    />
                  </div>
                  
                  <div className="space-y-2">
                    <Label htmlFor="product" className="text-gray-300">Product</Label>
                    <Input
                      id="product"
                      value={formData.product}
                      onChange={(e) => handleInputChange('product', e.target.value)}
                      className="bg-gray-800 border-gray-600 text-white"
                      placeholder="Product type"
                    />
                  </div>
                  
                  <div className="space-y-2 flex items-center">
                    <input
                      type="checkbox"
                      id="h2sAmpRequired"
                      checked={formData.h2sAmpRequired}
                      onChange={(e) => handleInputChange('h2sAmpRequired', e.target.checked)}
                      className="mr-2"
                    />
                    <Label htmlFor="h2sAmpRequired" className="text-gray-300">H2S Amp Required</Label>
                  </div>
                </div>
                
                <DialogFooter>
                  <Button 
                    variant="outline" 
                    onClick={() => setIsCreateDialogOpen(false)}
                    className="border-gray-600 text-gray-300 hover:bg-gray-700"
                  >
                    Cancel
                  </Button>
                  <Button 
                    onClick={handleCreateProject}
                    className="bg-orange-600 hover:bg-orange-700 text-white border-0"
                    disabled={!formData.projectName || !formData.projectNumber || actionLoading}
                  >
                    {actionLoading && <Loader2 className="h-4 w-4 mr-2 animate-spin" />}
                    {actionLoading ? 'Creating...' : 'Create Project'}
                  </Button>
                </DialogFooter>
              </DialogContent>
            </Dialog>

            {/* Edit Project Dialog */}
            <Dialog open={isEditDialogOpen} onOpenChange={setIsEditDialogOpen}>
              <DialogContent className="bg-[#1E1E1E] border-gray-800 text-white max-w-4xl w-[95vw] sm:w-full max-h-[90vh] overflow-y-auto">
                <DialogHeader>
                  <DialogTitle className="text-xl font-semibold">
                    Edit Project: {editingProject?.projectName}
                  </DialogTitle>
                </DialogHeader>
                
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 py-4">
                  <div className="space-y-2">
                    <Label htmlFor="edit-projectName" className="text-gray-300">Project Name</Label>
                    <Input
                      id="edit-projectName"
                      value={formData.projectName}
                      onChange={(e) => handleInputChange('projectName', e.target.value)}
                      className="bg-gray-800 border-gray-600 text-white"
                      placeholder="Enter project name"
                    />
                  </div>
                  
                  <div className="space-y-2">
                    <Label htmlFor="edit-projectNumber" className="text-gray-300">Project Number</Label>
                    <Input
                      id="edit-projectNumber"
                      value={formData.projectNumber}
                      onChange={(e) => handleInputChange('projectNumber', e.target.value)}
                      className="bg-gray-800 border-gray-600 text-white"
                      placeholder="PRJ-2024-001"
                    />
                  </div>
                  
                  <div className="space-y-2">
                    <Label htmlFor="edit-location" className="text-gray-300">Location</Label>
                    <Input
                      id="edit-location"
                      value={formData.location}
                      onChange={(e) => handleInputChange('location', e.target.value)}
                      className="bg-gray-800 border-gray-600 text-white"
                      placeholder="Project location"
                    />
                  </div>
                  
                  <div className="space-y-2">
                    <Label htmlFor="edit-unitNumber" className="text-gray-300">Unit Number</Label>
                    <Input
                      id="edit-unitNumber"
                      value={formData.unitNumber}
                      onChange={(e) => handleInputChange('unitNumber', e.target.value)}
                      className="bg-gray-800 border-gray-600 text-white"
                      placeholder="Unit-A1"
                    />
                  </div>

                  <div className="space-y-2">
                    <Label htmlFor="edit-status" className="text-gray-300">Status</Label>
                    <Select 
                      value={editingProject?.status} 
                      onValueChange={(value) => {
                        if (editingProject) {
                          setEditingProject({...editingProject, status: value as Project['status']});
                        }
                      }}
                    >
                      <SelectTrigger className="bg-gray-800 border-gray-600 text-white">
                        <SelectValue placeholder="Select status" />
                      </SelectTrigger>
                      <SelectContent className="bg-gray-800 border-gray-600">
                        <SelectItem value="Active">Active</SelectItem>
                        <SelectItem value="Pending">Pending</SelectItem>
                        <SelectItem value="Completed">Completed</SelectItem>
                        <SelectItem value="Archived">Archived</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                </div>
                
                <DialogFooter>
                  <Button 
                    variant="outline" 
                    onClick={() => {
                      setIsEditDialogOpen(false);
                      setEditingProject(null);
                      resetFormData();
                    }}
                    className="border-gray-600 text-gray-300 hover:bg-gray-700"
                  >
                    Cancel
                  </Button>
                  <Button 
                    onClick={handleUpdateProject}
                    className="bg-orange-600 hover:bg-orange-700 text-white border-0"
                    disabled={!formData.projectName || !formData.projectNumber || actionLoading}
                  >
                    {actionLoading && <Loader2 className="h-4 w-4 mr-2 animate-spin" />}
                    {actionLoading ? 'Updating...' : 'Update Project'}
                  </Button>
                </DialogFooter>
              </DialogContent>
            </Dialog>
          </div>
        </div>

        {/* View Toggle Controls */}
        {!loading && projects.length > 0 && (
          <div className="flex justify-between items-center mb-4">
            <div className="text-sm text-gray-400">
              {projects.length} project{projects.length !== 1 ? 's' : ''} found
            </div>
            <div className="flex items-center gap-2">
              <Button
                variant={viewMode === 'table' ? 'default' : 'outline'}
                size="sm"
                onClick={() => setViewMode('table')}
                className="hidden sm:flex border-gray-600 text-gray-300"
              >
                <List className="h-4 w-4 mr-1" />
                Table
              </Button>
              <Button
                variant={viewMode === 'grid' ? 'default' : 'outline'}
                size="sm"
                onClick={() => setViewMode('grid')}
                className="border-gray-600 text-gray-300"
              >
                <Grid className="h-4 w-4 mr-1" />
                <span className="sm:hidden">View</span>
                <span className="hidden sm:inline">Cards</span>
              </Button>
            </div>
          </div>
        )}

        <div className="bg-[#1E1E1E] border border-gray-800 rounded-lg overflow-hidden">
          {loading ? (
            <div className="flex items-center justify-center py-12">
              <Loader2 className="h-8 w-8 animate-spin text-gray-400" />
              <span className="ml-2 text-gray-400">Loading projects...</span>
            </div>
          ) : projects.length === 0 ? (
            <div className="text-center py-12">
              <p className="text-gray-400 mb-4">No projects found</p>
              <Button 
                onClick={() => setIsCreateDialogOpen(true)}
                className="bg-orange-600 hover:bg-orange-700 text-white border-0"
              >
                <PlusCircle className="h-4 w-4 mr-2" />
                Create Your First Project
              </Button>
            </div>
          ) : viewMode === 'table' ? (
            /* Desktop Table View */
            <div className="hidden sm:block overflow-x-auto">
              <table className="w-full">
                <thead className="bg-gray-800">
                  <tr>
                    <th className="px-4 lg:px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">
                      Project Name
                    </th>
                    <th className="px-4 lg:px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">
                      Number
                    </th>
                    <th className="px-4 lg:px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">
                      Location
                    </th>
                    <th className="px-4 lg:px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">
                      Status
                    </th>
                    <th className="px-4 lg:px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider hidden lg:table-cell">
                      Templates
                    </th>
                    <th className="px-4 lg:px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider hidden lg:table-cell">
                      Created
                    </th>
                    <th className="px-4 lg:px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-800">
                  {projects.map((project) => (
                    <tr key={project.id} className="hover:bg-gray-800/50">
                      <td className="px-4 lg:px-6 py-4">
                        <div className="text-sm font-medium text-white">{project.projectName}</div>
                        <div className="text-xs text-gray-400">{project.unitNumber}</div>
                      </td>
                      <td className="px-4 lg:px-6 py-4">
                        <div className="text-sm text-gray-300">{project.projectNumber}</div>
                      </td>
                      <td className="px-4 lg:px-6 py-4">
                        <div className="text-sm text-gray-300">{project.location}</div>
                      </td>
                      <td className="px-4 lg:px-6 py-4">
                        <span className={`px-2 py-1 text-xs rounded-full ${
                          project.status === 'Active' 
                            ? 'bg-green-600/20 text-green-400' 
                            : project.status === 'Pending'
                            ? 'bg-yellow-600/20 text-yellow-400'
                            : project.status === 'Completed'
                            ? 'bg-blue-600/20 text-blue-400'
                            : 'bg-gray-600/20 text-gray-400'
                        }`}>
                          {project.status}
                        </span>
                      </td>
                      <td className="px-4 lg:px-6 py-4 text-sm text-gray-300 hidden lg:table-cell">
                        {project.assignedTemplateId ? 1 : 0}
                      </td>
                      <td className="px-4 lg:px-6 py-4 text-sm text-gray-300 hidden lg:table-cell">
                        {project.createdAt?.toDate().toLocaleDateString() || 'N/A'}
                      </td>
                      <td className="px-4 lg:px-6 py-4 text-sm">
                        <div className="flex items-center gap-1">
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => handleEditProject(project)}
                            disabled={actionLoading}
                            className="h-8 w-8 p-0 text-blue-400 hover:text-blue-300 hover:bg-blue-500/10"
                          >
                            <Edit className="h-4 w-4" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => window.open(`/admin/${project.id}`, '_blank')}
                            className="h-8 w-8 p-0 text-gray-400 hover:text-gray-300 hover:bg-gray-700/50"
                          >
                            <Eye className="h-4 w-4" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => handleArchiveProject(project)}
                            disabled={actionLoading}
                            className={`h-8 w-8 p-0 ${
                              project.status === 'Archived' 
                                ? 'text-green-400 hover:text-green-300 hover:bg-green-500/10' 
                                : 'text-red-400 hover:text-red-300 hover:bg-red-500/10'
                            }`}
                          >
                            <Archive className="h-4 w-4" />
                          </Button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : (
            /* Grid/Card View */
            <div className="p-4 sm:p-6">
              <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4 sm:gap-6">
                {projects.map((project) => (
                  <div
                    key={project.id}
                    className="bg-gray-800/50 border border-gray-700 rounded-lg p-4 sm:p-6 hover:bg-gray-800/70 transition-colors"
                  >
                    {/* Card Header */}
                    <div className="flex items-start justify-between mb-4">
                      <div className="flex-1 min-w-0">
                        <h3 className="text-lg font-semibold text-white truncate">
                          {project.projectName}
                        </h3>
                        <p className="text-sm text-gray-400 mt-1">
                          {project.projectNumber}
                        </p>
                      </div>
                      <span className={`px-2 py-1 text-xs rounded-full flex-shrink-0 ml-2 ${
                        project.status === 'Active' 
                          ? 'bg-green-600/20 text-green-400' 
                          : project.status === 'Pending'
                          ? 'bg-yellow-600/20 text-yellow-400'
                          : project.status === 'Completed'
                          ? 'bg-blue-600/20 text-blue-400'
                          : 'bg-gray-600/20 text-gray-400'
                      }`}>
                        {project.status}
                      </span>
                    </div>

                    {/* Card Content */}
                    <div className="space-y-3 mb-4">
                      <div className="flex items-center text-sm">
                        <span className="text-gray-400 w-20">Location:</span>
                        <span className="text-white">{project.location}</span>
                      </div>
                      <div className="flex items-center text-sm">
                        <span className="text-gray-400 w-20">Unit:</span>
                        <span className="text-white">{project.unitNumber}</span>
                      </div>
                      <div className="flex items-center text-sm">
                        <span className="text-gray-400 w-20">Templates:</span>
                        <span className="text-white">{project.assignedTemplateId ? 1 : 0}</span>
                      </div>
                      <div className="flex items-center text-sm">
                        <span className="text-gray-400 w-20">Created:</span>
                        <span className="text-white">
                          {project.createdAt?.toDate().toLocaleDateString() || 'N/A'}
                        </span>
                      </div>
                    </div>

                    {/* Card Actions */}
                    <div className="flex items-center gap-2 pt-3 border-t border-gray-700">
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => handleEditProject(project)}
                        disabled={actionLoading}
                        className="flex-1 border-gray-600 text-blue-400 hover:bg-blue-500/10 hover:border-blue-500"
                      >
                        <Edit className="h-4 w-4 mr-2" />
                        Edit
                      </Button>
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => window.open(`/admin/${project.id}`, '_blank')}
                        className="border-gray-600 text-gray-400 hover:bg-gray-700/50"
                      >
                        <Eye className="h-4 w-4" />
                      </Button>
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => handleArchiveProject(project)}
                        disabled={actionLoading}
                        className={`border-gray-600 ${
                          project.status === 'Archived' 
                            ? 'text-green-400 hover:bg-green-500/10 hover:border-green-500' 
                            : 'text-red-400 hover:bg-red-500/10 hover:border-red-500'
                        }`}
                      >
                        <Archive className="h-4 w-4" />
                      </Button>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}