import { auth } from '@/lib/firebase-admin';
import { headers } from 'next/headers';

export interface AuthContext {
  uid: string;
  email: string | null;
  isAdmin: boolean;
  isOperator: boolean;
}

export async function verifyAuth(): Promise<AuthContext | null> {
  try {
    const headersList = await headers();
    const authorization = headersList.get('authorization');
    
    if (!authorization?.startsWith('Bearer ')) {
      return null;
    }
    
    const idToken = authorization.split('Bearer ')[1];
    const decodedToken = await auth.verifyIdToken(idToken);
    
    return {
      uid: decodedToken.uid,
      email: decodedToken.email || null,
      isAdmin: decodedToken.admin === true,
      isOperator: decodedToken.operator === true
    };
  } catch (error) {
    console.error('Auth verification failed:', error);
    return null;
  }
}

export async function requireAdmin(): Promise<AuthContext> {
  const authContext = await verifyAuth();
  
  if (!authContext) {
    throw new Error('Authentication required');
  }
  
  if (!authContext.isAdmin) {
    throw new Error('Admin access required');
  }
  
  return authContext;
}

export async function requireAuth(): Promise<AuthContext> {
  const authContext = await verifyAuth();
  
  if (!authContext) {
    throw new Error('Authentication required');
  }
  
  return authContext;
}