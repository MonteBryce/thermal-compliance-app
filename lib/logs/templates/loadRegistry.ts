import { LogTemplate, TemplateRegistry } from './types';
import registryData from './registry.json';

/**
 * Template registry loader
 * Loads and caches template definitions from JSON files
 */

// Cache for loaded templates
let templateCache: Map<string, LogTemplate> | null = null;

/**
 * Load all templates into a Map
 */
export async function loadRegistry(): Promise<Map<string, LogTemplate>> {
  // Return cached version if available
  if (templateCache) {
    return templateCache;
  }

  const templates = new Map<string, LogTemplate>();

  // Load all template files based on registry
  const registry = registryData as TemplateRegistry;
  
  for (const templateInfo of registry.templates) {
    try {
      // Dynamically import each template file
      const templateModule = await import(`./${templateInfo.id}.json`);
      const template = templateModule.default as LogTemplate;
      templates.set(templateInfo.id, template);
    } catch (error) {
      console.warn(`Failed to load template ${templateInfo.id}:`, error);
    }
  }

  // Cache the result
  templateCache = templates;

  return templates;
}

/**
 * Get a single template by ID
 */
export async function getTemplate(templateId: string): Promise<LogTemplate | null> {
  const registry = await loadRegistry();
  return registry.get(templateId) || null;
}

/**
 * Get all templates as an array
 */
export async function getAllTemplates(): Promise<LogTemplate[]> {
  const registry = await loadRegistry();
  return Array.from(registry.values());
}

/**
 * Get template metadata from registry
 */
export function getRegistryMetadata(): TemplateRegistry {
  return registryData as TemplateRegistry;
}

/**
 * Check if a template exists
 */
export async function templateExists(templateId: string): Promise<boolean> {
  const registry = await loadRegistry();
  return registry.has(templateId);
}

/**
 * Get template options for dropdown
 */
export async function getTemplateOptions(): Promise<Array<{ value: string; label: string; version: string }>> {
  const templates = await getAllTemplates();
  return templates.map(t => ({
    value: t.id,
    label: t.name,
    version: t.version,
  }));
}

/**
 * Clear the template cache (useful for development)
 */
export function clearCache(): void {
  templateCache = null;
}