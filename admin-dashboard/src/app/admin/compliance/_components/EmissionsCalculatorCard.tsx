'use client';

import { useEffect, useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Progress } from '@/components/ui/progress';
import { Calculator, TrendingUp, AlertTriangle, RefreshCw } from 'lucide-react';
import { calculateEmissions, LogEntry } from '@/lib/compliance-utils';

interface EmissionsData {
  hourlyEmissions: Array<{ hour: number; emissions: number }>;
  totalEmissions: number;
  averageEmissions: number;
  peakEmissions: number;
  peakHour: number;
  percentOfLimit: number;
  withinLimit: boolean;
}

interface EmissionsCalculatorCardProps {
  jobId?: string | null;
  onStatusChange?: (status: 'red' | 'amber' | 'green', delta: number) => void;
}

export function EmissionsCalculatorCard({ jobId, onStatusChange }: EmissionsCalculatorCardProps) {
  const [emissionsData, setEmissionsData] = useState<EmissionsData | null>(null);
  const [loading, setLoading] = useState(false);
  const [permitLimit] = useState(2.5); // lb/hr from permit
  const [selectedDate, setSelectedDate] = useState(new Date());

  const mockLogEntries: LogEntry[] = [
    { id: '1', hour: 8, exhaustTemp: 650, flow: 1200, h2sPpm: 15, timestamp: new Date(), operatorId: 'op1' },
    { id: '2', hour: 9, exhaustTemp: 675, flow: 1150, h2sPpm: 18, timestamp: new Date(), operatorId: 'op1' },
    { id: '3', hour: 10, exhaustTemp: 700, flow: 1300, h2sPpm: 12, timestamp: new Date(), operatorId: 'op1' },
    { id: '4', hour: 11, exhaustTemp: 680, flow: 1250, h2sPpm: 22, timestamp: new Date(), operatorId: 'op1' },
    { id: '5', hour: 12, exhaustTemp: 690, flow: 1180, h2sPpm: 16, timestamp: new Date(), operatorId: 'op2' },
    { id: '6', hour: 13, exhaustTemp: 710, flow: 1350, h2sPpm: 20, timestamp: new Date(), operatorId: 'op2' },
    { id: '7', hour: 14, exhaustTemp: 720, flow: 1400, h2sPpm: 25, timestamp: new Date(), operatorId: 'op2' },
    { id: '8', hour: 15, exhaustTemp: 695, flow: 1220, h2sPpm: 14, timestamp: new Date(), operatorId: 'op2' },
  ];

  const calculateJobEmissions = () => {
    if (!jobId) return;
    
    setLoading(true);
    
    // Simulate calculation delay
    setTimeout(() => {
      const results = calculateEmissions(mockLogEntries, 34.08); // H2S molecular weight
      const maxEmissions = Math.max(...results.hourlyEmissions.map(h => h.emissions));
      const percentOfLimit = (maxEmissions / permitLimit) * 100;
      const withinLimit = maxEmissions <= permitLimit;
      
      const emissionsData: EmissionsData = {
        ...results,
        percentOfLimit,
        withinLimit,
      };
      
      setEmissionsData(emissionsData);
      
      // Update status based on emissions
      if (onStatusChange) {
        if (!withinLimit) {
          onStatusChange('red', 1);
        } else if (percentOfLimit > 80) {
          onStatusChange('amber', 1);
        } else {
          onStatusChange('green', 1);
        }
      }
      
      setLoading(false);
    }, 1000);
  };

  useEffect(() => {
    if (jobId) {
      calculateJobEmissions();
    }
  }, [jobId, selectedDate]);

  const getStatusBadge = () => {
    if (!emissionsData) return null;
    
    if (!emissionsData.withinLimit) {
      return <Badge variant="destructive">❌ Exceeds Limit</Badge>;
    } else if (emissionsData.percentOfLimit > 80) {
      return <Badge className="bg-amber-500">⚠ Near Limit</Badge>;
    } else {
      return <Badge className="bg-green-500">✅ Within Limit</Badge>;
    }
  };

  const formatHour = (hour: number) => {
    return `${hour.toString().padStart(2, '0')}:00`;
  };

  if (!jobId) {
    return (
      <Card className="col-span-1">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Calculator className="h-5 w-5" />
            Emissions Calculator
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="text-center py-8 text-muted-foreground">
            Select a job to calculate emissions
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className="col-span-1">
      <CardHeader className="flex flex-row items-center justify-between">
        <div>
          <CardTitle className="flex items-center gap-2">
            <Calculator className="h-5 w-5" />
            Emissions Calculator
            {getStatusBadge()}
          </CardTitle>
          <div className="text-xs text-muted-foreground mt-1">
            H2S Emissions - Permit Limit: {permitLimit} lb/hr
          </div>
        </div>
        <div className="flex gap-2">
          <Button
            variant="ghost"
            size="icon"
            onClick={calculateJobEmissions}
            disabled={loading}
          >
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          </Button>
        </div>
      </CardHeader>
      <CardContent>
        {loading && (
          <div className="text-center py-8">
            <RefreshCw className="h-6 w-6 animate-spin mx-auto mb-2" />
            <div className="text-sm text-muted-foreground">Calculating emissions...</div>
          </div>
        )}
        
        {emissionsData && !loading && (
          <div className="space-y-4">
            {/* Summary Stats */}
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-1">
                <div className="text-xs text-muted-foreground">Total Emissions</div>
                <div className="text-lg font-bold">{emissionsData.totalEmissions} lb</div>
              </div>
              <div className="space-y-1">
                <div className="text-xs text-muted-foreground">Average Rate</div>
                <div className="text-lg font-bold">{emissionsData.averageEmissions} lb/hr</div>
              </div>
              <div className="space-y-1">
                <div className="text-xs text-muted-foreground">Peak Rate</div>
                <div className="text-lg font-bold text-amber-600">
                  {emissionsData.peakEmissions} lb/hr
                </div>
                <div className="text-xs text-muted-foreground">
                  at {formatHour(emissionsData.peakHour)}
                </div>
              </div>
              <div className="space-y-1">
                <div className="text-xs text-muted-foreground">% of Limit</div>
                <div className={`text-lg font-bold ${
                  emissionsData.percentOfLimit > 100 ? 'text-destructive' :
                  emissionsData.percentOfLimit > 80 ? 'text-amber-600' : 'text-green-600'
                }`}>
                  {emissionsData.percentOfLimit.toFixed(1)}%
                </div>
              </div>
            </div>
            
            {/* Progress Bar */}
            <div className="space-y-2">
              <div className="flex justify-between text-xs">
                <span>Peak vs Permit Limit</span>
                <span>{emissionsData.peakEmissions} / {permitLimit} lb/hr</span>
              </div>
              <Progress 
                value={Math.min(emissionsData.percentOfLimit, 100)} 
                className={`h-2 ${
                  emissionsData.percentOfLimit > 100 ? '[&>div]:bg-destructive' :
                  emissionsData.percentOfLimit > 80 ? '[&>div]:bg-amber-500' : '[&>div]:bg-green-500'
                }`}
              />
            </div>
            
            {/* Hourly Breakdown */}
            <div className="space-y-2">
              <div className="text-sm font-medium">Hourly Emissions</div>
              <div className="grid grid-cols-4 gap-1 text-xs">
                {emissionsData.hourlyEmissions.slice(0, 8).map(({ hour, emissions }) => (
                  <div
                    key={hour}
                    className={`p-2 rounded text-center border ${
                      emissions > permitLimit ? 'border-destructive bg-destructive/10' :
                      emissions > permitLimit * 0.8 ? 'border-amber-500 bg-amber-500/10' :
                      'border-green-500 bg-green-500/10'
                    }`}
                  >
                    <div className="font-mono">{formatHour(hour)}</div>
                    <div className="font-medium">{emissions.toFixed(2)}</div>
                  </div>
                ))}
              </div>
              {emissionsData.hourlyEmissions.length > 8 && (
                <div className="text-xs text-muted-foreground text-center">
                  +{emissionsData.hourlyEmissions.length - 8} more hours
                </div>
              )}
            </div>
            
            {/* Warnings */}
            {!emissionsData.withinLimit && (
              <div className="p-3 bg-destructive/10 border border-destructive/20 rounded-lg">
                <div className="flex items-center gap-2 text-destructive">
                  <AlertTriangle className="h-4 w-4" />
                  <span className="text-sm font-medium">Permit Limit Exceeded</span>
                </div>
                <div className="text-xs text-destructive/80 mt-1">
                  Peak emissions of {emissionsData.peakEmissions} lb/hr exceeds permit limit of {permitLimit} lb/hr
                </div>
              </div>
            )}
            
            <div className="text-xs text-muted-foreground border-t pt-2">
              Last calculated: {new Date().toLocaleString()} • 
              Formula: Flow × Concentration × MW / (379.5 × 10⁶)
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  );
}