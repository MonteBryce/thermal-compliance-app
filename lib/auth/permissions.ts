import { User } from 'firebase/auth';
import { Role, Permission } from '@/lib/types/permissions';
import { getRolePermissions, hasPermission, hasAnyPermission, hasAllPermissions } from '@/lib/config/roles';

export interface PermissionContext {
  user: User | null;
  roles: Role[];
  permissions: Permission[];
  isLoading: boolean;
}

export function getUserRoles(user: User | null): Role[] {
  if (!user) return [];
  
  // Check custom claims first
  const customClaims = (user as any).customClaims;
  if (customClaims?.roles && Array.isArray(customClaims.roles)) {
    return customClaims.roles.filter((role: string) => Object.values(Role).includes(role as Role));
  }
  
  if (customClaims?.role && Object.values(Role).includes(customClaims.role as Role)) {
    return [customClaims.role as Role];
  }
  
  // Fallback: Check environment variables for admin emails
  if (user.email) {
    const adminEmails = process.env.NEXT_PUBLIC_ADMIN_EMAILS?.split(',').map(e => e.trim()) || [];
    const superAdminEmails = process.env.NEXT_PUBLIC_SUPER_ADMIN_EMAILS?.split(',').map(e => e.trim()) || [];
    const managerEmails = process.env.NEXT_PUBLIC_MANAGER_EMAILS?.split(',').map(e => e.trim()) || [];
    
    if (superAdminEmails.includes(user.email)) {
      return [Role.SUPER_ADMIN];
    }
    
    if (adminEmails.includes(user.email)) {
      return [Role.ADMIN];
    }
    
    if (managerEmails.includes(user.email)) {
      return [Role.MANAGER];
    }
    
    // Check domain-based permissions
    const adminDomains = process.env.NEXT_PUBLIC_ADMIN_DOMAINS?.split(',').map(d => d.trim()) || [];
    for (const domain of adminDomains) {
      if (user.email.endsWith(domain)) {
        return [Role.ADMIN];
      }
    }
  }
  
  // Default role for authenticated users
  return [Role.VIEWER];
}

export function getUserPermissions(user: User | null): Permission[] {
  const roles = getUserRoles(user);
  const allPermissions: Permission[] = [];
  
  for (const role of roles) {
    allPermissions.push(...getRolePermissions(role));
  }
  
  // Remove duplicates
  return Array.from(new Set(allPermissions));
}

export function canPerform(user: User | null, permission: Permission): boolean {
  const roles = getUserRoles(user);
  return hasPermission(roles, permission);
}

export function canPerformAny(user: User | null, permissions: Permission[]): boolean {
  const roles = getUserRoles(user);
  return hasAnyPermission(roles, permissions);
}

export function canPerformAll(user: User | null, permissions: Permission[]): boolean {
  const roles = getUserRoles(user);
  return hasAllPermissions(roles, permissions);
}

export function isAdmin(user: User | null): boolean {
  const roles = getUserRoles(user);
  return roles.includes(Role.ADMIN) || roles.includes(Role.SUPER_ADMIN);
}

export function isSuperAdmin(user: User | null): boolean {
  const roles = getUserRoles(user);
  return roles.includes(Role.SUPER_ADMIN);
}

export function isManager(user: User | null): boolean {
  const roles = getUserRoles(user);
  return roles.includes(Role.MANAGER) || isAdmin(user);
}

export function canAccessAdminPanel(user: User | null): boolean {
  return canPerformAny(user, [
    Permission.TEMPLATE_VIEW,
    Permission.PROJECT_VIEW,
    Permission.COMPLIANCE_VIEW,
    Permission.ANALYTICS_VIEW,
    Permission.USER_VIEW
  ]);
}

// Template permissions
export function canCreateTemplates(user: User | null): boolean {
  return canPerform(user, Permission.TEMPLATE_CREATE);
}

export function canEditTemplates(user: User | null): boolean {
  return canPerform(user, Permission.TEMPLATE_EDIT);
}

export function canDeleteTemplates(user: User | null): boolean {
  return canPerform(user, Permission.TEMPLATE_DELETE);
}

export function canPublishTemplates(user: User | null): boolean {
  return canPerform(user, Permission.TEMPLATE_PUBLISH);
}

export function canViewTemplates(user: User | null): boolean {
  return canPerform(user, Permission.TEMPLATE_VIEW);
}

// Project permissions
export function canCreateProjects(user: User | null): boolean {
  return canPerform(user, Permission.PROJECT_CREATE);
}

export function canEditProjects(user: User | null): boolean {
  return canPerform(user, Permission.PROJECT_EDIT);
}

export function canDeleteProjects(user: User | null): boolean {
  return canPerform(user, Permission.PROJECT_DELETE);
}

export function canViewProjects(user: User | null): boolean {
  return canPerform(user, Permission.PROJECT_VIEW);
}

export function canAssignOperators(user: User | null): boolean {
  return canPerform(user, Permission.PROJECT_ASSIGN_OPERATORS);
}

// Compliance permissions
export function canViewCompliance(user: User | null): boolean {
  return canPerform(user, Permission.COMPLIANCE_VIEW);
}

export function canEditCompliance(user: User | null): boolean {
  return canPerform(user, Permission.COMPLIANCE_EDIT);
}

// Analytics permissions
export function canViewAnalytics(user: User | null): boolean {
  return canPerform(user, Permission.ANALYTICS_VIEW);
}

export function canExportAnalytics(user: User | null): boolean {
  return canPerform(user, Permission.ANALYTICS_EXPORT);
}

// User management permissions
export function canCreateUsers(user: User | null): boolean {
  return canPerform(user, Permission.USER_CREATE);
}

export function canEditUsers(user: User | null): boolean {
  return canPerform(user, Permission.USER_EDIT);
}

export function canDeleteUsers(user: User | null): boolean {
  return canPerform(user, Permission.USER_DELETE);
}

export function canViewUsers(user: User | null): boolean {
  return canPerform(user, Permission.USER_VIEW);
}

export function canAssignRoles(user: User | null): boolean {
  return canPerform(user, Permission.USER_ASSIGN_ROLES);
}

// System permissions
export function canAccessSystemSettings(user: User | null): boolean {
  return canPerform(user, Permission.SYSTEM_SETTINGS);
}

export function canAccessSystemLogs(user: User | null): boolean {
  return canPerform(user, Permission.SYSTEM_LOGS);
}

// Data permissions
export function canExportData(user: User | null): boolean {
  return canPerform(user, Permission.DATA_EXPORT);
}

export function canImportData(user: User | null): boolean {
  return canPerform(user, Permission.DATA_IMPORT);
}

export function canDeleteData(user: User | null): boolean {
  return canPerform(user, Permission.DATA_DELETE);
}