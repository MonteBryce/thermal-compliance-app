import {
  collection,
  doc,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
  addDoc,
  query,
  where,
  orderBy,
  limit,
  writeBatch,
  runTransaction,
  Timestamp,
  DocumentReference,
} from 'firebase/firestore';
import { db } from '@/lib/firebase';
import {
  LogTemplate,
  TemplateVersion,
  TemplateSnapshot,
  FacilityPreset,
  VersionDiff,
  generateTemplateHash,
  computeVersionDiff,
  MASTER_FIELDS,
  filterFieldsByConditions,
  Toggles,
  Targets,
} from './versioned-types';

export class VersionedTemplateService {
  // Create a new template with initial version
  static async createTemplate(data: {
    name: string;
    templateKey: string;
    gasFamily: 'methane' | 'pentane';
    createdBy: string;
    initialVersion: Omit<TemplateVersion, 'version' | 'createdAt' | 'createdBy' | 'hash'>;
  }): Promise<{ templateId: string; versionId: string }> {
    return await runTransaction(db, async (transaction) => {
      // Create template document
      const templateRef = doc(collection(db, 'logTemplates'));
      const template: LogTemplate = {
        name: data.name,
        templateKey: data.templateKey,
        gasFamily: data.gasFamily,
        createdAt: Timestamp.now(),
        createdBy: data.createdBy,
      };
      
      // Create initial version
      const versionRef = doc(collection(db, `logTemplates/${templateRef.id}/versions`));
      const version: TemplateVersion = {
        ...data.initialVersion,
        version: 1,
        createdAt: Timestamp.now(),
        createdBy: data.createdBy,
        hash: '',
      };
      
      // Generate hash after setting other fields
      version.hash = generateTemplateHash(version);
      
      // Set active version reference
      template.activeVersionRef = versionRef.id;
      
      transaction.set(templateRef, template);
      transaction.set(versionRef, version);
      
      return { templateId: templateRef.id, versionId: versionRef.id };
    });
  }
  
  // Clone existing version to create new draft (copy-on-write)
  static async cloneVersion(
    templateId: string,
    baseVersionId: string,
    createdBy: string,
    changelog?: string
  ): Promise<string> {
    return await runTransaction(db, async (transaction) => {
      // Get base version
      const baseVersionRef = doc(db, `logTemplates/${templateId}/versions`, baseVersionId);
      const baseVersionDoc = await transaction.get(baseVersionRef);
      
      if (!baseVersionDoc.exists()) {
        throw new Error('Base version not found');
      }
      
      const baseVersion = baseVersionDoc.data() as TemplateVersion;
      
      // Get all versions to determine next version number
      const versionsQuery = query(
        collection(db, `logTemplates/${templateId}/versions`),
        orderBy('version', 'desc'),
        limit(1)
      );
      const versionsSnapshot = await getDocs(versionsQuery);
      const latestVersion = versionsSnapshot.docs[0]?.data() as TemplateVersion;
      const nextVersion = (latestVersion?.version || 0) + 1;
      
      // Create new version
      const newVersionRef = doc(collection(db, `logTemplates/${templateId}/versions`));
      const newVersion: TemplateVersion = {
        ...baseVersion,
        version: nextVersion,
        status: 'draft',
        derivedFromVersion: baseVersion.version,
        createdAt: Timestamp.now(),
        createdBy,
        changelog,
        hash: '',
      };
      
      // Generate new hash
      newVersion.hash = generateTemplateHash(newVersion);
      
      transaction.set(newVersionRef, newVersion);
      
      return newVersionRef.id;
    });
  }
  
