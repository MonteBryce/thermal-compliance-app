'use client';

import { useAuth } from '@/lib/contexts/AuthContext';
import { Permission, Role } from '@/lib/types/permissions';

interface PermissionGuardProps {
  children: React.ReactNode;
  permissions?: Permission | Permission[];
  roles?: Role | Role[];
  requireAll?: boolean; // true = AND logic, false = OR logic
  fallback?: React.ReactNode;
}

export function PermissionGuard({
  children,
  permissions,
  roles,
  requireAll = false,
  fallback = null
}: PermissionGuardProps) {
  const { canAccess, hasRole, isLoading } = useAuth();

  // Don't render anything while loading
  if (isLoading) {
    return null;
  }

  let hasPermissions = true;
  let hasRoles = true;

  // Check permissions
  if (permissions) {
    const permissionArray = Array.isArray(permissions) ? permissions : [permissions];
    
    if (requireAll) {
      hasPermissions = permissionArray.every(permission => canAccess(permission));
    } else {
      hasPermissions = permissionArray.some(permission => canAccess(permission));
    }
  }

  // Check roles
  if (roles) {
    const roleArray = Array.isArray(roles) ? roles : [roles];
    
    if (requireAll) {
      hasRoles = roleArray.every(role => hasRole(role));
    } else {
      hasRoles = roleArray.some(role => hasRole(role));
    }
  }

  // Combine permission and role checks
  const canRender = requireAll ? (hasPermissions && hasRoles) : (hasPermissions || hasRoles);

  return canRender ? <>{children}</> : <>{fallback}</>;
}

// Convenient wrapper components
interface PermissionWrapperProps {
  children: React.ReactNode;
  fallback?: React.ReactNode;
}

export function AdminOnly({ children, fallback }: PermissionWrapperProps) {
  return (
    <PermissionGuard roles={[Role.ADMIN, Role.SUPER_ADMIN]} fallback={fallback}>
      {children}
    </PermissionGuard>
  );
}

export function SuperAdminOnly({ children, fallback }: PermissionWrapperProps) {
  return (
    <PermissionGuard roles={Role.SUPER_ADMIN} fallback={fallback}>
      {children}
    </PermissionGuard>
  );
}

export function ManagerOnly({ children, fallback }: PermissionWrapperProps) {
  return (
    <PermissionGuard roles={[Role.MANAGER, Role.ADMIN, Role.SUPER_ADMIN]} fallback={fallback}>
      {children}
    </PermissionGuard>
  );
}

export function TemplateEditor({ children, fallback }: PermissionWrapperProps) {
  return (
    <PermissionGuard permissions={Permission.TEMPLATE_EDIT} fallback={fallback}>
      {children}
    </PermissionGuard>
  );
}

export function ProjectManager({ children, fallback }: PermissionWrapperProps) {
  return (
    <PermissionGuard permissions={Permission.PROJECT_CREATE} fallback={fallback}>
      {children}
    </PermissionGuard>
  );
}

export function DataExporter({ children, fallback }: PermissionWrapperProps) {
  return (
    <PermissionGuard permissions={Permission.DATA_EXPORT} fallback={fallback}>
      {children}
    </PermissionGuard>
  );
}