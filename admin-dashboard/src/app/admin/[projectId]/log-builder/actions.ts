'use server';

import { z } from 'zod';
import { 
  doc, 
  getDoc, 
  writeBatch, 
  serverTimestamp,
  collection,
  addDoc
} from 'firebase/firestore';
import { db } from '@/lib/firebase';
import { requireAdmin } from '@/lib/auth/rbac';
import { revalidatePath } from 'next/cache';

/**
 * Server action to assign a log template to a project
 */
export async function assignLogTemplate(
  projectId: string,
  formData: FormData
) {
  try {
    // Verify admin access
    const user = await requireAdmin();
    
    // Parse and validate input
    const data = {
      projectId,
      logType: formData.get('logType') as string,
      templateVersion: formData.get('templateVersion') as string,
      reason: formData.get('reason') as string | undefined,
      includeFields: formData.get('includeFields') === 'true',
    };
    
    // Basic validation
    if (!data.logType) {
      throw new Error('Template type is required');
    }
    
    // Check if project exists (optional check)
    // In our simplified version, we don't strictly require project to exist
    
    // Get current metadata if it exists
    const metadataRef = doc(db, 'projects', projectId, 'metadata', 'current');
    const metadataSnap = await getDoc(metadataRef);
    const currentMetadata = metadataSnap.exists() ? metadataSnap.data() : null;
    
    // Check if changing existing template
    const isChange = currentMetadata && currentMetadata.logType !== data.logType;
    if (isChange && !data.reason) {
      throw new Error('Reason is required when changing existing template');
    }
    
    // Prepare batch write
    const batch = writeBatch(db);
    
    // Update metadata
    const metadataUpdate = {
      logType: data.logType,
      templateId: data.logType, // Keep them the same for now
      templateVersion: data.templateVersion || '1',
      updatedBy: user.uid,
      updatedAt: serverTimestamp(),
    };
    
    batch.set(metadataRef, metadataUpdate, { merge: true });
    
    // Add history record if this is a change
    if (isChange || data.reason) {
      const historyRef = doc(collection(db, 'projects', projectId, 'logTypeHistory'));
      const historyRecord = {
        oldLogType: currentMetadata?.logType || null,
        newLogType: data.logType,
        oldVersion: currentMetadata?.templateVersion || null,
        newVersion: data.templateVersion || '1',
        reason: data.reason || 'Initial template assignment',
        changedBy: user.uid,
        changedAt: serverTimestamp(),
      };
      
      batch.set(historyRef, historyRecord);
    }
    
    // Commit the batch
    await batch.commit();
    
    // Revalidate the page
    revalidatePath(`/admin/${projectId}/log-builder`);
    
    return {
      success: true,
      message: isChange 
        ? `Template changed to ${data.logType}`
        : `Template ${data.logType} assigned successfully`,
    };
    
  } catch (error) {
    console.error('Error assigning template:', error);
    
    if (error instanceof z.ZodError) {
      return {
        success: false,
        message: 'Invalid input: ' + error.errors.map(e => e.message).join(', '),
      };
    }
    
    return {
      success: false,
      message: error instanceof Error ? error.message : 'Failed to assign template',
    };
  }
}

/**
 * Server action to get project metadata
 */
export async function getProjectMetadata(projectId: string) {
  try {
    // Verify admin access
    await requireAdmin();
    
    // Get metadata
    const metadataRef = doc(db, 'projects', projectId, 'metadata', 'current');
    const metadataSnap = await getDoc(metadataRef);
    
    if (!metadataSnap.exists()) {
      return null;
    }
    
    return metadataSnap.data();
    
  } catch (error) {
    console.error('Error fetching metadata:', error);
    return null;
  }
}

/**
 * Server action to get template history
 */
export async function getTemplateHistory(projectId: string) {
  try {
    // Verify admin access
    await requireAdmin();
    
    // Query history collection
    const historyRef = collection(db, 'projects', projectId, 'logTypeHistory');
    const { getDocs, orderBy, query, limit } = await import('firebase/firestore');
    
    const q = query(
      historyRef,
      orderBy('changedAt', 'desc'),
      limit(10)
    );
    
    const snapshot = await getDocs(q);
    
    return snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    }));
    
  } catch (error) {
    console.error('Error fetching history:', error);
    return [];
  }
}