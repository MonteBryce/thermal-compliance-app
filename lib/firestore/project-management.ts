import {
  collection,
  doc,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
  deleteDoc,
  query,
  where,
  orderBy,
  Timestamp,
  FirestoreDataConverter,
  QueryDocumentSnapshot,
} from 'firebase/firestore';
import { db } from '@/lib/firebase';

export interface ProjectData {
  id: string;
  projectName: string;
  projectNumber: string;
  location: string;
  unitNumber: string;
  workOrderNumber?: string;
  tankType?: string;
  facilityTarget?: string;
  operatingTemperature?: string;
  benzeneTarget?: string;
  product?: string;
  h2sAmpRequired?: boolean;
  status: 'Active' | 'Pending' | 'Completed' | 'Archived';
  createdAt: Timestamp;
  updatedAt: Timestamp;
  createdBy: string;
  projectStartDate?: Timestamp;
  metadata?: Record<string, any>;
  // Template assignment fields
  assignedTemplateId?: string;
  assignedVersion?: number;
  assignedAt?: Timestamp;
  assignedBy?: string;
  usedTemplates?: Array<{
    templateId: string;
    templateName: string;
    version: number;
    assignedAt: Timestamp;
    assignedBy: string;
  }>;
}

const projectConverter: FirestoreDataConverter<ProjectData> = {
  toFirestore(project: ProjectData) {
    const { id, ...data } = project;
    return data;
  },
  fromFirestore(snapshot: QueryDocumentSnapshot): ProjectData {
    const data = snapshot.data();
    return {
      id: snapshot.id,
      projectName: data.projectName || '',
      projectNumber: data.projectNumber || '',
      location: data.location || '',
      unitNumber: data.unitNumber || '',
      workOrderNumber: data.workOrderNumber || '',
      tankType: data.tankType || '',
      facilityTarget: data.facilityTarget || '',
      operatingTemperature: data.operatingTemperature || '',
      benzeneTarget: data.benzeneTarget || '',
      product: data.product || '',
      h2sAmpRequired: data.h2sAmpRequired || false,
      status: data.status || 'Pending',
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
      createdBy: data.createdBy || '',
      projectStartDate: data.projectStartDate,
      metadata: data.metadata || {},
      assignedTemplateId: data.assignedTemplateId,
      assignedVersion: data.assignedVersion,
      assignedAt: data.assignedAt,
      assignedBy: data.assignedBy,
      usedTemplates: data.usedTemplates || [],
    };
  },
};

/**
 * Comprehensive project management service for CRUD operations
 */
export class ProjectManagementService {
  private projectsRef = collection(db, 'projects').withConverter(projectConverter);

  /**
   * Create a new project
   */
  async createProject(
    projectData: Omit<ProjectData, 'id' | 'createdAt' | 'updatedAt'>,
    userId: string
  ): Promise<ProjectData> {
    const now = Timestamp.now();
    const projectDoc = doc(this.projectsRef);
    
    const newProject: ProjectData = {
      ...projectData,
      id: projectDoc.id,
      createdAt: now,
      updatedAt: now,
      createdBy: userId,
      status: projectData.status || 'Pending',
      usedTemplates: [],
    };

    await setDoc(projectDoc, newProject);
    return newProject;
  }

  /**
   * Get all projects
   */
  async getProjects(): Promise<ProjectData[]> {
    const q = query(this.projectsRef, orderBy('updatedAt', 'desc'));
    const snapshot = await getDocs(q);
    return snapshot.docs.map(doc => doc.data());
  }

  /**
   * Get project by ID
   */
  async getProject(projectId: string): Promise<ProjectData | null> {
    const projectDoc = doc(this.projectsRef, projectId);
    const snapshot = await getDoc(projectDoc);
    return snapshot.exists() ? snapshot.data() : null;
  }

  /**
   * Update an existing project
   */
  async updateProject(
    projectId: string,
    updates: Partial<Omit<ProjectData, 'id' | 'createdAt' | 'createdBy'>>
  ): Promise<void> {
    const projectDoc = doc(this.projectsRef, projectId);
    await updateDoc(projectDoc, {
      ...updates,
      updatedAt: Timestamp.now(),
    });
  }

