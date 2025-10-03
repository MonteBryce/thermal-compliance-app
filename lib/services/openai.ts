import OpenAI from 'openai';
import { LogField, LogTemplate } from '@/lib/types/logbuilder';

// Types for AI service responses
export interface FieldSuggestion {
  field: LogField;
  confidence: number;
  reasoning: string;
  complianceRelevance?: string;
}

export interface PatternSuggestion {
  name: string;
  description: string;
  fieldGroups: LogField[][];
}

export interface FieldProperties {
  label?: string;
  helpText?: string;
  validation?: {
    required?: boolean;
    min?: number;
    max?: number;
    minLength?: number;
    maxLength?: number;
    pattern?: string;
  };
  unit?: string;
  defaultValue?: any;
  placeholder?: string;
  formatHint?: string;
}

export interface ComplianceValidation {
  isCompliant: boolean;
  issues: ValidationIssue[];
  recommendations: string[];
  overallScore: number;
}

export interface ValidationIssue {
  field?: string;
  severity: 'error' | 'warning' | 'info';
  message: string;
  regulation?: string;
  solution?: string;
}

// Initialize OpenAI client
const getOpenAIClient = () => {
  const apiKey = process.env.OPENAI_API_KEY || process.env.NEXT_PUBLIC_OPENAI_API_KEY;
  
  if (!apiKey) {
    throw new Error('OpenAI API key not configured. Please set OPENAI_API_KEY environment variable.');
  }

  return new OpenAI({
    apiKey,
    dangerouslyAllowBrowser: typeof window !== 'undefined', // Allow browser usage in development
  });
};

// Rate limiting configuration
interface RateLimitConfig {
  requests: number;
  window: number; // milliseconds
}

class RateLimiter {
  private requests: number[] = [];
  private config: RateLimitConfig;

  constructor(config: RateLimitConfig = { requests: 10, window: 60000 }) {
    this.config = config;
  }

  async checkLimit(): Promise<void> {
    const now = Date.now();
    this.requests = this.requests.filter(time => now - time < this.config.window);

    if (this.requests.length >= this.config.requests) {
      const oldestRequest = this.requests[0];
      const waitTime = this.config.window - (now - oldestRequest);
      
      if (waitTime > 0) {
        throw new Error(`Rate limit exceeded. Please wait ${Math.ceil(waitTime / 1000)} seconds.`);
      }
    }

    this.requests.push(now);
  }
}

const rateLimiter = new RateLimiter();

// Error handling wrapper
async function withErrorHandling<T>(
  operation: () => Promise<T>,
  fallback?: T
): Promise<T> {
  try {
    await rateLimiter.checkLimit();
    return await operation();
  } catch (error: any) {
    console.error('OpenAI service error:', error);
    
    if (error.message?.includes('Rate limit')) {
      throw error; // Re-throw rate limit errors
    }

    if (fallback !== undefined) {
      console.warn('Using fallback response due to AI service error');
      return fallback;
    }

    throw new Error(`AI service unavailable: ${error.message || 'Unknown error'}`);
  }
}

// Field suggestion generation
export async function generateFieldSuggestions(params: {
  templateType: string;
  existingFields: LogField[];
  industryContext: string;
  complianceRequirements?: string[];
}): Promise<{ suggestions: FieldSuggestion[]; patterns: PatternSuggestion[] }> {
  return withErrorHandling(async () => {
    const client = getOpenAIClient();
    
    const systemPrompt = `
You are an expert in thermal logging and industrial form design. Generate intelligent field suggestions for thermal logging templates.

Context:
- Template Type: ${params.templateType}
- Industry: ${params.industryContext}
- Compliance: ${params.complianceRequirements?.join(', ') || 'General'}
- Existing Fields: ${params.existingFields.map(f => f.key).join(', ')}

Provide suggestions that are:
1. Relevant to thermal logging operations
2. Compliant with industry regulations
3. Commonly used in similar templates
4. Logically grouped and related

Respond with valid JSON only.
`;

    const userPrompt = `
Generate field suggestions for a ${params.templateType} template in the ${params.industryContext} industry.

Current template has these fields: ${params.existingFields.map(f => `${f.key} (${f.type})`).join(', ')}

Suggest 3-8 additional fields that would improve this template, considering:
- Regulatory compliance for ${params.complianceRequirements?.join(', ') || 'general industrial standards'}
- Common industry practices
- Data collection best practices
- Field relationships and groupings

Format your response as JSON with this structure:
{
  "suggestions": [
    {
      "field": {
        "id": "generated-id",
        "key": "fieldKey",
        "label": "Field Label",
        "type": "text|number|date|select|checkbox",
        "unit": "unit if applicable",
        "validation": { "required": boolean, "min": number, "max": number }
      },
      "confidence": 0.95,
      "reasoning": "Why this field is important",
      "complianceRelevance": "Which regulation requires this"
    }
  ],
  "patterns": [
    {
      "name": "Pattern Name",
      "description": "Pattern description",
      "fieldGroups": [["field1", "field2"], ["field3", "field4"]]
    }
  ]
}
`;

    const completion = await client.chat.completions.create({
      model: 'gpt-4',
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userPrompt }
      ],
      max_tokens: 2000,
      temperature: 0.3,
    });

    const content = completion.choices[0]?.message?.content;
    if (!content) {
      throw new Error('No response from AI service');
    }

    try {
      const parsed = JSON.parse(content);
      
      // Validate and enhance response
      return {
        suggestions: parsed.suggestions?.map((s: any, index: number) => ({
          ...s,
          field: {
            ...s.field,
            id: s.field.id || `ai-suggested-${Date.now()}-${index}`,
          }
        })) || [],
        patterns: parsed.patterns || []
      };
    } catch (parseError) {
      throw new Error('Invalid AI response format');
    }
  }, { suggestions: [], patterns: [] });
}

