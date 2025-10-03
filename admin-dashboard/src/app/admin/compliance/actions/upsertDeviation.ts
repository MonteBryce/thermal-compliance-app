'use server';

import { getAdminFirestore } from '@/lib/firebase-admin';
import { cookies } from 'next/headers';
import { validateAdminSession } from '@/lib/auth-utils';
import { Deviation } from '@/lib/compliance-utils';
import { projectDocRef } from '@/lib/firestore/paths';

export async function createDeviation(
  projectId: string,
  logId: string,
  deviationData: {
    facility: string;
    dateTime: Date;
    type: Deviation['type'];
    description: string;
    cause?: string;
    assignedTo?: string;
    evidenceUrls?: string[];
  }
): Promise<string> {
  const cookieStore = await cookies();
  const session = await validateAdminSession(cookieStore);
  
  if (!session || session.role !== 'admin') {
    throw new Error('Unauthorized: Admin access required');
  }

  const db = getAdminFirestore();
  
  try {
    const deviationRef = db
      .collection('projects')
      .doc(projectId)
      .collection('deviations')
      .doc();
    
    const deviation: Omit<Deviation, 'id'> = {
      projectId,
      logId,
      facility: deviationData.facility,
      dateTime: deviationData.dateTime,
      type: deviationData.type,
      description: deviationData.description,
      cause: deviationData.cause,
      status: 'open',
      assignedTo: deviationData.assignedTo,
      evidenceUrls: deviationData.evidenceUrls || [],
      createdBy: session.uid,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    
    await deviationRef.set(deviation);
    
    return deviationRef.id;
  } catch (error) {
    console.error('Error creating deviation:', error);
    throw new Error('Failed to create deviation');
  }
}

export async function updateDeviation(
  projectId: string,
  deviationId: string,
  updates: {
    status?: Deviation['status'];
    cause?: string;
    assignedTo?: string;
    evidenceUrls?: string[];
    description?: string;
  }
): Promise<void> {
  const cookieStore = await cookies();
  const session = await validateAdminSession(cookieStore);
  
  if (!session || session.role !== 'admin') {
    throw new Error('Unauthorized: Admin access required');
  }

  const db = getAdminFirestore();
  
  try {
    const updateData = {
      ...updates,
      updatedAt: new Date(),
      updatedBy: session.uid,
    };
    
    // Remove undefined values
    Object.keys(updateData).forEach(key => {
      if (updateData[key as keyof typeof updateData] === undefined) {
        delete updateData[key as keyof typeof updateData];
      }
    });
    
    await db
      .collection('projects')
      .doc(projectId)
      .collection('deviations')
      .doc(deviationId)
      .update(updateData);
  } catch (error) {
    console.error('Error updating deviation:', error);
    throw new Error('Failed to update deviation');
  }
}

export async function closeDeviation(
  projectId: string,
  deviationId: string,
  resolution?: string
): Promise<void> {
  const cookieStore = await cookies();
  const session = await validateAdminSession(cookieStore);
  
  if (!session || session.role !== 'admin') {
    throw new Error('Unauthorized: Admin access required');
  }

  const db = getAdminFirestore();
  
  try {
    const updateData: any = {
      status: 'closed',
      closedBy: session.uid,
      closedAt: new Date(),
      updatedAt: new Date(),
    };
    
    if (resolution) {
      updateData.resolution = resolution;
    }
    
    await db
      .collection('projects')
      .doc(projectId)
      .collection('deviations')
      .doc(deviationId)
      .update(updateData);
  } catch (error) {
    console.error('Error closing deviation:', error);
    throw new Error('Failed to close deviation');
  }
}

export async function addEvidenceToDeviation(
  projectId: string,
  deviationId: string,
  evidenceUrl: string
): Promise<void> {
  const cookieStore = await cookies();
  const session = await validateAdminSession(cookieStore);
  
  if (!session || session.role !== 'admin') {
    throw new Error('Unauthorized: Admin access required');
  }

  const db = getAdminFirestore();
  
  try {
    const deviationRef = db
      .collection('projects')
      .doc(projectId)
      .collection('deviations')
      .doc(deviationId);
    
    const deviationDoc = await deviationRef.get();
    if (!deviationDoc.exists) {
      throw new Error('Deviation not found');
    }
    
    const currentData = deviationDoc.data()!;
    const currentUrls = currentData.evidenceUrls || [];
    
    await deviationRef.update({
      evidenceUrls: [...currentUrls, evidenceUrl],
      updatedAt: new Date(),
      updatedBy: session.uid,
    });
  } catch (error) {
    console.error('Error adding evidence to deviation:', error);
    throw new Error('Failed to add evidence to deviation');
  }
}