  /**
   * Archive/Unarchive a project
   */
  async toggleArchiveProject(projectId: string): Promise<void> {
    const project = await this.getProject(projectId);
    if (!project) {
      throw new Error('Project not found');
    }

    const newStatus = project.status === 'Archived' ? 'Pending' : 'Archived';
    await this.updateProject(projectId, { status: newStatus });
  }

  /**
   * Delete a project (hard delete - use with caution)
   */
  async deleteProject(projectId: string): Promise<void> {
    const projectDoc = doc(this.projectsRef, projectId);
    await deleteDoc(projectDoc);
  }

  /**
   * Get projects by status
   */
  async getProjectsByStatus(status: ProjectData['status']): Promise<ProjectData[]> {
    const q = query(
      this.projectsRef,
      where('status', '==', status),
      orderBy('updatedAt', 'desc')
    );
    const snapshot = await getDocs(q);
    return snapshot.docs.map(doc => doc.data());
  }

  /**
   * Search projects by name, number, or location
   */
  async searchProjects(searchTerm: string): Promise<ProjectData[]> {
    const projects = await this.getProjects();
    const term = searchTerm.toLowerCase();
    
    return projects.filter(project => 
      project.projectName.toLowerCase().includes(term) ||
      project.projectNumber.toLowerCase().includes(term) ||
      project.location.toLowerCase().includes(term) ||
      project.unitNumber.toLowerCase().includes(term)
    );
  }

  /**
   * Get project statistics
   */
  async getProjectStats(): Promise<{
    total: number;
    active: number;
    pending: number;
    completed: number;
    archived: number;
    statusBreakdown: Record<string, number>;
    recentProjects: ProjectData[];
  }> {
    const projects = await this.getProjects();
    
    const statusBreakdown: Record<string, number> = {};
    projects.forEach(project => {
      statusBreakdown[project.status] = (statusBreakdown[project.status] || 0) + 1;
    });

    return {
      total: projects.length,
      active: statusBreakdown.Active || 0,
      pending: statusBreakdown.Pending || 0,
      completed: statusBreakdown.Completed || 0,
      archived: statusBreakdown.Archived || 0,
      statusBreakdown,
      recentProjects: projects.slice(0, 5),
    };
  }

  /**
   * Validate project data before creation/update
   */
  validateProject(projectData: Partial<ProjectData>): {
    valid: boolean;
    errors: string[];
  } {
    const errors: string[] = [];

    if (!projectData.projectName?.trim()) {
      errors.push('Project name is required');
    }

    if (!projectData.projectNumber?.trim()) {
      errors.push('Project number is required');
    }

    if (!projectData.location?.trim()) {
      errors.push('Location is required');
    }

    if (!projectData.unitNumber?.trim()) {
      errors.push('Unit number is required');
    }

    // Validate project number format (example: PRJ-2024-001)
    if (projectData.projectNumber && !/^[A-Z0-9-]+$/i.test(projectData.projectNumber)) {
      errors.push('Project number should only contain letters, numbers, and hyphens');
    }

    return {
      valid: errors.length === 0,
      errors,
    };
  }

  /**
   * Check if project number already exists
   */
  async isProjectNumberUnique(
    projectNumber: string,
    excludeProjectId?: string
  ): Promise<boolean> {
    const q = query(
      this.projectsRef,
      where('projectNumber', '==', projectNumber)
    );
    const snapshot = await getDocs(q);
    
    // If no existing project found, it's unique
    if (snapshot.empty) {
      return true;
    }

    // If we're updating an existing project, exclude it from the check
    if (excludeProjectId) {
      return snapshot.docs.every(doc => doc.id === excludeProjectId);
    }

    return false;
  }

  /**
   * Get projects with pagination
   */
  async getProjectsPaginated(
    limit: number = 20,
    offset: number = 0
  ): Promise<{
    projects: ProjectData[];
    hasMore: boolean;
    total: number;
  }> {
    const allProjects = await this.getProjects();
    const total = allProjects.length;
    const projects = allProjects.slice(offset, offset + limit);
    
    return {
      projects,
      hasMore: offset + limit < total,
      total,
    };
  }

  /**
   * Bulk update project statuses
   */
  async bulkUpdateStatus(
    projectIds: string[],
    newStatus: ProjectData['status']
  ): Promise<void> {
    const updatePromises = projectIds.map(id => 
      this.updateProject(id, { status: newStatus })
    );
    await Promise.all(updatePromises);
  }
}