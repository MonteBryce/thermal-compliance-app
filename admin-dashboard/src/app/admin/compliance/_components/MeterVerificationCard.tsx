'use client';

import { useEffect, useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Textarea } from '@/components/ui/textarea';
import { CheckCircle, XCircle, Gauge, Edit } from 'lucide-react';
import { verifyMeters } from '@/lib/compliance-utils';

interface MeterCheck {
  meterType: string;
  required: boolean;
  installed: boolean;
  model?: string;
  serialNumber?: string;
  lastCalibration?: Date;
  status: 'verified' | 'missing' | 'extra';
}

interface MeterVerificationCardProps {
  jobId?: string | null;
  onStatusChange?: (status: 'red' | 'amber' | 'green', delta: number) => void;
}

export function MeterVerificationCard({ jobId, onStatusChange }: MeterVerificationCardProps) {
  const [meterChecks, setMeterChecks] = useState<MeterCheck[]>([]);
  const [notes, setNotes] = useState('');
  const [loading, setLoading] = useState(false);
  const [editing, setEditing] = useState(false);
  const [verificationStatus, setVerificationStatus] = useState<'verified' | 'partial' | 'failed'>('verified');

  // Mock data for demonstration - would normally fetch from server
  useEffect(() => {
    if (jobId) {
      // Simulate meter verification data
      const mockChecks: MeterCheck[] = [
        {
          meterType: 'Exhaust Temperature',
          required: true,
          installed: true,
          model: 'ThermoCouple-K',
          serialNumber: 'TC-001',
          lastCalibration: new Date('2024-01-15'),
          status: 'verified',
        },
        {
          meterType: 'Flow Rate',
          required: true,
          installed: true,
          model: 'FlowMeter-X200',
          serialNumber: 'FM-002',
          lastCalibration: new Date('2024-02-01'),
          status: 'verified',
        },
        {
          meterType: 'H2S Analyzer',
          required: true,
          installed: false,
          status: 'missing',
        },
        {
          meterType: 'Pressure Sensor',
          required: false,
          installed: true,
          model: 'PS-100',
          serialNumber: 'PS-003',
          status: 'extra',
        },
      ];
      
      setMeterChecks(mockChecks);
      
      // Determine overall status
      const missing = mockChecks.filter(m => m.status === 'missing');
      const hasIssues = missing.length > 0;
      
      if (hasIssues) {
        setVerificationStatus('failed');
        onStatusChange?.('red', 1);
      } else {
        setVerificationStatus('verified');
        onStatusChange?.('green', 1);
      }
    }
  }, [jobId]);

  const getStatusIcon = (status: MeterCheck['status']) => {
    switch (status) {
      case 'verified':
        return <CheckCircle className="h-4 w-4 text-green-500" />;
      case 'missing':
        return <XCircle className="h-4 w-4 text-destructive" />;
      case 'extra':
        return <Badge variant="outline" className="text-xs">Extra</Badge>;
    }
  };

  const getStatusBadge = () => {
    switch (verificationStatus) {
      case 'verified':
        return <Badge className="bg-green-500">✓ Verified</Badge>;
      case 'partial':
        return <Badge className="bg-amber-500">⚠ Partial</Badge>;
      case 'failed':
        return <Badge variant="destructive">✗ Failed</Badge>;
    }
  };

  const isCalibrationExpired = (date?: Date) => {
    if (!date) return false;
    const sixMonthsAgo = new Date();
    sixMonthsAgo.setMonth(sixMonthsAgo.getMonth() - 6);
    return date < sixMonthsAgo;
  };

  return (
    <Card className="col-span-1">
      <CardHeader className="flex flex-row items-center justify-between">
        <CardTitle className="flex items-center gap-2">
          <Gauge className="h-5 w-5" />
          Meter Verification
          {getStatusBadge()}
        </CardTitle>
        <Button
          variant="ghost"
          size="icon"
          onClick={() => setEditing(!editing)}
        >
          <Edit className="h-4 w-4" />
        </Button>
      </CardHeader>
      <CardContent>
        {!jobId && (
          <div className="text-center py-8 text-muted-foreground">
            Select a job to verify meters
          </div>
        )}
        
        {jobId && (
          <div className="space-y-4">
            <div className="space-y-2">
              {meterChecks.map((check, idx) => (
                <div
                  key={idx}
                  className="flex items-center justify-between p-3 border rounded-lg"
                >
                  <div className="flex items-center gap-3">
                    {getStatusIcon(check.status)}
                    <div>
                      <div className="font-medium">{check.meterType}</div>
                      {check.installed && (
                        <div className="text-xs text-muted-foreground space-y-1">
                          {check.model && <div>Model: {check.model}</div>}
                          {check.serialNumber && <div>S/N: {check.serialNumber}</div>}
                          {check.lastCalibration && (
                            <div className={isCalibrationExpired(check.lastCalibration) ? 'text-destructive' : ''}>
                              Cal: {check.lastCalibration.toLocaleDateString()}
                              {isCalibrationExpired(check.lastCalibration) && ' (Expired)'}
                            </div>
                          )}
                        </div>
                      )}
                    </div>
                  </div>
                  <div>
                    {check.required ? (
                      <Badge variant="outline" className="text-xs">Required</Badge>
                    ) : (
                      <Badge variant="secondary" className="text-xs">Optional</Badge>
                    )}
                  </div>
                </div>
              ))}
            </div>
            
            {editing && (
              <div className="space-y-2">
                <label className="text-sm font-medium">Verification Notes</label>
                <Textarea
                  placeholder="Add notes about meter verification, calibration dates, or issues..."
                  value={notes}
                  onChange={(e) => setNotes(e.target.value)}
                  rows={3}
                />
                <div className="flex gap-2">
                  <Button size="sm" onClick={() => setEditing(false)}>
                    Save Notes
                  </Button>
                  <Button size="sm" variant="outline" onClick={() => setEditing(false)}>
                    Cancel
                  </Button>
                </div>
              </div>
            )}
            
            <div className="text-xs text-muted-foreground">
              Last verified: {new Date().toLocaleDateString()} by System Admin
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  );
}