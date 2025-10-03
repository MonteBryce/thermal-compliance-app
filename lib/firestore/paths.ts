import { collection, doc, CollectionReference, DocumentReference } from 'firebase/firestore';
import { db } from '@/lib/firebase';

/**
 * Path helper service for consistent Firestore path construction
 * 
 * Canonical path structure:
 * projects/{projectId}/logs/{logId}/entries/{hour}
 * where logId = YYYYMMDD string; hour = two-digit "00".."23"
 */

/**
 * Get a reference to a log document
 * 
 * @param projectId - Project identifier
 * @param yyyymmdd - Date in YYYYMMDD format (e.g., "20241201")
 * @returns DocumentReference to projects/{projectId}/logs/{yyyymmdd}
 */
export function logDocRef(projectId: string, yyyymmdd: string): DocumentReference {
  return doc(db, 'projects', projectId, 'logs', yyyymmdd);
}

/**
 * Get a reference to an entry document
 * 
 * @param projectId - Project identifier
 * @param yyyymmdd - Date in YYYYMMDD format (e.g., "20241201")
 * @param hour2 - Two-digit hour string (e.g., "00", "23")
 * @returns DocumentReference to projects/{projectId}/logs/{yyyymmdd}/entries/{hour2}
 */
export function entryDocRef(projectId: string, yyyymmdd: string, hour2: string): DocumentReference {
  if (!isValidHourId(hour2)) {
    throw new Error(`Invalid hour format. Expected "00" to "23", got: ${hour2}`);
  }
  
  return doc(db, 'projects', projectId, 'logs', yyyymmdd, 'entries', hour2);
}

/**
 * Get a reference to the entries collection for a log
 * 
 * @param projectId - Project identifier
 * @param yyyymmdd - Date in YYYYMMDD format (e.g., "20241201")
 * @returns CollectionReference to projects/{projectId}/logs/{yyyymmdd}/entries
 */
export function entriesCollectionRef(projectId: string, yyyymmdd: string): CollectionReference {
  return collection(db, 'projects', projectId, 'logs', yyyymmdd, 'entries');
}

/**
 * Get a reference to the logs collection for a project
 * 
 * @param projectId - Project identifier
 * @returns CollectionReference to projects/{projectId}/logs
 */
export function logsCollectionRef(projectId: string): CollectionReference {
  return collection(db, 'projects', projectId, 'logs');
}

/**
 * Get a reference to a project document
 * 
 * @param projectId - Project identifier
 * @returns DocumentReference to projects/{projectId}
 */
export function projectDocRef(projectId: string): DocumentReference {
  return doc(db, 'projects', projectId);
}

/**
 * Validate if a string is a valid hour identifier
 * 
 * @param h - Hour string to validate
 * @returns true if the string is a valid two-digit hour (00-23), false otherwise
 */
export function isValidHourId(h: string): boolean {
  if (h.length !== 2) return false;
  
  try {
    const hour = parseInt(h, 10);
    return hour >= 0 && hour <= 23;
  } catch (e) {
    return false;
  }
}

/**
 * Convert Date to YYYYMMDD format string
 * 
 * @param date - Date to convert
 * @returns String in YYYYMMDD format
 */
export function dateToYyyyMmDd(date: Date): string {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  return `${year}${month}${day}`;
}

/**
 * Convert hour integer to two-digit string
 * 
 * @param hour - Hour as integer (0-23)
 * @returns Two-digit string (e.g., "00", "23")
 */
export function hourToHour2(hour: number): string {
  if (hour < 0 || hour > 23) {
    throw new Error(`Hour must be between 0 and 23, got: ${hour}`);
  }
  return String(hour).padStart(2, '0');
}

/**
 * Convert two-digit hour string to integer
 * 
 * @param hour2 - Two-digit hour string (e.g., "00", "23")
 * @returns Hour as integer (0-23)
 */
export function hour2ToHour(hour2: string): number {
  if (!isValidHourId(hour2)) {
    throw new Error(`Invalid hour format. Expected "00" to "23", got: ${hour2}`);
  }
  return parseInt(hour2, 10);
}

/**
 * Get all valid hour identifiers
 * 
 * @returns Array of all valid hour strings from "00" to "23"
 */
export function getAllHourIds(): string[] {
  return Array.from({ length: 24 }, (_, i) => hourToHour2(i));
}

/**
 * Check if a string is a valid YYYYMMDD format
 * 
 * @param yyyymmdd - String to validate
 * @returns true if valid YYYYMMDD format, false otherwise
 */
export function isValidYyyyMmDd(yyyymmdd: string): boolean {
  if (yyyymmdd.length !== 8) return false;
  
  try {
    const year = parseInt(yyyymmdd.substring(0, 4), 10);
    const month = parseInt(yyyymmdd.substring(4, 6), 10);
    const day = parseInt(yyyymmdd.substring(6, 8), 10);
    
    if (year < 1900 || year > 2100) return false;
    if (month < 1 || month > 12) return false;
    if (day < 1 || day > 31) return false;
    
    // Basic validation - could be enhanced with actual calendar validation
    return true;
  } catch (e) {
    return false;
  }
}

/**
 * Parse YYYYMMDD string to Date object
 * 
 * @param yyyymmdd - String in YYYYMMDD format
 * @returns Date object
 */
export function yyyyMmDdToDate(yyyymmdd: string): Date {
  if (!isValidYyyyMmDd(yyyymmdd)) {
    throw new Error(`Invalid YYYYMMDD format: ${yyyymmdd}`);
  }
  
  const year = parseInt(yyyymmdd.substring(0, 4), 10);
  const month = parseInt(yyyymmdd.substring(4, 6), 10) - 1; // Month is 0-indexed
  const day = parseInt(yyyymmdd.substring(6, 8), 10);
  
  return new Date(year, month, day);
}
