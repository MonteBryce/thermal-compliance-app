'use server';

import { getAdminFirestore } from '@/lib/firebase-admin';
import { cookies } from 'next/headers';
import { validateAdminSession } from '@/lib/auth-utils';

export interface ScheduleItem {
  operatorId: string;
  operatorName: string;
  projectId: string;
  facility: string;
  role: string;
  lastLoggedHour?: number;
  status: 'active' | 'missing';
}

export async function fetchDailySchedule(
  date: Date = new Date()
): Promise<ScheduleItem[]> {
  const cookieStore = await cookies();
  const session = await validateAdminSession(cookieStore);
  
  if (!session || session.role !== 'admin') {
    throw new Error('Unauthorized: Admin access required');
  }

  const db = getAdminFirestore();
  const dateKey = date.toISOString().split('T')[0].replace(/-/g, '');
  
  try {
    // Fetch schedule for the day
    const scheduleDoc = await db
      .collection('schedules')
      .doc('daily')
      .collection(dateKey)
      .doc('assignments')
      .get();
    
    if (!scheduleDoc.exists) {
      return [];
    }
    
    const scheduleData = scheduleDoc.data();
    const items = scheduleData?.items || [];
    
    // Check last logged hour for each operator
    const currentHour = new Date().getHours();
    const enrichedItems = await Promise.all(
      items.map(async (item: any) => {
        // Query last entry for this operator today
        const entriesQuery = await db
          .collectionGroup('entries')
          .where('operatorId', '==', item.operatorId)
          .where('date', '==', dateKey)
          .orderBy('hour', 'desc')
          .limit(1)
          .get();
        
        const lastEntry = entriesQuery.docs[0];
        const lastLoggedHour = lastEntry?.data()?.hour;
        
        // Determine status (missing if no log in last hour during work hours)
        const workHoursStart = 6; // 6 AM
        const workHoursEnd = 18; // 6 PM
        const isWorkHours = currentHour >= workHoursStart && currentHour <= workHoursEnd;
        const status = 
          isWorkHours && (!lastLoggedHour || currentHour - lastLoggedHour > 1)
            ? 'missing'
            : 'active';
        
        return {
          ...item,
          lastLoggedHour,
          status,
        };
      })
    );
    
    return enrichedItems;
  } catch (error) {
    console.error('Error fetching daily schedule:', error);
    throw new Error('Failed to fetch daily schedule');
  }
}