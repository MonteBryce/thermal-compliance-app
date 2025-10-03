import { redirect } from 'next/navigation';
import { getCurrentUser } from '@/lib/auth';

/**
 * Admin role check for server components
 */
export async function requireAdmin() {
  const user = await getCurrentUser();
  
  if (!user) {
    redirect('/login');
  }
  
  // Check if user has admin role
  // This assumes you have a custom claim or role system
  const isAdmin = user.customClaims?.role === 'admin' || 
                  user.email?.endsWith('@admin.com'); // Fallback for testing
  
  if (!isAdmin) {
    redirect('/unauthorized');
  }
  
  return user;
}

/**
 * Client-side admin check hook
 */
export function useAdminGuard() {
  // This would integrate with your auth context
  // Implementation depends on your auth setup
  return {
    isAdmin: true, // Placeholder
    isLoading: false,
    user: null,
  };
}

/**
 * Check if user has admin permissions
 */
export function hasAdminPermissions(user: any): boolean {
  if (!user) return false;
  
  return user.customClaims?.role === 'admin' || 
         user.email?.endsWith('@admin.com'); // Fallback for testing
}

/**
 * Check if user can edit templates
 */
export function canEditTemplates(user: any): boolean {
  return hasAdminPermissions(user);
}

/**
 * Check if user can publish templates
 */
export function canPublishTemplates(user: any): boolean {
  return hasAdminPermissions(user);
}

/**
 * Check if user can assign templates to projects
 */
export function canAssignTemplates(user: any): boolean {
  return hasAdminPermissions(user);
}

/**
 * Check if user can view template analytics
 */
export function canViewAnalytics(user: any): boolean {
  return hasAdminPermissions(user);
}