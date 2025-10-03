'use client';

import { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { TemplateGridPreview } from '@/components/template/TemplateGridPreview';
import { MetricDesignerPanel } from '@/components/template/MetricDesignerPanel';
import { StructureValidationPanel } from '@/components/template/StructureValidationPanel';
import { LogTemplate, TemplateMetric, createDefaultTemplate, STANDARD_METRICS } from '@/lib/types/template';
import { TemplateService } from '@/lib/services/template.service';
import { 
  TestTube, 
  Thermometer, 
  Wind, 
  Gauge,
  RefreshCw,
  Eye,
  Settings,
  FileSpreadsheet
} from 'lucide-react';

export default function TestTemplatesPage() {
  const [templates, setTemplates] = useState<Record<string, LogTemplate>>({});
  const [activeTemplate, setActiveTemplate] = useState<string>('methane_hourly');
  const [isLoading, setIsLoading] = useState(true);

  const templateService = TemplateService.getInstance();

  const templateTypes = [
    {
      key: 'methane_hourly',
      name: 'Methane Hourly',
      description: 'Hourly methane monitoring log with exhaust temperature and flow rates',
      icon: <Thermometer className="h-5 w-5 text-red-400" />,
      color: 'bg-red-600'
    },
    {
      key: 'benzene_12hr',
      name: 'Benzene 12HR',
      description: 'Semi-daily benzene monitoring with H2S readings and degas measurements',
      icon: <TestTube className="h-5 w-5 text-purple-400" />,
      color: 'bg-purple-600'
    },
    {
      key: 'custom_flow',
      name: 'Custom Flow',
      description: 'Custom template for flow rate monitoring',
      icon: <Wind className="h-5 w-5 text-cyan-400" />,
      color: 'bg-cyan-600'
    },
    {
      key: 'pressure_monitoring',
      name: 'Pressure Monitoring',
      description: 'Pressure and vacuum monitoring template',
      icon: <Gauge className="h-5 w-5 text-blue-400" />,
      color: 'bg-blue-600'
    }
  ];

  useEffect(() => {
    loadAllTemplates();
  }, []);

  const loadAllTemplates = async () => {
    setIsLoading(true);
    const loadedTemplates: Record<string, LogTemplate> = {};

    try {
      // Load standard templates
      for (const templateType of templateTypes) {
        try {
          let template = await templateService.getTemplate(templateType.key);
          if (!template) {
            // Create default template if it doesn't exist
            template = createTemplateFromType(templateType.key);
          }
          loadedTemplates[templateType.key] = template;
        } catch (error) {
          console.error(`Error loading template ${templateType.key}:`, error);
          // Fallback to default template
          loadedTemplates[templateType.key] = createTemplateFromType(templateType.key);
        }
      }

      setTemplates(loadedTemplates);
    } catch (error) {
      console.error('Error loading templates:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const createTemplateFromType = (logType: string): LogTemplate => {
    if (STANDARD_METRICS[logType]) {
      return createDefaultTemplate(logType);
    }

    // Create custom templates for demo purposes
    let customMetrics: TemplateMetric[] = [];
    
    switch (logType) {
      case 'custom_flow':
        customMetrics = [
          {
            key: 'inspectionTime',
            label: 'Inspection Time',
            required: true,
            visible: true,
            order: 1,
            category: 'primary'
          },
          {
            key: 'operatorInitials',
            label: 'Operator Initials',
            required: true,
            visible: true,
            order: 2,
            category: 'primary'
          },
          {
            key: 'inletFlowRate',
            label: 'Inlet Flow Rate',
            unit: 'CFM',
            required: true,
            visible: true,
            order: 10,
            category: 'flow'
          },
          {
            key: 'outletFlowRate',
            label: 'Outlet Flow Rate',
            unit: 'CFM',
            required: true,
            visible: true,
            order: 11,
            category: 'flow'
          },
          {
            key: 'differentialPressure',
            label: 'Differential Pressure',
            unit: 'in H₂O',
            required: false,
            visible: true,
            order: 20,
            category: 'pressure'
          },
          {
            key: 'velocityReading',
            label: 'Velocity Reading',
            unit: 'FPM',
            required: false,
            visible: false,
            order: 21,
            category: 'flow'
          }
        ];
        break;

      case 'pressure_monitoring':
        customMetrics = [
          {
            key: 'inspectionTime',
            label: 'Inspection Time',
            required: true,
            visible: true,
            order: 1,
            category: 'primary'
          },
          {
            key: 'operatorInitials',
            label: 'Operator Initials',
            required: true,
            visible: true,
            order: 2,
            category: 'primary'
          },
          {
            key: 'systemPressure',
            label: 'System Pressure',
            unit: 'PSI',
            required: true,
            visible: true,
            order: 10,
            category: 'pressure'
          },
          {
            key: 'vacuumLevel',
            label: 'Vacuum Level',
            unit: 'in Hg',
            required: true,
            visible: true,
            order: 11,
            category: 'pressure'
          },
          {
            key: 'differentialPressure',
            label: 'Differential Pressure',
            unit: 'in H₂O',
            required: false,
            visible: true,
            order: 12,
            category: 'pressure'
          },
          {
            key: 'temperature',
            label: 'System Temperature',
            unit: '°F',
            required: false,
            visible: true,
            order: 20,
            category: 'primary'
          }
        ];
        break;

      default:
        customMetrics = [
          {
            key: 'inspectionTime',
            label: 'Inspection Time',
            required: true,
            visible: true,
            order: 1,
            category: 'primary'
          },
          {
            key: 'operatorInitials',
            label: 'Operator Initials',
            required: true,
            visible: true,
            order: 2,
            category: 'primary'
          },
          {
            key: 'reading',
            label: 'Reading',
            unit: 'units',
            required: true,
            visible: true,
            order: 10,
            category: 'other'
          }
        ];
        break;
    }

    return {
      id: `${logType}_v1`,
      logType,
      displayName: `${logType.replace(/_/g, ' ').toUpperCase()} Template`,
      description: `Test template for ${logType.replace(/_/g, ' ')} monitoring`,
      hours: ['00', '01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23'],
      groups: [
        {
          label: 'AM',
          hours: ['00', '01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11'],
          color: '#3B82F6'
        },
        {
          label: 'PM',
          hours: ['12', '13', '14', '15', '16', '17', '18', '19', '20', '21', '22', '23'],
          color: '#F59E0B'
        }
      ],
      metrics: customMetrics,
      validation: {},
      version: 1,
      updatedAt: new Date().toISOString(),
      updatedBy: 'test',
      active: true
    };
  };

  const handleMetricsChange = (logType: string, metrics: TemplateMetric[]) => {
    setTemplates(prev => ({
      ...prev,
      [logType]: {
        ...prev[logType]!,
        metrics
      }
    }));
  };

  const getCurrentTemplate = () => templates[activeTemplate];
  const currentTemplateType = templateTypes.find(t => t.key === activeTemplate);

  if (isLoading) {
    return (
      <div className="min-h-screen bg-[#111111] flex items-center justify-center">
        <div className="text-center">
          <RefreshCw className="h-8 w-8 animate-spin text-orange-500 mx-auto mb-4" />
          <p className="text-gray-400">Loading templates...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#111111]">
      {/* Header */}
      <div className="bg-[#1E1E1E] border-b border-gray-800 p-4">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-xl font-bold text-white">Template Testing Center</h1>
            <p className="text-gray-400 text-sm">Test different log template types and configurations</p>
          </div>
          <Badge className="bg-orange-600 text-white border-0">
            {Object.keys(templates).length} Templates Loaded
          </Badge>
        </div>
      </div>

      {/* Template Type Selector */}
      <div className="p-4 border-b border-gray-800">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          {templateTypes.map((type) => (
            <Card 
              key={type.key}
              className={`cursor-pointer transition-all border-2 ${
                activeTemplate === type.key 
                  ? 'border-orange-600 bg-[#2A2A2A]' 
                  : 'border-gray-800 bg-[#1E1E1E] hover:border-gray-700'
              }`}
              onClick={() => setActiveTemplate(type.key)}
            >
              <CardContent className="p-4">
                <div className="flex items-center gap-3 mb-2">
                  {type.icon}
                  <div>
                    <h3 className="text-white font-medium">{type.name}</h3>
                    <Badge className={`text-xs ${type.color} text-white border-0`}>
                      {templates[type.key]?.metrics?.filter(m => m.visible).length || 0} visible
                    </Badge>
                  </div>
                </div>
                <p className="text-gray-400 text-sm">{type.description}</p>
              </CardContent>
            </Card>
          ))}
        </div>
      </div>

      {/* Template Content */}
      {getCurrentTemplate() && (
        <div className="p-4">
          <Tabs defaultValue="preview" className="w-full">
            <TabsList className="grid w-full grid-cols-3">
              <TabsTrigger value="preview" className="flex items-center gap-2">
                <Eye className="h-4 w-4" />
                Grid Preview
              </TabsTrigger>
              <TabsTrigger value="designer" className="flex items-center gap-2">
                <Settings className="h-4 w-4" />
                Metrics Designer
              </TabsTrigger>
              <TabsTrigger value="validation" className="flex items-center gap-2">
                <FileSpreadsheet className="h-4 w-4" />
                Excel Validation
              </TabsTrigger>
            </TabsList>

            <TabsContent value="preview" className="mt-6">
              <div className="space-y-4">
                {/* Template Info */}
                <Card className="bg-[#1E1E1E] border-gray-800">
                  <CardHeader>
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-3">
                        {currentTemplateType?.icon}
                        <div>
                          <CardTitle className="text-white">{currentTemplateType?.name}</CardTitle>
                          <p className="text-gray-400 text-sm">{currentTemplateType?.description}</p>
                        </div>
                      </div>
                      <div className="flex items-center gap-2">
                        <Badge className="bg-blue-600 text-white border-0">
                          v{getCurrentTemplate()?.version}
                        </Badge>
                        <Badge className="bg-green-600 text-white border-0">
                          {getCurrentTemplate()?.hours?.length || 24} hours
                        </Badge>
                      </div>
                    </div>
                  </CardHeader>
                </Card>

                {/* Grid Preview */}
                <TemplateGridPreview
                  template={getCurrentTemplate()!}
                  isEditable={false}
                  showMetadata={true}
                />
              </div>
            </TabsContent>

            <TabsContent value="designer" className="mt-6">
              {getCurrentTemplate() && (
                <MetricDesignerPanel
                  metrics={getCurrentTemplate()!.metrics || []}
                  onMetricsChange={(metrics) => handleMetricsChange(activeTemplate, metrics)}
                />
              )}
            </TabsContent>

            <TabsContent value="validation" className="mt-6">
              {getCurrentTemplate() && (
                <StructureValidationPanel
                  template={getCurrentTemplate()!}
                  onValidationComplete={(result) => {
                    console.log('Validation result for', activeTemplate, ':', result);
                  }}
                />
              )}
            </TabsContent>
          </Tabs>
        </div>
      )}
    </div>
  );
}