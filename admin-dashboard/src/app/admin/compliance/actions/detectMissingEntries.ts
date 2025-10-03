'use server';

import { getAdminFirestore } from '@/lib/firebase-admin';
import { cookies } from 'next/headers';
import { validateAdminSession } from '@/lib/auth-utils';
import { findMissingEntries, LogEntry } from '@/lib/compliance-utils';
import { entriesCollectionRef, logsCollectionRef, projectDocRef } from '@/lib/firestore/paths';

export interface MissingEntry {
  hour: number;
  timeString: string;
  isRequired: boolean;
  reason?: string;
}

export async function detectMissingEntries(
  projectId: string,
  logId: string,
  date: Date = new Date()
): Promise<{
  missingEntries: MissingEntry[];
  totalExpected: number;
  totalFound: number;
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
      .get();
    
    const entries: LogEntry[] = entriesSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    } as LogEntry));
    
    // Find missing hours
    const missingHours = findMissingEntries(entries, date);
    
    // Check for planned downtime or exceptions
    const exceptionsDoc = await db
      .collection('projects')
      .doc(projectId)
      .collection('logs')
      .doc(logId)
      .collection('metadata')
      .doc('exceptions')
      .get();
    
    const exceptions = exceptionsDoc.exists ? exceptionsDoc.data()?.exceptions || {} : {};
    
    const missingEntries: MissingEntry[] = missingHours.map(hour => ({
      hour,
      timeString: `${hour.toString().padStart(2, '0')}:00`,
      isRequired: !exceptions[hour],
      reason: exceptions[hour]?.reason,
    }));
    
    return {
      missingEntries,
      totalExpected: 24,
      totalFound: entries.length,
    };
  } catch (error) {
    console.error('Error detecting missing entries:', error);
    throw new Error('Failed to detect missing entries');
  }
}

export async function markEntryNotRequired(
  projectId: string,
  logId: string,
  hour: number,
  reason: string
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
      .collection('logs')
      .doc(logId)
      .collection('metadata')
      .doc('exceptions')
      .set(
        {
          exceptions: {
            [hour]: {
              reason,
              markedBy: session.uid,
              markedAt: new Date(),
            },
          },
        },
        { merge: true }
      );
  } catch (error) {
    console.error('Error marking entry as not required:', error);
    throw new Error('Failed to update entry requirement');
  }
}