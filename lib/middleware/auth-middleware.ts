import { NextRequest, NextResponse } from 'next/server';
import { auth } from '@/lib/firebase-admin';
import { DecodedIdToken } from 'firebase-admin/auth';

export interface AuthenticatedRequest extends NextRequest {
  user?: DecodedIdToken;
}

export async function verifyAuth(request: NextRequest): Promise<DecodedIdToken | null> {
  try {
    const authHeader = request.headers.get('authorization');
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return null;
    }
    
    const token = authHeader.split('Bearer ')[1];
    
    if (!token) {
      return null;
    }
    
    const decodedToken = await auth.verifyIdToken(token);
    return decodedToken;
  } catch (error) {
    console.error('Error verifying auth token:', error);
    return null;
  }
}

export async function requireAuth(request: NextRequest): Promise<DecodedIdToken | NextResponse> {
  const user = await verifyAuth(request);
  
  if (!user) {
    return NextResponse.json(
      { error: 'Unauthorized', message: 'Valid authentication required' },
      { status: 401 }
    );
  }
  
  return user;
}

export async function requireAdmin(request: NextRequest): Promise<DecodedIdToken | NextResponse> {
  const user = await verifyAuth(request);
  
  if (!user) {
    return NextResponse.json(
      { error: 'Unauthorized', message: 'Valid authentication required' },
      { status: 401 }
    );
  }
  
  const customClaims = user.customClaims || {};
  
  if (!customClaims.admin && !customClaims.role?.includes('admin')) {
    return NextResponse.json(
      { error: 'Forbidden', message: 'Admin access required' },
      { status: 403 }
    );
  }
  
  return user;
}

export async function requireRole(request: NextRequest, roles: string[]): Promise<DecodedIdToken | NextResponse> {
  const user = await verifyAuth(request);
  
  if (!user) {
    return NextResponse.json(
      { error: 'Unauthorized', message: 'Valid authentication required' },
      { status: 401 }
    );
  }
  
  const userRole = user.customClaims?.role || user.role || 'operator';
  
  if (!roles.includes(userRole)) {
    return NextResponse.json(
      { error: 'Forbidden', message: `Required role: ${roles.join(' or ')}` },
      { status: 403 }
    );
  }
  
  return user;
}

export function createAuthMiddleware(options?: {
  requireAdmin?: boolean;
  requireRoles?: string[];
  allowAnonymous?: boolean;
}) {
  return async function middleware(request: NextRequest) {
    if (options?.allowAnonymous) {
      return null;
    }
    
    if (options?.requireAdmin) {
      return await requireAdmin(request);
    }
    
    if (options?.requireRoles && options.requireRoles.length > 0) {
      return await requireRole(request, options.requireRoles);
    }
    
    return await requireAuth(request);
  };
}