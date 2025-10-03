'use server';

import { getAdminFirestore } from '@/lib/firebase-admin';
import { ActiveJob } from '@/lib/compliance-utils';
import { cookies } from 'next/headers';
import { validateAdminSession } from '@/lib/auth-utils';
import { logsCollectionRef, projectDocRef } from '@/lib/firestore/paths';

export async function fetchActiveJobs(
  limit: number = 10,
  startAfter?: string
): Promise<{
  jobs: ActiveJob[];
  hasMore: boolean;
  lastDoc?: string;
}> {
  const cookieStore = await cookies();
  const session = await validateAdminSession(cookieStore);
  
  if (!session || session.role !== 'admin') {
    throw new Error('Unauthorized: Admin access required');
  }

  const db = getAdminFirestore();
  
  try {
    let query = db.collection('projects')
      .where('status', '==', 'active')
      .orderBy('startDate', 'desc')
      .limit(limit + 1);
    
    if (startAfter) {
      const startDoc = await projectDocRef(startAfter).get();
      query = query.startAfter(startDoc);
    }
    
    const snapshot = await query.get();
    const docs = snapshot.docs;
    const hasMore = docs.length > limit;
    const jobs = docs.slice(0, limit).map(doc => {
      const data = doc.data();
      return {
        id: doc.id,
        projectId: data.projectId,
        facility: data.facility,
        tankId: data.tankId,
        logType: data.logType,
        assignedOperators: data.assignedOperators || [],
        startDate: data.startDate?.toDate(),
        endDate: data.endDate?.toDate(),
        expectedHours: data.expectedHours || 24,
        completedHours: data.completedHours || 0,
        lastEntryTimestamp: data.lastEntryTimestamp?.toDate(),
      } as ActiveJob;
    });
    
    return {
      jobs,
      hasMore,
      lastDoc: hasMore ? docs[limit - 1].id : undefined,
    };
  } catch (error) {
    console.error('Error fetching active jobs:', error);
    throw new Error('Failed to fetch active jobs');
  }
}