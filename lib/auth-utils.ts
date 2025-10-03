import { getAdminAuth } from './firebase-admin';
import { RequestCookies } from 'next/dist/compiled/@edge-runtime/cookies';

export interface AdminSession {
  uid: string;
  email: string;
  role: 'admin' | 'operator' | 'viewer';
}

export async function validateAdminSession(
  cookieStore: RequestCookies
): Promise<AdminSession | null> {
  try {
    const sessionCookie = cookieStore.get('session');
    
    if (!sessionCookie?.value) {
      return null;
    }
    
    const auth = getAdminAuth();
    const decodedClaims = await auth.verifySessionCookie(sessionCookie.value, true);
    
    // Check custom claims for admin role
    if (!decodedClaims.admin && decodedClaims.role !== 'admin') {
      return null;
    }
    
    return {
      uid: decodedClaims.uid,
      email: decodedClaims.email || '',
      role: decodedClaims.role || 'viewer',
    };
  } catch (error) {
    console.error('Session validation error:', error);
    return null;
  }
}