'use client';

import { useEffect, useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { FileText, AlertTriangle, CheckCircle } from 'lucide-react';

interface PermitLimits {
  h2sPpmMax: number;
  benzenePpmMax: number;
  tempMinF: number;
  tempMaxF: number;
  flowMin: number;
  flowMax: number;
  emissionsMaxLbHr: number;
}

interface PermitInfo {
  permitId: string;
  facilityName: string;
  limits: PermitLimits;
  expirationDate: Date;
  status: 'active' | 'expired' | 'pending';
}

interface PermitQuickViewCardProps {
  jobId?: string | null;
  onStatusChange?: (status: 'red' | 'amber' | 'green', delta: number) => void;
}

export function PermitQuickViewCard({ jobId, onStatusChange }: PermitQuickViewCardProps) {
  const [permitInfo, setPermitInfo] = useState<PermitInfo | null>(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (jobId) {
      // Mock permit data - would normally fetch from server
      const mockPermit: PermitInfo = {
        permitId: 'EPA-TX-2024-001',
        facilityName: 'Tank Farm Alpha',
        limits: {
          h2sPpmMax: 20,
          benzenePpmMax: 10,
          tempMinF: 180,
          tempMaxF: 800,
          flowMin: 100,
          flowMax: 5000,
          emissionsMaxLbHr: 2.5,
        },
        expirationDate: new Date('2025-06-30'),
        status: 'active',
      };
      
      setPermitInfo(mockPermit);
      
      // Check if permit is expiring soon
      const thirtyDaysFromNow = new Date();
      thirtyDaysFromNow.setDate(thirtyDaysFromNow.getDate() + 30);
      
      if (mockPermit.expirationDate < thirtyDaysFromNow) {
        onStatusChange?.('amber', 1);
      } else {
        onStatusChange?.('green', 1);
      }
    }
  }, [jobId]);

  const getStatusBadge = (status: PermitInfo['status']) => {
    switch (status) {
      case 'active':
        return <Badge className="bg-green-500">Active</Badge>;
      case 'expired':
        return <Badge variant="destructive">Expired</Badge>;
      case 'pending':
        return <Badge className="bg-amber-500">Pending</Badge>;
    }
  };

  const isExpiringSoon = (date: Date) => {
    const thirtyDaysFromNow = new Date();
    thirtyDaysFromNow.setDate(thirtyDaysFromNow.getDate() + 30);
    return date <= thirtyDaysFromNow;
  };

  if (!jobId) {
    return (
      <Card className="col-span-1">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <FileText className="h-5 w-5" />
            Permit Quick View
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="text-center py-8 text-muted-foreground">
            Select a job to view permit details
          </div>
        </CardContent>
      </Card>
    );
  }

  if (!permitInfo) {
    return (
      <Card className="col-span-1">
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <FileText className="h-5 w-5" />
            Permit Quick View
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="text-center py-8 text-muted-foreground">
            Loading permit information...
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <Card className="col-span-1">
      <CardHeader className="flex flex-row items-center justify-between">
        <CardTitle className="flex items-center gap-2">
          <FileText className="h-5 w-5" />
          Permit Quick View
        </CardTitle>
        {getStatusBadge(permitInfo.status)}
      </CardHeader>
      <CardContent>
        <div className="space-y-4">
          {/* Permit Header */}
          <div>
            <div className="font-medium">{permitInfo.permitId}</div>
            <div className="text-sm text-muted-foreground">{permitInfo.facilityName}</div>
          </div>
          
          {/* Expiration Warning */}
          {isExpiringSoon(permitInfo.expirationDate) && (
            <div className="flex items-center gap-2 p-2 bg-amber-50 border border-amber-200 rounded-lg">
              <AlertTriangle className="h-4 w-4 text-amber-600" />
              <span className="text-sm text-amber-800">
                Expires {permitInfo.expirationDate.toLocaleDateString()}
              </span>
            </div>
          )}
          
          {/* Key Limits */}
          <div className="space-y-2">
            <div className="text-sm font-medium">Key Limits</div>
            <div className="grid grid-cols-2 gap-2 text-xs">
              <div className="flex justify-between">
                <span>H2S Max:</span>
                <span className="font-mono">{permitInfo.limits.h2sPpmMax} ppm</span>
              </div>
              <div className="flex justify-between">
                <span>Benzene Max:</span>
                <span className="font-mono">{permitInfo.limits.benzenePpmMax} ppm</span>
              </div>
              <div className="flex justify-between">
                <span>Temp Range:</span>
                <span className="font-mono">
                  {permitInfo.limits.tempMinF}-{permitInfo.limits.tempMaxF}°F
                </span>
              </div>
              <div className="flex justify-between">
                <span>Flow Range:</span>
                <span className="font-mono">
                  {permitInfo.limits.flowMin}-{permitInfo.limits.flowMax} scfh
                </span>
              </div>
              <div className="flex justify-between col-span-2">
                <span>Emissions Max:</span>
                <span className="font-mono">{permitInfo.limits.emissionsMaxLbHr} lb/hr</span>
              </div>
            </div>
          </div>
          
          {/* Status Indicators */}
          <div className="flex items-center gap-2 text-xs">
            <CheckCircle className="h-3 w-3 text-green-500" />
            <span className="text-muted-foreground">All limits within range</span>
          </div>
          
          <div className="text-xs text-muted-foreground border-t pt-2">
            Expires: {permitInfo.expirationDate.toLocaleDateString()}
          </div>
        </div>
      </CardContent>
    </Card>
  );
}