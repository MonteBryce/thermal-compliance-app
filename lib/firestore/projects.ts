import {
  collection,
  doc,
  getDoc,
  getDocs,
  updateDoc,
  query,
  where,
  orderBy,
  Timestamp,
  arrayUnion,
  runTransaction,
  FirestoreDataConverter,
  QueryDocumentSnapshot,
} from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { ProjectAssignment } from '@/lib/types/logbuilder';

export interface Project {
  id: string;
  projectNumber: string;
  facility: string;
  tankId: string;
  assignedTemplateId?: string;
  assignedVersion?: number;
  assignedAt?: Timestamp;
  assignedBy?: string;
  usedTemplates: Array<{
    templateId: string;
    templateName: string;
    version: number;
    assignedAt: Timestamp;
    assignedBy: string;
  }>;
  // ... other existing project fields
}

const projectConverter: FirestoreDataConverter<Project> = {
  toFirestore(project: Project) {
    const { id, ...data } = project;
    return data;
  },
  fromFirestore(snapshot: QueryDocumentSnapshot): Project {
    const data = snapshot.data();
    return {
      id: snapshot.id,
      projectNumber: data.projectNumber || '',
      facility: data.facility || '',
      tankId: data.tankId || '',
      assignedTemplateId: data.assignedTemplateId,
      assignedVersion: data.assignedVersion,
      assignedAt: data.assignedAt,
      assignedBy: data.assignedBy,
      usedTemplates: data.usedTemplates || [],
      ...data, // Include any other existing fields
    };
  },
};

/**
 * Service for managing project template assignments
 */
export class ProjectService {
  private projectsRef = collection(db, 'projects').withConverter(projectConverter);

  /**
   * Get all projects
   */
  async getProjects(): Promise<Project[]> {
    const q = query(this.projectsRef, orderBy('projectNumber'));
    const snapshot = await getDocs(q);
    return snapshot.docs.map(doc => doc.data());
  }

  /**
   * Get project by ID
   */
  async getProject(projectId: string): Promise<Project | null> {
    const projectDoc = doc(this.projectsRef, projectId);
    const snapshot = await getDoc(projectDoc);
    return snapshot.exists() ? snapshot.data() : null;
  }

  /**
   * Get projects by assigned template
   */
  async getProjectsByTemplate(templateId: string): Promise<Project[]> {
    const q = query(
      this.projectsRef,
      where('assignedTemplateId', '==', templateId)
    );
    const snapshot = await getDocs(q);
    return snapshot.docs.map(doc => doc.data());
  }

  /**
   * Assign template version to project
   */
  async assignTemplate(
    projectId: string,
    templateId: string,
    templateName: string,
    version: number,
    assignedBy: string
  ): Promise<void> {
    await runTransaction(db, async (transaction) => {
      const projectDoc = doc(this.projectsRef, projectId);
      const projectSnap = await transaction.get(projectDoc);

      if (!projectSnap.exists()) {
        throw new Error('Project not found');
      }

      const now = Timestamp.now();
      const assignmentRecord = {
        templateId,
        templateName,
        version,
        assignedAt: now,
        assignedBy,
      };

      // Update current assignment
      transaction.update(projectDoc, {
        assignedTemplateId: templateId,
        assignedVersion: version,
        assignedAt: now,
        assignedBy,
      });

      // Add to history (append-only)
      transaction.update(projectDoc, {
        usedTemplates: arrayUnion(assignmentRecord),
      });
    });
  }

  /**
   * Remove template assignment from project
   */
  async removeTemplateAssignment(projectId: string): Promise<void> {
    const projectDoc = doc(this.projectsRef, projectId);
    await updateDoc(projectDoc, {
      assignedTemplateId: null,
      assignedVersion: null,
      assignedAt: null,
      assignedBy: null,
    });
  }

  /**
   * Get project template assignment history
   */
  async getProjectHistory(projectId: string): Promise<Project['usedTemplates']> {
    const project = await this.getProject(projectId);
    return project?.usedTemplates || [];
  }

  /**
   * Get projects with template assignments
   */
  async getProjectsWithAssignments(): Promise<Project[]> {
    const q = query(
      this.projectsRef,
      where('assignedTemplateId', '!=', null),
      orderBy('assignedAt', 'desc')
    );
    const snapshot = await getDocs(q);
    return snapshot.docs.map(doc => doc.data());
  }

  /**
   * Search projects
   */
  async searchProjects(searchTerm: string): Promise<Project[]> {
    const projects = await this.getProjects();
    const term = searchTerm.toLowerCase();
    
    return projects.filter(project => 
      project.projectNumber.toLowerCase().includes(term) ||
      project.facility.toLowerCase().includes(term) ||
      project.tankId.toLowerCase().includes(term)
    );
  }

  /**
   * Get project assignment summary
   */
  async getAssignmentSummary(): Promise<{
    totalProjects: number;
    assignedProjects: number;
    unassignedProjects: number;
    templateUsage: Record<string, number>;
  }> {
    const projects = await this.getProjects();
    const assigned = projects.filter(p => p.assignedTemplateId);
    
    const templateUsage: Record<string, number> = {};
    assigned.forEach(project => {
      if (project.assignedTemplateId) {
        templateUsage[project.assignedTemplateId] = 
          (templateUsage[project.assignedTemplateId] || 0) + 1;
      }
    });

    return {
      totalProjects: projects.length,
      assignedProjects: assigned.length,
      unassignedProjects: projects.length - assigned.length,
      templateUsage,
    };
  }

  /**
   * Validate template assignment
   */
  async validateAssignment(
    projectId: string,
    templateId: string,
    version: number
  ): Promise<{
    valid: boolean;
    errors: string[];
  }> {
    const errors: string[] = [];

    // Check if project exists
    const project = await this.getProject(projectId);
    if (!project) {
      errors.push('Project not found');
    }

    // Check if template version exists
    try {
      const templateDoc = doc(db, `log_templates/${templateId}/versions/${version}`);
      const templateSnap = await getDoc(templateDoc);
      if (!templateSnap.exists()) {
        errors.push('Template version not found');
      }
    } catch (error) {
      errors.push('Error validating template version');
    }

    return {
      valid: errors.length === 0,
      errors,
    };
  }

  /**
   * Get template usage statistics
   */
  async getTemplateUsageStats(templateId: string): Promise<{
    currentlyAssigned: number;
    totalAssignments: number;
    projects: Project[];
  }> {
    const allProjects = await this.getProjects();
    
    const currentlyAssigned = allProjects.filter(
      p => p.assignedTemplateId === templateId
    );

    const totalAssignments = allProjects.reduce((count, project) => {
      return count + project.usedTemplates.filter(
        usage => usage.templateId === templateId
      ).length;
    }, 0);

    return {
      currentlyAssigned: currentlyAssigned.length,
      totalAssignments,
      projects: currentlyAssigned,
    };
  }
}