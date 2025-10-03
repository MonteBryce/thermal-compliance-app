import { 
  collection, 
  doc, 
  getDoc, 
  setDoc, 
  getDocs, 
  query, 
  where, 
  orderBy,
  serverTimestamp 
} from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { 
  LogTemplate, 
  TemplateMetric, 
  StructureCheckResult, 
  StructureMismatch,
  createDefaultTemplate 
} from '@/lib/types/template';
import * as XLSX from 'xlsx';

export class TemplateService {
  private static instance: TemplateService;
  
  static getInstance(): TemplateService {
    if (!TemplateService.instance) {
      TemplateService.instance = new TemplateService();
    }
    return TemplateService.instance;
  }

  /**
   * Get template by logType - like getting the right character class sheet
   */
  async getTemplate(logType: string): Promise<LogTemplate | null> {
    try {
      const templateDoc = await getDoc(doc(db, 'logTemplates', logType));
      
      if (templateDoc.exists()) {
        const data = templateDoc.data();
        return {
          id: templateDoc.id,
          ...data,
          updatedAt: data.updatedAt?.toDate?.()?.toISOString() || data.updatedAt
        } as LogTemplate;
      }
      
      // Return default template if none exists
      console.log(`No template found for ${logType}, creating default`);
      return createDefaultTemplate(logType);
    } catch (error) {
      console.error('Error getting template:', error);
      throw error;
    }
  }

  /**
   * Save template to Firestore - like saving a finalized character sheet
   */
  async saveTemplate(template: Omit<LogTemplate, 'updatedAt'>, adminUid: string): Promise<void> {
    try {
      const templateToSave = {
        ...template,
        updatedAt: serverTimestamp(),
        updatedBy: adminUid,
        version: template.version + 1 // Increment version
      };

      await setDoc(doc(db, 'logTemplates', template.logType), templateToSave);
      console.log(`Template saved: ${template.logType} v${templateToSave.version}`);
    } catch (error) {
      console.error('Error saving template:', error);
      throw error;
    }
  }

