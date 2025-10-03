import {
  collection,
  doc,
  getDoc,
  getDocs,
  addDoc,
  updateDoc,
  deleteDoc,
  query,
  where,
  orderBy,
  limit,
  Timestamp,
  DocumentSnapshot,
  QueryDocumentSnapshot,
  FirestoreDataConverter,
  runTransaction,
  increment,
} from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { queryOptimizer } from './query-optimizer';
import {
  LogTemplate,
  LogTemplateVersion,
  VariableCatalog,
  LogSchema,
  SchemaDiff,
} from '@/lib/types/logbuilder';

// Firestore converters
export const logTemplateConverter: FirestoreDataConverter<LogTemplate> = {
  toFirestore(template: LogTemplate) {
    return {
      name: template.name,
      logType: template.logType,
      status: template.status,
      latestVersion: template.latestVersion,
      createdBy: template.createdBy,
      createdAt: template.createdAt,
      updatedAt: template.updatedAt,
      draftSchema: template.draftSchema,
    };
  },
  fromFirestore(snapshot: QueryDocumentSnapshot): LogTemplate {
    const data = snapshot.data();
    return {
      id: snapshot.id,
      name: data.name,
      logType: data.logType,
      status: data.status,
      latestVersion: data.latestVersion || 0,
      createdBy: data.createdBy,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
      draftSchema: data.draftSchema,
    };
  },
};

export const logTemplateVersionConverter: FirestoreDataConverter<LogTemplateVersion> = {
  toFirestore(version: LogTemplateVersion) {
    return {
      templateId: version.templateId,
      version: version.version,
      schema: version.schema,
      previewConfig: version.previewConfig,
      changelog: version.changelog,
      createdBy: version.createdBy,
      createdAt: version.createdAt,
    };
  },
  fromFirestore(snapshot: QueryDocumentSnapshot): LogTemplateVersion {
    const data = snapshot.data();
    return {
      id: snapshot.id,
      templateId: data.templateId,
      version: data.version,
      schema: data.schema,
      previewConfig: data.previewConfig,
      changelog: data.changelog,
      createdBy: data.createdBy,
      createdAt: data.createdAt,
    };
  },
};

export const variableCatalogConverter: FirestoreDataConverter<VariableCatalog> = {
  toFirestore(variable: VariableCatalog) {
    return {
      key: variable.key,
      label: variable.label,
      type: variable.type,
      unit: variable.unit,
      options: variable.options,
      validation: variable.validation,
      notes: variable.notes,
      category: variable.category,
      createdAt: variable.createdAt,
      updatedAt: variable.updatedAt,
    };
  },
  fromFirestore(snapshot: QueryDocumentSnapshot): VariableCatalog {
    const data = snapshot.data();
    return {
      id: snapshot.id,
      key: data.key,
      label: data.label,
      type: data.type,
      unit: data.unit,
      options: data.options,
      validation: data.validation,
      notes: data.notes,
      category: data.category,
      createdAt: data.createdAt,
      updatedAt: data.updatedAt,
    };
  },
};

// Template operations
export class TemplateService {
  private templatesRef = collection(db, 'log_templates').withConverter(logTemplateConverter);
  private variablesRef = collection(db, 'variables_catalog').withConverter(variableCatalogConverter);

  /**
   * Get all templates with optional filtering
   */
  async getTemplates(filters?: {
    status?: LogTemplate['status'];
    logType?: string;
    createdBy?: string;
    useCache?: boolean;
    pageSize?: number;
  }): Promise<LogTemplate[]> {
    const constraints = [orderBy('updatedAt', 'desc')];

    if (filters?.status) {
      constraints.push(where('status', '==', filters.status));
    }
    if (filters?.logType) {
      constraints.push(where('logType', '==', filters.logType));
    }
    if (filters?.createdBy) {
      constraints.push(where('createdBy', '==', filters.createdBy));
    }
    if (filters?.pageSize) {
      constraints.push(limit(filters.pageSize));
    }

    return queryOptimizer.optimizedQuery<LogTemplate>(
      'logTemplates',
      constraints,
      { 
        useCache: filters?.useCache ?? true,
        timeoutMs: 10000
      }
    );
  }

  /**
   * Get template by ID
   */
  async getTemplate(templateId: string): Promise<LogTemplate | null> {
    const templateDoc = doc(this.templatesRef, templateId);
    const snapshot = await getDoc(templateDoc);
    return snapshot.exists() ? snapshot.data() : null;
  }

  /**
   * Create new template
   */
  async createTemplate(
    name: string,
    logType: string,
    createdBy: string,
    initialSchema?: LogSchema
  ): Promise<string> {
    const now = Timestamp.now();
    const template: Omit<LogTemplate, 'id'> = {
      name,
      logType,
      status: 'draft',
      latestVersion: 0,
      createdBy,
      createdAt: now,
      updatedAt: now,
      draftSchema: initialSchema || {
        fields: [],
        layout: [],
        meta: {},
      },
    };

    const docRef = await addDoc(this.templatesRef, template);
    return docRef.id;
  }

