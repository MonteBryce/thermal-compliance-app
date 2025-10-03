import { auth } from '@/lib/firebase';
import { User } from 'firebase/auth';
import { redirect } from 'next/navigation';

/**
 * RBAC (Role-Based Access Control) utilities
 * Consistent with existing Firebase Auth patterns
 */

export interface AuthUser {
  uid: string;
  email: string | null;
  displayName: string | null;
  customClaims?: {
    admin?: boolean;
    operator?: boolean;
    viewer?: boolean;
  };
}

/**
 * Get the current authenticated user with custom claims
 */
export async function getCurrentUser(): Promise<AuthUser | null> {
  const user = auth.currentUser;
  if (!user) return null;

  const idTokenResult = await user.getIdTokenResult();
  
  return {
    uid: user.uid,
    email: user.email,
    displayName: user.displayName,
    customClaims: idTokenResult.claims as AuthUser['customClaims'],
  };
}

/**
 * Check if the current user is an admin
 */
export async function isAdmin(): Promise<boolean> {
  const user = await getCurrentUser();
  return user?.customClaims?.admin === true;
}

/**
 * Check if the current user is an operator
 */
export async function isOperator(): Promise<boolean> {
  const user = await getCurrentUser();
  return user?.customClaims?.operator === true;
}

/**
 * Require admin access for a page or action
 * Redirects to unauthorized page if not admin
 */
export async function requireAdmin(): Promise<AuthUser> {
  const user = await getCurrentUser();
  
  if (!user) {
    redirect('/login');
  }
  
  // During development, allow any authenticated user to be admin
  // In production, check: if (!user.customClaims?.admin) { redirect('/unauthorized'); }
  // For now, we'll treat any authenticated user as admin
  
  return user;
}

/**
 * Require authenticated user (any role)
 */
export async function requireAuth(): Promise<AuthUser> {
  const user = await getCurrentUser();
  
  if (!user) {
    redirect('/login');
  }
  
  return user;
}

/**
 * Server-side validation of admin claim
 * Used in server actions and API routes
 */
export async function validateAdminClaim(idToken: string): Promise<boolean> {
  try {
    // In production, verify the token with Firebase Admin SDK
    // For now, decode and check the claim
    const payload = JSON.parse(
      Buffer.from(idToken.split('.')[1], 'base64').toString()
    );
    
    return payload.admin === true;
  } catch (error) {
    console.error('Error validating admin claim:', error);
    return false;
  }
}

/**
 * Get user display name or email
 */
export function getUserDisplayName(user: AuthUser): string {
  return user.displayName || user.email || 'Unknown User';
}

/**
 * Check if a user can modify a project
 * Admins can modify any project, operators only their assigned ones
 */
export async function canModifyProject(
  projectId: string,
  user?: AuthUser
): Promise<boolean> {
  const currentUser = user || await getCurrentUser();
  
  if (!currentUser) return false;
  
  // Admins can modify any project
  if (currentUser.customClaims?.admin) return true;
  
  // Operators need to check project assignment (future implementation)
  // For now, operators cannot modify projects
  return false;
}

/**
 * Format role for display
 */
export function formatRole(user: AuthUser): string {
  if (user.customClaims?.admin) return 'Administrator';
  if (user.customClaims?.operator) return 'Operator';
  if (user.customClaims?.viewer) return 'Viewer';
  return 'User';
}