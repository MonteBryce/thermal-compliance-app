'use server';

import { getAdminFirestore } from '@/lib/firebase-admin';
import { cookies } from 'next/headers';
import { validateAdminSession } from '@/lib/auth-utils';
import { Deviation } from '@/lib/compliance-utils';
import { projectDocRef } from '@/lib/firestore/paths';

export async function listDeviations(
  projectId?: string,
  filters?: {
    status?: 'open' | 'closed';
    type?: string;
    facility?: string;
    startDate?: Date;
    endDate?: Date;
  },
  limit: number = 20,
  startAfter?: string
): Promise<{
  deviations: Deviation[];
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
    let query = db.collectionGroup('deviations')
      .orderBy('createdAt', 'desc')
      .limit(limit + 1);
    
    // Apply filters
    if (projectId) {
      query = query.where('projectId', '==', projectId);
    }
    
    if (filters?.status) {
      query = query.where('status', '==', filters.status);
    }
    
    if (filters?.type) {
      query = query.where('type', '==', filters.type);
    }
    
    if (filters?.facility) {
      query = query.where('facility', '==', filters.facility);
    }
    
    if (filters?.startDate) {
      query = query.where('dateTime', '>=', filters.startDate);
    }
    
    if (filters?.endDate) {
      query = query.where('dateTime', '<=', filters.endDate);
    }
    
    if (startAfter) {
      const startDoc = await db.collectionGroup('deviations').doc(startAfter).get();
      query = query.startAfter(startDoc);
    }
    
    const snapshot = await query.get();
    const docs = snapshot.docs;
    const hasMore = docs.length > limit;
    
    const deviations = docs.slice(0, limit).map(doc => ({
      id: doc.id,
      ...doc.data(),
      dateTime: doc.data().dateTime?.toDate(),
      createdAt: doc.data().createdAt?.toDate(),
      updatedAt: doc.data().updatedAt?.toDate(),
    } as Deviation));
    
    return {
      deviations,
      hasMore,
      lastDoc: hasMore ? docs[limit - 1].id : undefined,
    };
  } catch (error) {
    console.error('Error listing deviations:', error);
    throw new Error('Failed to list deviations');
  }
}