  // Publish a draft version (make it active)
  static async publishVersion(
    templateId: string,
    versionId: string,
    publishedBy: string
  ): Promise<void> {
    await runTransaction(db, async (transaction) => {
      const versionRef = doc(db, `logTemplates/${templateId}/versions`, versionId);
      const templateRef = doc(db, 'logTemplates', templateId);
      
      const versionDoc = await transaction.get(versionRef);
      if (!versionDoc.exists()) {
        throw new Error('Version not found');
      }
      
      const version = versionDoc.data() as TemplateVersion;
      if (version.status !== 'draft') {
        throw new Error('Can only publish draft versions');
      }
      
      // Update version status
      transaction.update(versionRef, {
        status: 'active',
        publishedAt: Timestamp.now(),
        publishedBy,
      });
      
      // Update template's active version reference
      transaction.update(templateRef, {
        activeVersionRef: versionId,
        updatedAt: Timestamp.now(),
      });
      
      // Deprecate previous active version
      const templateDoc = await transaction.get(templateRef);
      const template = templateDoc.data() as LogTemplate;
      if (template.activeVersionRef && template.activeVersionRef !== versionId) {
        const prevActiveRef = doc(db, `logTemplates/${templateId}/versions`, template.activeVersionRef);
        transaction.update(prevActiveRef, { status: 'deprecated' });
      }
    });
  }
  
  // Lock a version (prevent any future changes)
  static async lockVersion(templateId: string, versionId: string): Promise<void> {
    const versionRef = doc(db, `logTemplates/${templateId}/versions`, versionId);
    await updateDoc(versionRef, { status: 'locked' });
  }
  
  // Get template with active version
  static async getTemplateWithActiveVersion(templateId: string): Promise<{
    template: LogTemplate;
    activeVersion: TemplateVersion | null;
  }> {
    const templateDoc = await getDoc(doc(db, 'logTemplates', templateId));
    if (!templateDoc.exists()) {
      throw new Error('Template not found');
    }
    
    const template = { id: templateDoc.id, ...templateDoc.data() } as LogTemplate;
    let activeVersion: TemplateVersion | null = null;
    
    if (template.activeVersionRef) {
      const activeVersionDoc = await getDoc(
        doc(db, `logTemplates/${templateId}/versions`, template.activeVersionRef)
      );
      if (activeVersionDoc.exists()) {
        activeVersion = { id: activeVersionDoc.id, ...activeVersionDoc.data() } as TemplateVersion;
      }
    }
    
    return { template, activeVersion };
  }
  