  /**
   * Get all templates
   */
  async getAllTemplates(): Promise<LogTemplate[]> {
    try {
      const templatesQuery = query(
        collection(db, 'logTemplates'),
        where('active', '==', true),
        orderBy('displayName')
      );
      
      const snapshot = await getDocs(templatesQuery);
      return snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
        updatedAt: doc.data().updatedAt?.toDate?.()?.toISOString() || doc.data().updatedAt
      })) as LogTemplate[];
    } catch (error) {
      console.error('Error getting all templates:', error);
      return [];
    }
  }

  /**
   * Validate template structure against Excel file
   * Like checking if custom character sheet matches official rules
   */
  async validateAgainstExcel(
    template: LogTemplate, 
    excelFile: File
  ): Promise<StructureCheckResult> {
    try {
      const arrayBuffer = await excelFile.arrayBuffer();
      const workbook = XLSX.read(arrayBuffer, { type: 'buffer' });
      const worksheet = workbook.Sheets[workbook.SheetNames[0]];
      
      // Parse Excel headers and structure
      const excelStructure = this.parseExcelStructure(worksheet);
      const templateStructure = this.getTemplateStructure(template);
      
      return this.compareStructures(templateStructure, excelStructure);
    } catch (error) {
      console.error('Error validating against Excel:', error);
      return {
        passed: false,
        mismatches: [{
          type: 'wrong_order',
          actual: 'Parse error',
          expected: 'Valid Excel file',
          suggestion: 'Check Excel file format',
          severity: 'error'
        }],
        warnings: [`Failed to parse Excel file: ${error}`]
      };
    }
  }

  /**
   * Parse Excel file structure to extract headers and metrics
   */
  private parseExcelStructure(worksheet: XLSX.WorkSheet): {
    hours: string[];
    metrics: { label: string; unit?: string; row: number }[];
  } {
    const range = XLSX.utils.decode_range(worksheet['!ref'] || 'A1:Z50');
    const hours: string[] = [];
    const metrics: { label: string; unit?: string; row: number }[] = [];
    
    // Look for hour headers (usually in first few rows)
    for (let row = range.s.r; row <= Math.min(range.s.r + 5, range.e.r); row++) {
      for (let col = range.s.c; col <= range.e.c; col++) {
        const cellRef = XLSX.utils.encode_cell({ r: row, c: col });
        const cell = worksheet[cellRef];
        
        if (cell && cell.v) {
          const value = String(cell.v).trim();
          
          // Check if it's an hour (00, 01, etc. or 12:00 AM format)
          if (/^\d{1,2}(:00)?(\s*(AM|PM))?$/i.test(value)) {
            const hour = value.replace(/(:00|\s*(AM|PM))/gi, '').padStart(2, '0');
            if (!hours.includes(hour)) {
              hours.push(hour);
            }
          }
        }
      }
    }
    
    // Look for metric labels (usually in first column)
    for (let row = range.s.r; row <= range.e.r; row++) {
      const cellRef = XLSX.utils.encode_cell({ r: row, c: 0 });
      const cell = worksheet[cellRef];
      
      if (cell && cell.v) {
        const label = String(cell.v).trim();
        
        // Skip header rows and empty labels
        if (label && 
            !label.toLowerCase().includes('hour') && 
            !label.toLowerCase().includes('time') &&
            label.length > 3) {
          
          // Extract unit from label if present
          const unitMatch = label.match(/\(([^)]+)\)/);
          const unit = unitMatch ? unitMatch[1] : undefined;
          
          metrics.push({ label, unit, row });
        }
      }
    }
    
    return { hours: hours.sort(), metrics };
  }

  /**
   * Get template structure for comparison
   */
  private getTemplateStructure(template: LogTemplate): {
    hours: string[];
    metrics: { label: string; unit?: string; order: number }[];
  } {
    return {
      hours: template.hours,
      metrics: template.metrics
        .filter(m => m.visible)
        .sort((a, b) => a.order - b.order)
        .map(m => ({
          label: m.label,
          unit: m.unit,
          order: m.order
        }))
    };
  }

  /**
   * Compare template structure with Excel structure
   */
  private compareStructures(
    template: { hours: string[]; metrics: { label: string; unit?: string; order: number }[] },
    excel: { hours: string[]; metrics: { label: string; unit?: string; row: number }[] }
  ): StructureCheckResult {
    const mismatches: StructureMismatch[] = [];
    const warnings: string[] = [];

    // Check hours
    const missingHours = template.hours.filter(h => !excel.hours.includes(h));
    const extraHours = excel.hours.filter(h => !template.hours.includes(h));
    
    missingHours.forEach(hour => {
      mismatches.push({
        type: 'missing_metric',
        expected: `Hour ${hour}`,
        actual: 'Not found in Excel',
        suggestion: `Add hour ${hour} column to Excel`,
        severity: 'error'
      });
    });

    extraHours.forEach(hour => {
      warnings.push(`Excel contains extra hour ${hour} not in template`);
    });

    // Check metrics
    template.metrics.forEach((templateMetric, index) => {
      const excelMetric = excel.metrics.find(m => 
        this.normalizeLabel(m.label) === this.normalizeLabel(templateMetric.label)
      );
      
      if (!excelMetric) {
        mismatches.push({
          type: 'missing_metric',
          expected: templateMetric.label,
          actual: 'Not found in Excel',
          suggestion: `Add metric "${templateMetric.label}" to Excel`,
          severity: 'error'
        });
      } else {
        // Check unit
        if (templateMetric.unit && excelMetric.unit && 
            this.normalizeUnit(templateMetric.unit) !== this.normalizeUnit(excelMetric.unit)) {
          mismatches.push({
            type: 'wrong_unit',
            expected: templateMetric.unit,
            actual: excelMetric.unit,
            suggestion: `Update unit for "${templateMetric.label}"`,
            severity: 'warning'
          });
        }
        
        // Check order (rough approximation)
        const expectedPosition = index;
        const actualPosition = excel.metrics.indexOf(excelMetric);
        if (Math.abs(expectedPosition - actualPosition) > 2) {
          mismatches.push({
            type: 'wrong_order',
            expected: `Position ${expectedPosition + 1}`,
            actual: `Position ${actualPosition + 1}`,
            suggestion: `Reorder "${templateMetric.label}" in Excel`,
            severity: 'warning'
          });
        }
      }
    });

    // Check for extra metrics in Excel
    excel.metrics.forEach(excelMetric => {
      const templateMetric = template.metrics.find(m =>
        this.normalizeLabel(m.label) === this.normalizeLabel(excelMetric.label)
      );
      
      if (!templateMetric) {
        warnings.push(`Excel contains extra metric "${excelMetric.label}" not in template`);
      }
    });

    const passed = mismatches.filter(m => m.severity === 'error').length === 0;

    return {
      passed,
      mismatches,
      warnings,
      excelHeaders: excel.metrics.map(m => m.label),
      templateHeaders: template.metrics.map(m => m.label)
    };
  }

  private normalizeLabel(label: string): string {
    return label.toLowerCase()
      .replace(/[()]/g, '')
      .replace(/\s+/g, ' ')
      .trim();
  }

  private normalizeUnit(unit: string): string {
    return unit.toLowerCase()
      .replace(/[°]/g, '')
      .replace(/\s+/g, '')
      .trim();
  }

  /**
   * Apply template to project
   */
  async applyTemplateToProject(projectId: string, templateId: string): Promise<void> {
    try {
      await setDoc(doc(db, 'projects', projectId, 'metadata', 'template'), {
        templateId,
        appliedAt: serverTimestamp(),
        appliedBy: 'admin' // TODO: Get from auth context
      });
      
      console.log(`Template ${templateId} applied to project ${projectId}`);
    } catch (error) {
      console.error('Error applying template to project:', error);
      throw error;
    }
  }

  /**
   * Clone template for customization
   */
  async cloneTemplate(sourceTemplate: LogTemplate, newLogType: string, adminUid: string): Promise<LogTemplate> {
    const clonedTemplate: LogTemplate = {
      ...sourceTemplate,
      id: `${newLogType}_v1`,
      logType: newLogType,
      displayName: `${newLogType.replace('_', ' ').toUpperCase()} (Custom)`,
      version: 1,
      updatedAt: new Date().toISOString(),
      updatedBy: adminUid
    };

    await this.saveTemplate(clonedTemplate, adminUid);
    return clonedTemplate;
  }
}