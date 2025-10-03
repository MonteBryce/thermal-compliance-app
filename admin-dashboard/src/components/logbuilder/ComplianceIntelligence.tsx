import React, { useState, useCallback } from 'react';
import { Shield, Loader2, AlertTriangle, CheckCircle } from 'lucide-react';
import { LogField } from '@/lib/types/logbuilder';
import { cn } from '@/lib/utils';

export interface ComplianceResult {
  overallScore: number;
  requiredFields: Array<{
    key: string;
    label: string;
    regulation: string;
    required: boolean;
    present: boolean;
    importance: 'critical' | 'high' | 'medium';
  }>;
  recommendedFields: Array<{
    key: string;
    label: string;
    regulation: string;
    reasoning: string;
  }>;
  warnings: Array<{
    field: string;
    message: string;
    regulation: string;
  }>;
}

export interface ComplianceIntelligenceProps {
  industry: string;
  regulations: string[];
  templateType: string;
  existingFields: LogField[];
  onComplianceCheck: (result: ComplianceResult) => void;
  onError: (error: Error) => void;
  className?: string;
}

// Mock compliance database
async function validateRegulatory(params: {
  industry: string;
  regulations: string[];
  templateType: string;
  fields: LogField[];
}): Promise<ComplianceResult> {
  // Simulate compliance check delay
  await new Promise(resolve => setTimeout(resolve, 800));

  const existingFieldKeys = new Set(params.fields.map(f => f.key));

  // Mock compliance rules for thermal logging
  const thermalComplianceFields = [
    {
      key: 'operatorCertification',
      label: 'Operator Certification',
      regulation: 'EPA',
      required: true,
      importance: 'critical' as const
    },
    {
      key: 'equipmentCalibrationDate',
      label: 'Equipment Calibration Date',
      regulation: 'EPA',
      required: true,
      importance: 'high' as const
    },
    {
      key: 'safetyCheckCompleted',
      label: 'Safety Check Completed',
      regulation: 'OSHA',
      required: true,
      importance: 'critical' as const
    }
  ];

  const requiredFields = thermalComplianceFields.map(field => ({
    ...field,
    present: existingFieldKeys.has(field.key)
  }));

  const missingCritical = requiredFields.filter(f => !f.present && f.importance === 'critical').length;
  const missingHigh = requiredFields.filter(f => !f.present && f.importance === 'high').length;
  
  // Calculate compliance score
  const totalRequired = requiredFields.length;
  const totalPresent = requiredFields.filter(f => f.present).length;
  const baseScore = totalPresent / totalRequired;
  const penaltyForCritical = missingCritical * 0.3;
  const penaltyForHigh = missingHigh * 0.1;
  
  const overallScore = Math.max(0, baseScore - penaltyForCritical - penaltyForHigh);

  return {
    overallScore,
    requiredFields,
    recommendedFields: [
      {
        key: 'maintenanceDate',
        label: 'Last Maintenance Date',
        regulation: 'OSHA',
        reasoning: 'Equipment maintenance tracking required for safety compliance'
      }
    ],
    warnings: [
      {
        field: 'temperatureReading',
        message: 'Consider adding calibration date validation',
        regulation: 'EPA'
      }
    ]
  };
}

