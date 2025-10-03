'use server';

import { getAdminFirestore } from '@/lib/firebase-admin';
import { cookies } from 'next/headers';
import { validateAdminSession } from '@/lib/auth-utils';
import { detectOutliers as detectOutliersUtil, LogEntry, OutlierConfig } from '@/lib/compliance-utils';
import { entriesCollectionRef, logsCollectionRef, projectDocRef } from '@/lib/firestore/paths';

export interface OutlierResult {
  hour: number;
  metric: string;
  previousValue: number;
  currentValue: number;
  change: number;
  changePercent?: number;
  threshold: number;
  severity: 'low' | 'medium' | 'high';
}

export async function detectOutliers(
  projectId: string,
  logId: string,
  date: Date = new Date(),
  config?: Partial<OutlierConfig>
): Promise<{
  outliers: OutlierResult[];
  entriesAnalyzed: number;
}> {
  const cookieStore = await cookies();
  const session = await validateAdminSession(cookieStore);
  
  if (!session || session.role !== 'admin') {
    throw new Error('Unauthorized: Admin access required');
  }

  const db = getAdminFirestore();
  
  try {
    // Get entries for the specified date
    const startOfDay = new Date(date);
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(date);
    endOfDay.setHours(23, 59, 59, 999);
    
    const entriesSnapshot = await entriesCollectionRef(projectId, logId)
      .where('timestamp', '>=', startOfDay)
      .where('timestamp', '<=', endOfDay)
      .orderBy('timestamp')
      .get();
    
    const entries: LogEntry[] = entriesSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      timestamp: doc.data().timestamp,
    } as LogEntry));
    
    if (entries.length < 2) {
      return {
        outliers: [],
        entriesAnalyzed: entries.length,
      };
    }
    
    // Get outlier thresholds from project settings or use defaults
    const projectDoc = await projectDocRef(projectId).get();
    const projectConfig = projectDoc.data()?.outlierConfig || {};
    
    const mergedConfig: OutlierConfig = {
      exhaustTempThreshold: config?.exhaustTempThreshold || projectConfig.exhaustTempThreshold || 50,
      flowThreshold: config?.flowThreshold || projectConfig.flowThreshold || 25,
      h2sThreshold: config?.h2sThreshold || projectConfig.h2sThreshold || 10,
      benzeneThreshold: config?.benzeneThreshold || projectConfig.benzeneThreshold || 5,
    };
    
    const rawOutliers = detectOutliersUtil(entries, mergedConfig);
    
    // Enhance outliers with severity
    const outliers: OutlierResult[] = rawOutliers.map(outlier => {
      let severity: 'low' | 'medium' | 'high' = 'low';
      const changeRatio = outlier.change / outlier.threshold;
      
      if (changeRatio >= 2) {
        severity = 'high';
      } else if (changeRatio >= 1.5) {
        severity = 'medium';
      }
      
      return {
        ...outlier,
        changePercent: outlier.metric === 'Flow Rate' ? outlier.change : undefined,
        severity,
      };
    });
    
    return {
      outliers,
      entriesAnalyzed: entries.length,
    };
  } catch (error) {
    console.error('Error detecting outliers:', error);
    throw new Error('Failed to detect outliers');
  }
}

export async function updateOutlierThresholds(
  projectId: string,
  config: Partial<OutlierConfig>
): Promise<void> {
  const cookieStore = await cookies();
  const session = await validateAdminSession(cookieStore);
  
  if (!session || session.role !== 'admin') {
    throw new Error('Unauthorized: Admin access required');
  }

  const db = getAdminFirestore();
  
  try {
    await db
      .collection('projects')
      .doc(projectId)
      .update({
        outlierConfig: config,
        outlierConfigUpdatedBy: session.uid,
        outlierConfigUpdatedAt: new Date(),
      });
  } catch (error) {
    console.error('Error updating outlier thresholds:', error);
    throw new Error('Failed to update outlier thresholds');
  }
}