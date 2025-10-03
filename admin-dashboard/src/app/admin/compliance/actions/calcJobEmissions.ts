'use server';

import { getAdminFirestore } from '@/lib/firebase-admin';
import { cookies } from 'next/headers';
import { validateAdminSession } from '@/lib/auth-utils';
import { calculateEmissions, LogEntry } from '@/lib/compliance-utils';
import { entriesCollectionRef, projectDocRef } from '@/lib/firestore/paths';

interface EmissionsResult {
  hourlyEmissions: Array<{ hour: number; emissions: number }>;
  totalEmissions: number;
  averageEmissions: number;
  peakEmissions: number;
  peakHour: number;
  calculatedAt: Date;
  molecularWeight: number;
  permitLimit?: number;
  withinLimit?: boolean;
}

export async function calcJobEmissions(
  projectId: string,
  logId: string,
  date: Date,
  molecularWeight: number = 34.08 // Default to H2S
): Promise<EmissionsResult> {
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
    
    if (entries.length === 0) {
      return {
        hourlyEmissions: [],
        totalEmissions: 0,
        averageEmissions: 0,
        peakEmissions: 0,
        peakHour: 0,
        calculatedAt: new Date(),
        molecularWeight,
      };
    }
    
    // Calculate emissions
    const emissionsData = calculateEmissions(entries, molecularWeight);
    
    // Get permit limit if available
    const projectDoc = await projectDocRef(projectId).get();
    const permitLimit = projectDoc.data()?.permit?.emissionsMaxLbHr;
    
    const result: EmissionsResult = {
      ...emissionsData,
      calculatedAt: new Date(),
      molecularWeight,
      permitLimit,
      withinLimit: permitLimit ? emissionsData.peakEmissions <= permitLimit : undefined,
    };
    
    // Store calculation result for future reference
    await db
      .collection('projects')
      .doc(projectId)
      .collection('logs')
      .doc(logId)
      .collection('calculations')
      .doc(`emissions-${date.toISOString().split('T')[0]}`)
      .set({
        ...result,
        calculatedBy: session.uid,
      });
    
    return result;
  } catch (error) {
    console.error('Error calculating job emissions:', error);
    throw new Error('Failed to calculate job emissions');
  }
}

export async function getStoredEmissions(
  projectId: string,
  logId: string,
  date: Date
): Promise<EmissionsResult | null> {
  const cookieStore = await cookies();
  const session = await validateAdminSession(cookieStore);
  
  if (!session || session.role !== 'admin') {
    throw new Error('Unauthorized: Admin access required');
  }

  const db = getAdminFirestore();
  
  try {
    const calculationDoc = await db
      .collection('projects')
      .doc(projectId)
      .collection('logs')
      .doc(logId)
      .collection('calculations')
      .doc(`emissions-${date.toISOString().split('T')[0]}`)
      .get();
    
    if (!calculationDoc.exists) {
      return null;
    }
    
    const data = calculationDoc.data()!;
    return {
      ...data,
      calculatedAt: data.calculatedAt?.toDate(),
    } as EmissionsResult;
  } catch (error) {
    console.error('Error getting stored emissions:', error);
    return null;
  }
}

export async function compareWithPermitLimits(
  projectId: string,
  emissionsData: EmissionsResult
): Promise<{
  withinLimit: boolean;
  exceedanceHours: number[];
  maxExceedance: number;
  permitLimit: number;
}> {
  const cookieStore = await cookies();
  const session = await validateAdminSession(cookieStore);
  
  if (!session || session.role !== 'admin') {
    throw new Error('Unauthorized: Admin access required');
  }

  const db = getAdminFirestore();
  
  try {
    // Get permit data
    const permitDoc = await db.collection('permits').doc(`permit-${projectId}`).get();
    
    if (!permitDoc.exists) {
      throw new Error('Permit not found');
    }
    
    const permitData = permitDoc.data()!;
    const permitLimit = permitData.keyLimits?.emissionsMaxLbHr;
    
    if (!permitLimit) {
      throw new Error('Emissions limit not found in permit');
    }
    
    // Check each hour against limit
    const exceedanceHours: number[] = [];
    let maxExceedance = 0;
    
    emissionsData.hourlyEmissions.forEach(({ hour, emissions }) => {
      if (emissions > permitLimit) {
        exceedanceHours.push(hour);
        const exceedance = emissions - permitLimit;
        if (exceedance > maxExceedance) {
          maxExceedance = exceedance;
        }
      }
    });
    
    return {
      withinLimit: exceedanceHours.length === 0,
      exceedanceHours,
      maxExceedance,
      permitLimit,
    };
  } catch (error) {
    console.error('Error comparing with permit limits:', error);
    throw new Error('Failed to compare with permit limits');
  }
}