import { LogSchema, LogField, LogSection, LogLayoutRow, SchemaDiff } from '@/lib/types/logbuilder';

/**
 * Deep comparison utility for objects
 */
function deepEqual(obj1: any, obj2: any): boolean {
  if (obj1 === obj2) return true;
  
  if (obj1 == null || obj2 == null) return obj1 === obj2;
  
  if (typeof obj1 !== typeof obj2) return false;
  
  if (typeof obj1 !== 'object') return obj1 === obj2;
  
  if (Array.isArray(obj1) !== Array.isArray(obj2)) return false;
  
  if (Array.isArray(obj1)) {
    if (obj1.length !== obj2.length) return false;
    for (let i = 0; i < obj1.length; i++) {
      if (!deepEqual(obj1[i], obj2[i])) return false;
    }
    return true;
  }
  
  const keys1 = Object.keys(obj1);
  const keys2 = Object.keys(obj2);
  
  if (keys1.length !== keys2.length) return false;
  
  for (const key of keys1) {
    if (!keys2.includes(key)) return false;
    if (!deepEqual(obj1[key], obj2[key])) return false;
  }
  
  return true;
}

/**
 * Get differences between two field objects
 */
function getFieldChanges(oldField: LogField, newField: LogField): Partial<LogField> | null {
  const changes: Partial<LogField> = {};
  let hasChanges = false;

  // Check each property for changes
  const fieldsToCheck: (keyof LogField)[] = [
    'key', 'label', 'type', 'unit', 'required', 'defaultValue', 'validation', 'options', 'visibility'
  ];

  for (const field of fieldsToCheck) {
    if (!deepEqual(oldField[field], newField[field])) {
      (changes as any)[field] = newField[field];
      hasChanges = true;
    }
  }

  return hasChanges ? changes : null;
}

/**
 * Compare two schemas and return diff
 */
export function compareSchemas(oldSchema: LogSchema, newSchema: LogSchema): SchemaDiff {
  const diff: SchemaDiff = {
    fieldsAdded: [],
    fieldsRemoved: [],
    fieldsModified: [],
    layoutChanges: {
      sectionsAdded: [],
      sectionsRemoved: [],
      sectionsModified: [],
    },
  };

  // Create maps for easier lookup
  const oldFieldsMap = new Map(oldSchema.fields.map(f => [f.id, f]));
  const newFieldsMap = new Map(newSchema.fields.map(f => [f.id, f]));

  // Find added fields
  for (const newField of newSchema.fields) {
    if (!oldFieldsMap.has(newField.id)) {
      diff.fieldsAdded.push(newField);
    }
  }

  // Find removed fields
  for (const oldField of oldSchema.fields) {
    if (!newFieldsMap.has(oldField.id)) {
      diff.fieldsRemoved.push(oldField);
    }
  }

  // Find modified fields
  for (const newField of newSchema.fields) {
    const oldField = oldFieldsMap.get(newField.id);
    if (oldField) {
      const changes = getFieldChanges(oldField, newField);
      if (changes) {
        diff.fieldsModified.push({
          id: newField.id,
          changes,
        });
      }
    }
  }

  // Compare layout changes
  const oldSectionsMap = new Map(oldSchema.layout.map(s => [s.id, s]));
  const newSectionsMap = new Map(newSchema.layout.map(s => [s.id, s]));

  // Find added sections
  for (const newSection of newSchema.layout) {
    if (!oldSectionsMap.has(newSection.id)) {
      diff.layoutChanges.sectionsAdded.push(newSection);
    }
  }

  // Find removed sections
  for (const oldSection of oldSchema.layout) {
    if (!newSectionsMap.has(oldSection.id)) {
      diff.layoutChanges.sectionsRemoved.push(oldSection);
    }
  }

  // Find modified sections
  for (const newSection of newSchema.layout) {
    const oldSection = oldSectionsMap.get(newSection.id);
    if (oldSection && !deepEqual(oldSection, newSection)) {
      diff.layoutChanges.sectionsModified.push({
        id: newSection.id,
        changes: {
          title: oldSection.title !== newSection.title ? newSection.title : undefined,
          rows: !deepEqual(oldSection.rows, newSection.rows) ? newSection.rows : undefined,
        },
      });
    }
  }

  return diff;
}

/**
 * Check if a diff has any changes
 */
export function hasDifferences(diff: SchemaDiff): boolean {
  return (
    diff.fieldsAdded.length > 0 ||
    diff.fieldsRemoved.length > 0 ||
    diff.fieldsModified.length > 0 ||
    diff.layoutChanges.sectionsAdded.length > 0 ||
    diff.layoutChanges.sectionsRemoved.length > 0 ||
    diff.layoutChanges.sectionsModified.length > 0
  );
}

/**
 * Get a human-readable summary of changes
 */