// Field properties auto-completion
export async function generateFieldProperties(field: LogField): Promise<FieldProperties> {
  return withErrorHandling(async () => {
    const client = getOpenAIClient();

    const systemPrompt = `
You are an expert in form design and thermal logging. Generate intelligent field properties including labels, help text, validation rules, and formatting suggestions.
`;

    const userPrompt = `
Generate comprehensive properties for this field in a thermal logging template:
- Key: ${field.key}
- Label: ${field.label || field.key}
- Type: ${field.type}
- Current unit: ${(field as any).unit || 'none'}

Provide appropriate:
1. Enhanced label if needed
2. Helpful placeholder text
3. User-friendly help text
4. Validation rules appropriate for the field type
5. Default unit if applicable
6. Format hints for complex fields

Consider thermal logging industry standards and user experience.

Respond with valid JSON only:
{
  "label": "Enhanced Label",
  "helpText": "Helpful description for users",
  "validation": {
    "required": boolean,
    "min": number,
    "max": number,
    "pattern": "regex pattern",
    "minLength": number,
    "maxLength": number
  },
  "unit": "appropriate unit",
  "defaultValue": null or appropriate default,
  "placeholder": "example value",
  "formatHint": "format description"
}
`;

    const completion = await client.chat.completions.create({
      model: 'gpt-4',
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userPrompt }
      ],
      max_tokens: 800,
      temperature: 0.2,
    });

    const content = completion.choices[0]?.message?.content;
    if (!content) {
      throw new Error('No response from AI service');
    }

    try {
      return JSON.parse(content);
    } catch (parseError) {
      throw new Error('Invalid AI response format');
    }
  }, {});
}

// Template compliance validation
export async function validateTemplateCompliance(params: {
  template: LogTemplate;
  industry: string;
  regulations: string[];
}): Promise<ComplianceValidation> {
  return withErrorHandling(async () => {
    const client = getOpenAIClient();

    const systemPrompt = `
You are a regulatory compliance expert specializing in thermal logging and industrial documentation.
Analyze templates for compliance with industry regulations and standards.
`;

    const userPrompt = `
Analyze this thermal logging template for regulatory compliance:

Template: ${params.template.name}
Type: ${params.template.logType}
Industry: ${params.industry}
Regulations: ${params.regulations.join(', ')}

Fields: ${params.template.draftSchema.fields.map(f => `${f.key} (${f.type})`).join(', ')}

Check compliance with:
${params.regulations.map(reg => `- ${reg} requirements`).join('\n')}

Provide:
1. Overall compliance score (0-1)
2. Critical issues that must be addressed
3. Recommendations for improvement
4. Missing required fields

Respond with valid JSON:
{
  "isCompliant": boolean,
  "overallScore": 0.85,
  "issues": [
    {
      "field": "fieldKey or null",
      "severity": "error|warning|info",
      "message": "Issue description",
      "regulation": "Which regulation",
      "solution": "How to fix"
    }
  ],
  "recommendations": [
    "Recommendation text"
  ]
}
`;

    const completion = await client.chat.completions.create({
      model: 'gpt-4',
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userPrompt }
      ],
      max_tokens: 1500,
      temperature: 0.1,
    });

    const content = completion.choices[0]?.message?.content;
    if (!content) {
      throw new Error('No response from AI service');
    }

    try {
      return JSON.parse(content);
    } catch (parseError) {
      throw new Error('Invalid AI response format');
    }
  }, {
    isCompliant: false,
    overallScore: 0,
    issues: [],
    recommendations: []
  });
}

