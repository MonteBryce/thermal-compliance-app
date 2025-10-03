'use client';

import React, { useState, useEffect } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Progress } from '@/components/ui/progress';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { ArrowLeft, ArrowRight, Check, AlertCircle } from 'lucide-react';
import { StepPickBase } from './steps/StepPickBase';
import { StepConfigure } from './steps/StepConfigure';
import { StepReviewPublish } from './steps/StepReviewPublish';
import { VersionedTemplateService } from '@/lib/logs/templates/versioned-service';
import {
  LogTemplate,
  TemplateVersion,
  Toggles,
  Targets,
  MASTER_FIELDS,
  filterFieldsByConditions,
} from '@/lib/logs/templates/versioned-types';
import { LIBRARY_TEMPLATES, LibraryTemplate } from '@/lib/logs/templates/library-seed';

interface WizardState {
  step: 1 | 2 | 3;
  templateId?: string;
  versionId?: string;
  name: string;
  templateKey: string;
  gasFamily: 'methane' | 'pentane';
  gasType: 'methane' | 'pentane';
  toggles: Toggles;
  targets: Targets;
  excelTemplatePath: string;
  facilityPresetId?: string;
  derivedFromVersion?: number;
  isEditing: boolean;
  jobId?: string;
  validationErrors?: boolean;
  validationWarnings?: boolean;
}

const WIZARD_STEPS = [
  { id: 1, title: 'Pick Base', description: 'Choose fuel type and variant' },
  { id: 2, title: 'Configure', description: 'Set toggles and targets' },
  { id: 3, title: 'Review & Publish', description: 'Review and deploy' },
];