  // Get all versions of a template
  static async getTemplateVersions(templateId: string): Promise<TemplateVersion[]> {
    const versionsQuery = query(
      collection(db, `logTemplates/${templateId}/versions`),
      orderBy('version', 'desc')
    );
    const snapshot = await getDocs(versionsQuery);
    return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as TemplateVersion));
  }
  
  // Update a draft version
  static async updateDraftVersion(
    templateId: string,
    versionId: string,
    updates: Partial<TemplateVersion>
  ): Promise<void> {
    const versionRef = doc(db, `logTemplates/${templateId}/versions`, versionId);
    const versionDoc = await getDoc(versionRef);
    
    if (!versionDoc.exists()) {
      throw new Error('Version not found');
    }
    
    const version = versionDoc.data() as TemplateVersion;
    if (version.status !== 'draft') {
      throw new Error('Can only update draft versions');
    }
    
    const updatedVersion = { ...version, ...updates };
    updatedVersion.hash = generateTemplateHash(updatedVersion);
    
    await updateDoc(versionRef, {
      ...updates,
      hash: updatedVersion.hash,
      updatedAt: Timestamp.now(),
    });
  }
  
  // Assign template version to jobs
  static async assignToJobs(
    templateId: string,
    versionId: string,
    jobIds: string[]
  ): Promise<void> {
    const versionDoc = await getDoc(doc(db, `logTemplates/${templateId}/versions`, versionId));
    if (!versionDoc.exists()) {
      throw new Error('Version not found');
    }
    
    const version = versionDoc.data() as TemplateVersion;
    const snapshot: TemplateSnapshot = {
      version: version.version,
      toggles: version.toggles,
      gasType: version.gasType,
      hourlyColumns: this.generateHourlyColumns(version),
      targets: version.targets,
      hash: version.hash,
      templateKey: '',
    };
    
    const batch = writeBatch(db);
    
    // Update each job with template snapshot
    for (const jobId of jobIds) {
      const jobRef = doc(db, 'jobs', jobId);
      batch.update(jobRef, {
        templateId,
        templateVersionRef: versionId,
        templateSnapshot: snapshot,
        assignedAt: Timestamp.now(),
      });
    }
    
    // Lock the version if it's being assigned
    if (version.status !== 'locked') {
      const versionRef = doc(db, `logTemplates/${templateId}/versions`, versionId);
      batch.update(versionRef, { status: 'locked' });
    }
    
    await batch.commit();
  }
  
  // Generate hourly columns based on version configuration
  private static generateHourlyColumns(version: TemplateVersion): string[] {
    const filteredFields = filterFieldsByConditions(
      version.fields,
      version.gasType,
      version.toggles
    );
    
    return filteredFields.map(field => `${field.label}${field.unit ? ` (${field.unit})` : ''}`);
  }
  
  // Validate version before publishing
  static validateVersion(version: TemplateVersion): { valid: boolean; errors: string[] } {
    const errors: string[] = [];
    
    // Check required fields
    const requiredFields = version.fields.filter(f => f.required);
    if (requiredFields.length === 0) {
      errors.push('At least one required field must be defined');
    }
    
    // Check targets for enabled features
    if (version.toggles.hasH2S && !version.targets.h2sPPM) {
      errors.push('H₂S target required when H₂S monitoring is enabled');
    }
    
    if (version.toggles.hasBenzene && !version.targets.benzenePPM) {
      errors.push('Benzene target required when Benzene monitoring is enabled');
    }
    
    if (version.toggles.hasLEL && !version.targets.lelPct) {
      errors.push('LEL target required when LEL monitoring is enabled');
    }
    
    // Check operation range
    if (!version.operationRange.start || !version.operationRange.end) {
      errors.push('Operation range must be defined');
    }
    
    // Check Excel template path
    if (!version.excelTemplatePath) {
      errors.push('Excel template file must be uploaded');
    }
    
    return { valid: errors.length === 0, errors };
  }
  
  // Compute diff between versions
  static async getVersionDiff(
    templateId: string,
    oldVersionId: string,
    newVersionId: string
  ): Promise<VersionDiff> {
    const [oldDoc, newDoc] = await Promise.all([
      getDoc(doc(db, `logTemplates/${templateId}/versions`, oldVersionId)),
      getDoc(doc(db, `logTemplates/${templateId}/versions`, newVersionId)),
    ]);
    
    if (!oldDoc.exists() || !newDoc.exists()) {
      throw new Error('Version not found');
    }
    
    const oldVersion = oldDoc.data() as TemplateVersion;
    const newVersion = newDoc.data() as TemplateVersion;
    
    return computeVersionDiff(oldVersion, newVersion);
  }
  
  // Facility presets management
  static async getFacilityPresets(): Promise<FacilityPreset[]> {
    const snapshot = await getDocs(collection(db, 'facilityPresets'));
    return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as FacilityPreset));
  }
  
  static async createFacilityPreset(preset: Omit<FacilityPreset, 'id' | 'createdAt'>): Promise<string> {
    const docRef = await addDoc(collection(db, 'facilityPresets'), {
      ...preset,
      createdAt: Timestamp.now(),
    });
    return docRef.id;
  }
  
  // Get template with default configuration
  static getDefaultTemplateVersion(gasType: 'methane' | 'pentane'): Omit<TemplateVersion, 'version' | 'createdAt' | 'createdBy' | 'hash'> {
    const defaultToggles: Toggles = {
      hasH2S: false,
      hasBenzene: false,
      hasLEL: false,
      hasO2: false,
      isRefill: false,
      is12hr: false,
      isFinal: false,
    };
    
    const defaultTargets: Targets = {};
    
    return {
      status: 'draft',
      toggles: defaultToggles,
      gasType,
      fields: filterFieldsByConditions(MASTER_FIELDS, gasType, defaultToggles),
      targets: defaultTargets,
      ui: {
        groups: ['core', 'monitoring', 'operator'],
        layout: 'standard',
      },
      excelTemplatePath: '',
      operationRange: {
        start: 'B12',
        end: 'N28',
        sheet: 'Sheet1',
      },
    };
  }
}