export function getDiffSummary(diff: SchemaDiff): string[] {
  const summary: string[] = [];

  if (diff.fieldsAdded.length > 0) {
    summary.push(`Added ${diff.fieldsAdded.length} field(s): ${diff.fieldsAdded.map(f => f.label).join(', ')}`);
  }

  if (diff.fieldsRemoved.length > 0) {
    summary.push(`Removed ${diff.fieldsRemoved.length} field(s): ${diff.fieldsRemoved.map(f => f.label).join(', ')}`);
  }

  if (diff.fieldsModified.length > 0) {
    summary.push(`Modified ${diff.fieldsModified.length} field(s)`);
  }

  if (diff.layoutChanges.sectionsAdded.length > 0) {
    summary.push(`Added ${diff.layoutChanges.sectionsAdded.length} section(s)`);
  }

  if (diff.layoutChanges.sectionsRemoved.length > 0) {
    summary.push(`Removed ${diff.layoutChanges.sectionsRemoved.length} section(s)`);
  }

  if (diff.layoutChanges.sectionsModified.length > 0) {
    summary.push(`Modified ${diff.layoutChanges.sectionsModified.length} section(s)`);
  }

  if (summary.length === 0) {
    summary.push('No changes detected');
  }

  return summary;
}

/**
 * Validate schema for potential issues
 */
export function validateSchema(schema: LogSchema): {
  isValid: boolean;
  errors: string[];
  warnings: string[];
} {
  const errors: string[] = [];
  const warnings: string[] = [];

  // Check for duplicate field IDs
  const fieldIds = new Set<string>();
  for (const field of schema.fields) {
    if (fieldIds.has(field.id)) {
      errors.push(`Duplicate field ID: ${field.id}`);
    }
    fieldIds.add(field.id);
  }

  // Check for duplicate field keys
  const fieldKeys = new Set<string>();
  for (const field of schema.fields) {
    if (fieldKeys.has(field.key)) {
      errors.push(`Duplicate field key: ${field.key}`);
    }
    fieldKeys.add(field.key);
  }

  // Check for empty field labels
  for (const field of schema.fields) {
    if (!field.label || field.label.trim() === '') {
      errors.push(`Field ${field.id} has empty label`);
    }
  }

  // Check for invalid field keys (should follow Firestore naming rules)
  const validKeyPattern = /^[a-zA-Z_][a-zA-Z0-9_]*$/;
  for (const field of schema.fields) {
    if (!validKeyPattern.test(field.key)) {
      errors.push(`Invalid field key: ${field.key}. Must start with letter or underscore and contain only letters, numbers, and underscores.`);
    }
  }

  // Check layout references
  const usedFieldIds = new Set<string>();
  for (const section of schema.layout) {
    for (const row of section.rows) {
      for (const column of row.columns) {
        usedFieldIds.add(column.fieldId);
        
        // Check if field exists
        if (!fieldIds.has(column.fieldId)) {
          errors.push(`Layout references non-existent field: ${column.fieldId}`);
        }
        
        // Check column width
        if (column.width && (column.width < 1 || column.width > 12)) {
          warnings.push(`Column width should be between 1 and 12: ${column.width}`);
        }
      }
    }
  }

  // Check for unused fields
  for (const field of schema.fields) {
    if (!usedFieldIds.has(field.id)) {
      warnings.push(`Field "${field.label}" is defined but not used in layout`);
    }
  }

  // Check for empty sections
  for (const section of schema.layout) {
    if (section.rows.length === 0) {
      warnings.push(`Section "${section.title || 'Untitled'}" has no rows`);
    }
  }

  // Check row column totals (should not exceed 12)
  for (const section of schema.layout) {
    for (const row of section.rows) {
      const totalWidth = row.columns.reduce((sum, col) => sum + (col.width || 6), 0);
      if (totalWidth > 12) {
        warnings.push(`Row in section "${section.title || 'Untitled'}" exceeds 12 columns (${totalWidth})`);
      }
    }
  }

  // Check for required fields validation
  for (const field of schema.fields) {
    if (field.type === 'number' && field.validation) {
      if (field.validation.min !== undefined && field.validation.max !== undefined) {
        if (field.validation.min >= field.validation.max) {
          errors.push(`Field "${field.label}": min value must be less than max value`);
        }
      }
    }
    
    if (field.type === 'select' && (!field.options || field.options.length === 0)) {
      warnings.push(`Select field "${field.label}" has no options defined`);
    }
  }

  return {
    isValid: errors.length === 0,
    errors,
    warnings,
  };
}

/**
 * Merge two schemas (useful for conflict resolution)
 */
export function mergeSchemas(baseSchema: LogSchema, incomingSchema: LogSchema): LogSchema {
  // Simple merge strategy - incoming takes precedence
  // In a real implementation, you might want more sophisticated merge logic
  
  const mergedFields = [...incomingSchema.fields];
  const incomingFieldIds = new Set(incomingSchema.fields.map(f => f.id));
  
  // Add any fields from base that aren't in incoming
  for (const baseField of baseSchema.fields) {
    if (!incomingFieldIds.has(baseField.id)) {
      mergedFields.push(baseField);
    }
  }

  return {
    fields: mergedFields,
    layout: incomingSchema.layout,
    meta: {
      ...baseSchema.meta,
      ...incomingSchema.meta,
    },
  };
}