// Pattern analysis for field relationships
export async function analyzeFieldPatterns(templates: LogTemplate[]): Promise<{
  commonFields: Array<{ key: string; usage: number; importance: string }>;
  fieldRelationships: Array<{ primary: string; related: string[]; strength: number }>;
  suggestedGroupings: Array<{ name: string; fields: string[]; reasoning: string }>;
}> {
  return withErrorHandling(async () => {
    const client = getOpenAIClient();

    const systemPrompt = `
You are an expert in data analysis and thermal logging operations. Analyze template patterns to identify common fields, relationships, and optimal groupings.
`;

    const templateData = templates.map(t => ({
      type: t.logType,
      fields: t.draftSchema.fields.map(f => ({ key: f.key, type: f.type }))
    }));

    const userPrompt = `
Analyze these thermal logging templates to identify patterns:

${JSON.stringify(templateData, null, 2)}

Identify:
1. Most commonly used fields across templates
2. Fields that frequently appear together
3. Logical groupings for better UX
4. Field importance based on usage

Respond with valid JSON:
{
  "commonFields": [
    {
      "key": "fieldKey",
      "usage": 0.95,
      "importance": "critical|high|medium|low"
    }
  ],
  "fieldRelationships": [
    {
      "primary": "primaryField",
      "related": ["relatedField1", "relatedField2"],
      "strength": 0.87
    }
  ],
  "suggestedGroupings": [
    {
      "name": "Group Name",
      "fields": ["field1", "field2"],
      "reasoning": "Why these fields belong together"
    }
  ]
}
`;

    const completion = await client.chat.completions.create({
      model: 'gpt-4',
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userPrompt }
      ],
      max_tokens: 1500,
      temperature: 0.2,
    });

    const content = completion.choices[0]?.message?.content;
    if (!content) {
      throw new Error('No response from AI service');
    }

    try {
      return JSON.parse(content);
    } catch (parseError) {
      throw new Error('Invalid AI response format');
    }
  }, {
    commonFields: [],
    fieldRelationships: [],
    suggestedGroupings: []
  });
}

// Intelligent help text generation
export async function generateHelpText(field: LogField, context: {
  templateType: string;
  relatedFields: string[];
}): Promise<string> {
  return withErrorHandling(async () => {
    const client = getOpenAIClient();

    const systemPrompt = `
You are a technical writer specializing in thermal logging documentation. Generate clear, concise help text for form fields.
`;

    const userPrompt = `
Generate helpful, user-friendly help text for this field:
- Field: ${field.key} (${field.label})
- Type: ${field.type}
- Template: ${context.templateType}
- Related fields: ${context.relatedFields.join(', ')}

The help text should:
1. Be 1-2 sentences maximum
2. Explain what data to enter
3. Provide context for why it's needed
4. Include example if helpful
5. Be accessible to non-technical users

Return only the help text, no JSON or formatting.
`;

    const completion = await client.chat.completions.create({
      model: 'gpt-3.5-turbo',
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: userPrompt }
      ],
      max_tokens: 150,
      temperature: 0.3,
    });

    return completion.choices[0]?.message?.content?.trim() || '';
  }, '');
}

// Service health check
export async function checkServiceHealth(): Promise<{
  available: boolean;
  latency: number;
  model: string;
}> {
  const startTime = Date.now();
  
  try {
    const client = getOpenAIClient();
    
    const completion = await client.chat.completions.create({
      model: 'gpt-3.5-turbo',
      messages: [{ role: 'user', content: 'Hello' }],
      max_tokens: 10,
    });

    const latency = Date.now() - startTime;
    
    return {
      available: true,
      latency,
      model: completion.model || 'unknown'
    };
  } catch (error) {
    return {
      available: false,
      latency: Date.now() - startTime,
      model: 'unavailable'
    };
  }
}

// Cache for expensive operations
class ResponseCache {
  private cache = new Map<string, { data: any; timestamp: number }>();
  private ttl = 30 * 60 * 1000; // 30 minutes

  set(key: string, data: any): void {
    this.cache.set(key, { data, timestamp: Date.now() });
  }

  get(key: string): any | null {
    const entry = this.cache.get(key);
    if (!entry) return null;

    if (Date.now() - entry.timestamp > this.ttl) {
      this.cache.delete(key);
      return null;
    }

    return entry.data;
  }

  clear(): void {
    this.cache.clear();
  }
}

export const responseCache = new ResponseCache();

// Cached field suggestions
export async function getCachedFieldSuggestions(params: {
  templateType: string;
  existingFields: LogField[];
  industryContext: string;
  complianceRequirements?: string[];
}): Promise<{ suggestions: FieldSuggestion[]; patterns: PatternSuggestion[] }> {
  const cacheKey = JSON.stringify({
    templateType: params.templateType,
    fieldKeys: params.existingFields.map(f => f.key).sort(),
    industryContext: params.industryContext,
    compliance: params.complianceRequirements?.sort()
  });

  const cached = responseCache.get(cacheKey);
  if (cached) {
    return cached;
  }

  const result = await generateFieldSuggestions(params);
  responseCache.set(cacheKey, result);
  
  return result;
}

export default {
  generateFieldSuggestions,
  generateFieldProperties,
  validateTemplateCompliance,
  analyzeFieldPatterns,
  generateHelpText,
  checkServiceHealth,
  getCachedFieldSuggestions
};