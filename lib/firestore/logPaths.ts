import { 
  Firestore, 
  DocumentReference, 
  CollectionReference,
  collection,
  doc,
  query,
  where,
  orderBy,
  QueryConstraint,
  Timestamp
} from 'firebase/firestore';

/**
 * Path helpers for consistent Firestore access patterns
 * Used by both mobile (Flutter) and admin (Next.js) apps
 */

// Valid hour IDs from "00" to "23"
export const VALID_HOUR_IDS = Array.from({ length: 24 }, (_, i) => 
  i.toString().padStart(2, '0')
);

/**
 * Validates if a string is a valid hour ID (00-23)
 */
export function isValidHourId(hourId: string): boolean {
  return VALID_HOUR_IDS.includes(hourId);
}

/**
 * Formats a date to YYYYMMDD string
 */
export function formatDateToYYYYMMDD(date: Date): string {
  const year = date.getFullYear();
  const month = (date.getMonth() + 1).toString().padStart(2, '0');
  const day = date.getDate().toString().padStart(2, '0');
  return `${year}${month}${day}`;
}

/**
 * Parses YYYYMMDD string to Date
 */
export function parseYYYYMMDDToDate(yyyymmdd: string): Date | null {
  if (!/^\d{8}$/.test(yyyymmdd)) return null;
  
  const year = parseInt(yyyymmdd.substring(0, 4));
  const month = parseInt(yyyymmdd.substring(4, 6)) - 1;
  const day = parseInt(yyyymmdd.substring(6, 8));
  
  const date = new Date(year, month, day);
  
  // Validate the date is real (e.g., not Feb 31)
  if (date.getFullYear() !== year || 
      date.getMonth() !== month || 
      date.getDate() !== day) {
    return null;
  }
  
  return date;
}

/**
 * Gets a reference to a daily log document
 */
export function logDocRef(
  db: Firestore, 
  projectId: string, 
  yyyymmdd: string
): DocumentReference {
  return doc(db, 'projects', projectId, 'logs', yyyymmdd);
}

/**
 * Gets a reference to an hourly entry document
 */
export function entryDocRef(
  db: Firestore,
  projectId: string,
  yyyymmdd: string,
  hourId: string
): DocumentReference {
  if (!isValidHourId(hourId)) {
    throw new Error(`Invalid hourId: ${hourId}. Must be 00-23.`);
  }
  return doc(db, 'projects', projectId, 'logs', yyyymmdd, 'entries', hourId);
}

/**
 * Gets a reference to the entries collection for a specific day
 */
export function entriesCollectionRef(
  db: Firestore,
  projectId: string,
  yyyymmdd: string
): CollectionReference {
  return collection(db, 'projects', projectId, 'logs', yyyymmdd, 'entries');
}

/**
 * Gets a reference to the logs collection for a project
 */
export function logsCollectionRef(
  db: Firestore,
  projectId: string
): CollectionReference {
  return collection(db, 'projects', projectId, 'logs');
}

/**
 * Gets a reference to the exports collection for a project
 */
export function exportsCollectionRef(
  db: Firestore,
  projectId: string
): CollectionReference {
  return collection(db, 'projects', projectId, 'exports');
}

/**
 * Creates a query for fetching logs within a date range
 */
export function createDateRangeQuery(
  db: Firestore,
  projectId: string,
  startDate: Date,
  endDate: Date
): { ref: CollectionReference; constraints: QueryConstraint[] } {
  const startYYYYMMDD = formatDateToYYYYMMDD(startDate);
  const endYYYYMMDD = formatDateToYYYYMMDD(endDate);
  
  return {
    ref: logsCollectionRef(db, projectId),
    constraints: [
      where('__name__', '>=', startYYYYMMDD),
      where('__name__', '<=', endYYYYMMDD),
      orderBy('__name__')
    ]
  };
}

/**
 * Generates an array of YYYYMMDD strings for a date range
 */
export function generateDateRange(startDate: Date, endDate: Date): string[] {
  const dates: string[] = [];
  const currentDate = new Date(startDate);
  
  while (currentDate <= endDate) {
    dates.push(formatDateToYYYYMMDD(currentDate));
    currentDate.setDate(currentDate.getDate() + 1);
  }
  
  return dates;
}

/**
 * Calculates the number of days between two dates
 */
export function daysBetween(startDate: Date, endDate: Date): number {
  const msPerDay = 24 * 60 * 60 * 1000;
  return Math.floor((endDate.getTime() - startDate.getTime()) / msPerDay) + 1;
}

/**
 * Gets the project document reference
 */
export function projectDocRef(
  db: Firestore,
  projectId: string
): DocumentReference {
  return doc(db, 'projects', projectId);
}

/**
 * Validates a date range for export
 */
export function validateDateRange(
  startDate: Date,
  endDate: Date,
  maxDays: number = 31
): { valid: boolean; error?: string } {
  if (startDate > endDate) {
    return { valid: false, error: 'Start date must be before end date' };
  }
  
  const days = daysBetween(startDate, endDate);
  if (days > maxDays) {
    return { valid: false, error: `Date range cannot exceed ${maxDays} days` };
  }
  
  // Don't allow future dates
  const today = new Date();
  today.setHours(23, 59, 59, 999);
  if (endDate > today) {
    return { valid: false, error: 'Cannot export future dates' };
  }
  
  return { valid: true };
}

/**
 * Helper to create a Firestore timestamp
 */
export function createTimestamp(date: Date = new Date()): Timestamp {
  return Timestamp.fromDate(date);
}

/**
 * Helper to convert Firestore timestamp to Date
 */
export function timestampToDate(timestamp: Timestamp): Date {
  return timestamp.toDate();
}