export function ComplianceIntelligence({
  industry,
  regulations,
  templateType,
  existingFields,
  onComplianceCheck,
  onError,
  className,
}: ComplianceIntelligenceProps) {
  const [isChecking, setIsChecking] = useState(false);
  const [complianceResult, setComplianceResult] = useState<ComplianceResult | null>(null);

  const handleCheckCompliance = useCallback(async () => {
    if (isChecking) return;

    setIsChecking(true);

    try {
      const result = await validateRegulatory({
        industry,
        regulations,
        templateType,
        fields: existingFields
      });
      
      setComplianceResult(result);
      onComplianceCheck(result);
    } catch (error) {
      console.error('Compliance check failed:', error);
      onError(error instanceof Error ? error : new Error('Compliance check failed'));
    } finally {
      setIsChecking(false);
    }
  }, [industry, regulations, templateType, existingFields, isChecking, onComplianceCheck, onError]);

  return (
    <div
      data-testid="compliance-intelligence"
      className={cn(
        'compliance-intelligence',
        'bg-white',
        'border',
        'border-gray-200',
        'rounded-lg',
        'p-4',
        'space-y-4',
        className
      )}
    >
      {/* Header */}
      <div className="flex items-center gap-3">
        <div className="p-2 bg-purple-100 rounded-lg">
          <Shield className="w-5 h-5 text-purple-600" />
        </div>
        <div>
          <h3 className="text-lg font-semibold text-gray-900">Regulatory Compliance Check</h3>
          <p className="text-sm text-gray-600">Industry: {industry}</p>
        </div>
      </div>

      {/* Context Info */}
      <div className="grid grid-cols-2 gap-4 text-sm">
        <div>
          <span className="font-medium text-gray-700">Regulations:</span>
          <div className="text-gray-900">{regulations.join(', ')}</div>
        </div>
        <div>
          <span className="font-medium text-gray-700">Template Type:</span>
          <div className="text-gray-900">{templateType}</div>
        </div>
      </div>

      {/* Check Button */}
      <button
        type="button"
        onClick={handleCheckCompliance}
        disabled={isChecking}
        className={cn(
          'flex items-center gap-2 px-4 py-2 rounded-lg font-medium transition-colors',
          'focus:outline-none focus:ring-2 focus:ring-purple-500 focus:ring-offset-2',
          isChecking
            ? 'bg-gray-100 text-gray-400 cursor-not-allowed'
            : 'bg-purple-600 text-white hover:bg-purple-700'
        )}
      >
        {isChecking ? (
          <>
            <Loader2 className="w-4 h-4 animate-spin" />
            <span>Checking compliance...</span>
          </>
        ) : (
          <>
            <Shield className="w-4 h-4" />
            <span>Check Compliance</span>
          </>
        )}
      </button>

      {/* Results */}
      {complianceResult && (
        <div className="space-y-4 p-3 bg-gray-50 rounded-lg">
          {/* Compliance Score */}
          <div className="flex items-center justify-between">
            <h4 className="font-medium text-gray-900">Compliance Score</h4>
            <div className={cn(
              'text-2xl font-bold',
              complianceResult.overallScore >= 0.8 ? 'text-green-600' :
              complianceResult.overallScore >= 0.6 ? 'text-yellow-600' : 'text-red-600'
            )}>
              {Math.round(complianceResult.overallScore * 100)}%
            </div>
          </div>

          {/* Missing Required Fields */}
          {complianceResult.requiredFields.some(f => !f.present) && (
            <div>
              <h5 className="text-sm font-medium text-red-700 mb-2 flex items-center gap-1">
                <AlertTriangle className="w-4 h-4" />
                Missing Required Fields
              </h5>
              <div className="space-y-1">
                {complianceResult.requiredFields
                  .filter(field => !field.present)
                  .map(field => (
                    <div key={field.key} className="flex justify-between text-sm">
                      <span>{field.label}</span>
                      <div className="flex items-center gap-2">
                        <span className="text-gray-500">{field.regulation}</span>
                        <span className={cn(
                          'px-2 py-0.5 rounded text-xs font-medium',
                          field.importance === 'critical' ? 'bg-red-100 text-red-700' :
                          field.importance === 'high' ? 'bg-orange-100 text-orange-700' :
                          'bg-yellow-100 text-yellow-700'
                        )}>
                          {field.importance}
                        </span>
                      </div>
                    </div>
                  ))}
              </div>
            </div>
          )}

          {/* Compliant Fields */}
          {complianceResult.requiredFields.some(f => f.present) && (
            <div>
              <h5 className="text-sm font-medium text-green-700 mb-2 flex items-center gap-1">
                <CheckCircle className="w-4 h-4" />
                Compliant Fields
              </h5>
              <div className="space-y-1">
                {complianceResult.requiredFields
                  .filter(field => field.present)
                  .map(field => (
                    <div key={field.key} className="flex justify-between text-sm">
                      <span>{field.label}</span>
                      <span className="text-gray-500">{field.regulation}</span>
                    </div>
                  ))}
              </div>
            </div>
          )}

          {/* Recommendations */}
          {complianceResult.recommendedFields.length > 0 && (
            <div>
              <h5 className="text-sm font-medium text-blue-700 mb-2">Recommendations</h5>
              <div className="space-y-1">
                {complianceResult.recommendedFields.map(field => (
                  <div key={field.key} className="text-sm">
                    <div className="flex justify-between">
                      <strong>{field.label}</strong>
                      <span className="text-gray-500">{field.regulation}</span>
                    </div>
                    <p className="text-gray-600 text-xs">{field.reasoning}</p>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Warnings */}
          {complianceResult.warnings.length > 0 && (
            <div>
              <h5 className="text-sm font-medium text-yellow-700 mb-2">Regulatory Guidance</h5>
              <div className="space-y-1">
                {complianceResult.warnings.map((warning, index) => (
                  <div key={index} className="text-sm text-yellow-800 bg-yellow-50 p-2 rounded">
                    <strong>{warning.field}:</strong> {warning.message}
                    <span className="text-gray-600 ml-2">({warning.regulation})</span>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}

export default ComplianceIntelligence;