  /**
   * Update template draft schema
   */
  async updateDraftSchema(templateId: string, schema: LogSchema): Promise<void> {
    const templateDoc = doc(this.templatesRef, templateId);
    await updateDoc(templateDoc, {
      draftSchema: schema,
      updatedAt: Timestamp.now(),
    });
  }

  /**
   * Publish template version (creates immutable snapshot)
   */
  async publishTemplate(
    templateId: string,
    changelog: string,
    createdBy: string
  ): Promise<number> {
    return await runTransaction(db, async (transaction) => {
      const templateDoc = doc(this.templatesRef, templateId);
      const templateSnap = await transaction.get(templateDoc);
      
      if (!templateSnap.exists()) {
        throw new Error('Template not found');
      }

      const template = templateSnap.data();
      if (template.status !== 'draft') {
        throw new Error('Only draft templates can be published');
      }

      const newVersion = template.latestVersion + 1;
      
      // Create immutable version document
      const versionsRef = collection(db, `log_templates/${templateId}/versions`);
      const versionDoc = doc(versionsRef, newVersion.toString());
      
      const versionData: Omit<LogTemplateVersion, 'id'> = {
        templateId,
        version: newVersion,
        schema: template.draftSchema,
        changelog,
        createdBy,
        createdAt: Timestamp.now(),
      };

      transaction.set(versionDoc, versionData);

      // Update template status and version
      transaction.update(templateDoc, {
        status: 'published',
        latestVersion: newVersion,
        updatedAt: Timestamp.now(),
      });

      return newVersion;
    });
  }

  /**
   * Get template versions
   */
  async getTemplateVersions(templateId: string): Promise<LogTemplateVersion[]> {
    const versionsRef = collection(db, `log_templates/${templateId}/versions`)
      .withConverter(logTemplateVersionConverter);
    
    const q = query(versionsRef, orderBy('version', 'desc'));
    const snapshot = await getDocs(q);
    
    return snapshot.docs.map(doc => doc.data());
  }

  /**
   * Get specific template version
   */
  async getTemplateVersion(templateId: string, version: number): Promise<LogTemplateVersion | null> {
    const versionDoc = doc(db, `log_templates/${templateId}/versions/${version}`)
      .withConverter(logTemplateVersionConverter);
    
    const snapshot = await getDoc(versionDoc);
    return snapshot.exists() ? snapshot.data() : null;
  }

  /**
   * Archive template
   */
  async archiveTemplate(templateId: string): Promise<void> {
    const templateDoc = doc(this.templatesRef, templateId);
    await updateDoc(templateDoc, {
      status: 'archived',
      updatedAt: Timestamp.now(),
    });
  }

  /**
   * Duplicate template
   */
  async duplicateTemplate(templateId: string, newName: string, createdBy: string): Promise<string> {
    const original = await this.getTemplate(templateId);
    if (!original) {
      throw new Error('Template not found');
    }

    return await this.createTemplate(
      newName,
      original.logType,
      createdBy,
      original.draftSchema
    );
  }

  /**
   * Get variables catalog
   */
  async getVariablesCatalog(category?: string): Promise<VariableCatalog[]> {
    let q = query(this.variablesRef, orderBy('category'), orderBy('label'));

    if (category) {
      q = query(q, where('category', '==', category));
    }

    const snapshot = await getDocs(q);
    return snapshot.docs.map(doc => doc.data());
  }

  /**
   * Create variable in catalog
   */
  async createVariable(variable: Omit<VariableCatalog, 'id' | 'createdAt' | 'updatedAt'>): Promise<string> {
    const now = Timestamp.now();
    const variableData: Omit<VariableCatalog, 'id'> = {
      ...variable,
      createdAt: now,
      updatedAt: now,
    };

    const docRef = await addDoc(this.variablesRef, variableData);
    return docRef.id;
  }

  /**
   * Update variable in catalog
   */
  async updateVariable(variableId: string, updates: Partial<VariableCatalog>): Promise<void> {
    const variableDoc = doc(this.variablesRef, variableId);
    await updateDoc(variableDoc, {
      ...updates,
      updatedAt: Timestamp.now(),
    });
  }

  /**
   * Delete template (soft delete by archiving)
   */
  async deleteTemplate(templateId: string): Promise<void> {
    await this.archiveTemplate(templateId);
  }

  /**
   * Search templates
   */
  async searchTemplates(searchTerm: string): Promise<LogTemplate[]> {
    // Note: Firestore doesn't support full-text search natively
    // This is a basic implementation - consider using Algolia or similar for production
    const templates = await this.getTemplates();
    return templates.filter(template => 
      template.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      template.logType.toLowerCase().includes(searchTerm.toLowerCase())
    );
  }
}