export function TemplateWizard() {
  const router = useRouter();
  const searchParams = useSearchParams();
  
  const [state, setState] = useState<WizardState>({
    step: 1,
    name: '',
    templateKey: '',
    gasFamily: 'methane',
    gasType: 'methane',
    toggles: {
      hasH2S: false,
      hasBenzene: false,
      hasLEL: false,
      hasO2: false,
      isRefill: false,
      is12hr: false,
      isFinal: false,
    },
    targets: {},
    excelTemplatePath: '',
    isEditing: false,
    validationErrors: false,
    validationWarnings: false,
  });
  
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [template, setTemplate] = useState<LogTemplate | null>(null);
  const [currentVersion, setCurrentVersion] = useState<TemplateVersion | null>(null);
  const [validationErrors, setValidationErrors] = useState<string[]>([]);

  // Initialize from URL params
  useEffect(() => {
    const templateId = searchParams.get('templateId');
    const versionId = searchParams.get('versionId');
    const sourceId = searchParams.get('sourceId');
    const sourceType = searchParams.get('sourceType');
    const mode = searchParams.get('mode'); // 'new', 'edit', 'clone', 'duplicate'
    const jobId = searchParams.get('jobId');
    
    if (mode === 'duplicate' && sourceId && sourceType === 'library') {
      loadLibraryTemplate(sourceId, jobId);
    } else if (templateId && versionId) {
      loadExistingTemplate(templateId, versionId, mode === 'clone');
    } else if (mode === 'new') {
      initializeNewTemplate();
    }
  }, [searchParams]);

  const initializeNewTemplate = () => {
    setState(prev => ({
      ...prev,
      name: 'New Template',
      templateKey: `template_${Date.now()}`,
      isEditing: false,
    }));
  };

  const loadExistingTemplate = async (templateId: string, versionId: string, isClone: boolean) => {
    try {
      setLoading(true);
      const { template, activeVersion } = await VersionedTemplateService.getTemplateWithActiveVersion(templateId);
      
      if (!activeVersion) {
        throw new Error('No active version found');
      }

      setTemplate(template);
      setCurrentVersion(activeVersion);
      
      setState(prev => ({
        ...prev,
        templateId: isClone ? undefined : templateId,
        versionId: isClone ? undefined : versionId,
        name: isClone ? `${template.name} (Copy)` : template.name,
        templateKey: isClone ? `${template.templateKey}_copy` : template.templateKey,
        gasFamily: template.gasFamily,
        gasType: activeVersion.gasType,
        toggles: activeVersion.toggles,
        targets: activeVersion.targets,
        excelTemplatePath: activeVersion.excelTemplatePath,
        derivedFromVersion: isClone ? activeVersion.version : undefined,
        isEditing: !isClone,
      }));
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load template');
    } finally {
      setLoading(false);
    }
  };

  const loadLibraryTemplate = async (sourceId: string, jobId?: string | null) => {
    try {
      setLoading(true);
      const libraryTemplate = LIBRARY_TEMPLATES.find(t => t.id === sourceId);
      
      if (!libraryTemplate) {
        throw new Error('Library template not found');
      }

      setState(prev => ({
        ...prev,
        name: `${libraryTemplate.name} (Custom)`,
        templateKey: `${libraryTemplate.id}_custom_${Date.now()}`,
        gasFamily: libraryTemplate.gasType,
        gasType: libraryTemplate.gasType,
        toggles: libraryTemplate.version.toggles,
        targets: libraryTemplate.version.targets,
        excelTemplatePath: libraryTemplate.version.excelTemplatePath,
        isEditing: false,
        step: 2, // Skip base selection since we have the template
      }));

      // If jobId is provided, we'll need it for final assignment
      if (jobId) {
        setState(prev => ({ ...prev, jobId }));
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load library template');
    } finally {
      setLoading(false);
    }
  };

  const updateState = (updates: Partial<WizardState>) => {
    setState(prev => ({ ...prev, ...updates }));
    setError(null);
  };

  const validateCurrentStep = (): boolean => {
    const errors: string[] = [];

    switch (state.step) {
      case 1:
        if (!state.name.trim()) errors.push('Template name is required');
        if (!state.templateKey.trim()) errors.push('Template key is required');
        if (!state.gasFamily) errors.push('Gas family must be selected');
        break;
        
      case 2:
        if (!state.excelTemplatePath) errors.push('Excel template must be uploaded');
        if (state.validationErrors) errors.push('Excel template has validation errors that must be resolved');
        if (state.toggles.hasH2S && !state.targets.h2sPPM) {
          errors.push('H₂S target required when H₂S monitoring is enabled');
        }
        if (state.toggles.hasBenzene && !state.targets.benzenePPM) {
          errors.push('Benzene target required when Benzene monitoring is enabled');
        }
        if (state.toggles.hasLEL && !state.targets.lelPct) {
          errors.push('LEL target required when LEL monitoring is enabled');
        }
        break;
        
      case 3:
        if (state.validationErrors) errors.push('Excel template validation must pass before publishing');
        // Final validation will be done in the service
        break;
    }

    setValidationErrors(errors);
    return errors.length === 0;
  };

  const nextStep = () => {
    if (validateCurrentStep() && state.step < 3) {
      setState(prev => ({ ...prev, step: (prev.step + 1) as 1 | 2 | 3 }));
    }
  };

  const prevStep = () => {
    if (state.step > 1) {
      setState(prev => ({ ...prev, step: (prev.step - 1) as 1 | 2 | 3 }));
    }
  };

  const handleComplete = async (action: 'draft' | 'publish') => {
    try {
      setLoading(true);
      
      // Get filtered fields based on current configuration
      const filteredFields = filterFieldsByConditions(MASTER_FIELDS, state.gasType, state.toggles);
      
      const versionData = {
        status: action === 'publish' ? 'active' : 'draft',
        toggles: state.toggles,
        gasType: state.gasType,
        fields: filteredFields,
        targets: state.targets,
        ui: {
          groups: ['core', 'monitoring', 'operator'],
          layout: 'standard' as const,
        },
        excelTemplatePath: state.excelTemplatePath,
        operationRange: {
          start: 'B12',
          end: 'N28',
          sheet: 'Sheet1',
        },
        derivedFromVersion: state.derivedFromVersion,
        changelog: state.isEditing ? 'Template updated' : 'Initial version',
      };

      // Validate before saving
      const validation = VersionedTemplateService.validateVersion({
        ...versionData,
        version: 1,
        createdAt: Date.now(),
        createdBy: 'admin', // TODO: Get from auth
        hash: '',
      });
      
      if (!validation.valid) {
        setValidationErrors(validation.errors);
        return;
      }

      let templateId = state.templateId;
      let versionId = state.versionId;

      if (state.isEditing && templateId && currentVersion) {
        // Clone existing version for editing
        versionId = await VersionedTemplateService.cloneVersion(
          templateId,
          currentVersion.id!,
          'admin', // TODO: Get from auth
          'Template updated'
        );
      } else if (!templateId) {
        // Create new template
        const result = await VersionedTemplateService.createTemplate({
          name: state.name,
          templateKey: state.templateKey,
          gasFamily: state.gasFamily,
          createdBy: 'admin', // TODO: Get from auth
          initialVersion: versionData,
        });
        templateId = result.templateId;
        versionId = result.versionId;
      }

      if (action === 'publish' && templateId && versionId) {
        await VersionedTemplateService.publishVersion(templateId, versionId, 'admin');
      }

      // Navigate to template list or detail
      router.push('/admin/templates');
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to save template');
    } finally {
      setLoading(false);
    }
  };

  const currentStepData = WIZARD_STEPS[state.step - 1];
  const progress = (state.step / WIZARD_STEPS.length) * 100;

  if (loading && !template) {
    return (
      <div className="flex items-center justify-center h-screen">
        <div className="text-gray-400">Loading...</div>
      </div>
    );
  }

  return (
    <div className="max-w-7xl mx-auto p-6 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <div className="flex items-center gap-4">
            <Button variant="ghost" size="icon" onClick={() => router.push('/admin/templates')}>
              <ArrowLeft className="w-4 h-4" />
            </Button>
            <div>
              <h1 className="text-2xl font-bold text-white">
                {state.isEditing ? 'Edit Template' : 'Template Builder'}
              </h1>
              <p className="text-gray-400">
                {state.name || 'Create a new thermal log template'}
              </p>
            </div>
          </div>
        </div>
        <div className="flex items-center gap-2">
          {state.isEditing && currentVersion && (
            <Badge variant="outline">
              Editing v{currentVersion.version}
            </Badge>
          )}
          <Badge className="bg-green-600">
            Step {state.step} of {WIZARD_STEPS.length}
          </Badge>
        </div>
      </div>

      {/* Progress */}
      <div className="space-y-2">
        <div className="flex justify-between text-sm text-gray-400">
          {WIZARD_STEPS.map((step, index) => (
            <div key={step.id} className={`flex items-center gap-2 ${
              state.step === step.id ? 'text-orange-400' : 
              state.step > step.id ? 'text-green-400' : 'text-gray-400'
            }`}>
              <div className={`w-6 h-6 rounded-full flex items-center justify-center text-xs font-bold ${
                state.step === step.id ? 'bg-orange-600' :
                state.step > step.id ? 'bg-green-600' : 'bg-gray-600'
              }`}>
                {state.step > step.id ? <Check className="w-3 h-3" /> : step.id}
              </div>
              <span className="hidden sm:inline">{step.title}</span>
            </div>
          ))}
        </div>
        <Progress value={progress} className="h-2" />
      </div>

      {/* Error Display */}
      {(error || validationErrors.length > 0) && (
        <Card className="border-red-500 bg-red-50 dark:bg-red-950">
          <CardContent className="pt-6">
            <div className="flex items-start gap-2">
              <AlertCircle className="w-5 h-5 text-red-500 mt-0.5" />
              <div>
                {error && <p className="text-red-700 dark:text-red-300">{error}</p>}
                {validationErrors.map((err, index) => (
                  <p key={index} className="text-red-700 dark:text-red-300">{err}</p>
                ))}
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* Step Content */}
      <Card className="bg-[#1E1E1E] border-gray-800">
        <CardHeader>
          <CardTitle className="text-white">{currentStepData.title}</CardTitle>
          <CardDescription className="text-gray-400">
            {currentStepData.description}
          </CardDescription>
        </CardHeader>
        <CardContent>
          {state.step === 1 && (
            <StepPickBase state={state} updateState={updateState} />
          )}
          {state.step === 2 && (
            <StepConfigure state={state} updateState={updateState} />
          )}
          {state.step === 3 && (
            <StepReviewPublish
              state={state}
              updateState={updateState}
              onComplete={handleComplete}
              template={template}
              currentVersion={currentVersion}
            />
          )}
        </CardContent>
      </Card>

      {/* Navigation */}
      <div className="flex justify-between">
        <Button
          variant="outline"
          onClick={prevStep}
          disabled={state.step === 1}
          className="border-gray-600 text-gray-300 hover:bg-gray-700"
        >
          <ArrowLeft className="w-4 h-4 mr-2" />
          Previous
        </Button>
        
        {state.step < 3 ? (
          <Button
            onClick={nextStep}
            disabled={loading}
            className="bg-orange-600 hover:bg-orange-700"
          >
            Next
            <ArrowRight className="w-4 h-4 ml-2" />
          </Button>
        ) : (
          <div className="flex gap-2">
            <Button
              variant="outline"
              onClick={() => handleComplete('draft')}
              disabled={loading}
              className="border-gray-600 text-gray-300 hover:bg-gray-700"
            >
              Save Draft
            </Button>
            <Button
              onClick={() => handleComplete('publish')}
              disabled={loading}
              className="bg-orange-600 hover:bg-orange-700"
            >
              {loading ? 'Publishing...' : 'Publish'}
            </Button>
          </div>
        )}
      </div>
    </div>
  );
}