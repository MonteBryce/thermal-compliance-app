import { Role, Permission, UserRole } from '@/lib/types/permissions';

export const ROLE_PERMISSIONS: Record<Role, Permission[]> = {
  [Role.SUPER_ADMIN]: [
    // All permissions - Super Admin has everything
    ...Object.values(Permission)
  ],
  
  [Role.ADMIN]: [
    // Template Management
    Permission.TEMPLATE_CREATE,
    Permission.TEMPLATE_EDIT,
    Permission.TEMPLATE_DELETE,
    Permission.TEMPLATE_PUBLISH,
    Permission.TEMPLATE_VIEW,
    
    // Project Management
    Permission.PROJECT_CREATE,
    Permission.PROJECT_EDIT,
    Permission.PROJECT_DELETE,
    Permission.PROJECT_VIEW,
    Permission.PROJECT_ASSIGN_OPERATORS,
    
    // Compliance & Analytics
    Permission.COMPLIANCE_VIEW,
    Permission.COMPLIANCE_EDIT,
    Permission.ANALYTICS_VIEW,
    Permission.ANALYTICS_EXPORT,
    
    // User Management (limited)
    Permission.USER_VIEW,
    Permission.USER_EDIT,
    
    // Data Management
    Permission.DATA_EXPORT,
    Permission.DATA_IMPORT,
    
    // Log Operations
    Permission.LOG_CREATE,
    Permission.LOG_EDIT,
    Permission.LOG_VIEW,
    Permission.LOG_SUBMIT
  ],
  
  [Role.MANAGER]: [
    // Template Management (view and edit only)
    Permission.TEMPLATE_EDIT,
    Permission.TEMPLATE_VIEW,
    
    // Project Management
    Permission.PROJECT_CREATE,
    Permission.PROJECT_EDIT,
    Permission.PROJECT_VIEW,
    Permission.PROJECT_ASSIGN_OPERATORS,
    
    // Compliance & Analytics
    Permission.COMPLIANCE_VIEW,
    Permission.ANALYTICS_VIEW,
    Permission.ANALYTICS_EXPORT,
    
    // User Management (view only)
    Permission.USER_VIEW,
    
    // Data Management (export only)
    Permission.DATA_EXPORT,
    
    // Log Operations
    Permission.LOG_CREATE,
    Permission.LOG_EDIT,
    Permission.LOG_VIEW,
    Permission.LOG_SUBMIT
  ],
  
  [Role.VIEWER]: [
    // Read-only access
    Permission.TEMPLATE_VIEW,
    Permission.PROJECT_VIEW,
    Permission.COMPLIANCE_VIEW,
    Permission.ANALYTICS_VIEW,
    Permission.USER_VIEW,
    Permission.LOG_VIEW
  ],
  
  [Role.OPERATOR]: [
    // Operator-specific permissions for mobile app
    Permission.LOG_CREATE,
    Permission.LOG_EDIT,
    Permission.LOG_VIEW,
    Permission.LOG_SUBMIT,
    Permission.PROJECT_VIEW,
    Permission.TEMPLATE_VIEW
  ]
};

export const ROLE_HIERARCHY: Record<Role, Role[]> = {
  [Role.SUPER_ADMIN]: [], // No inheritance needed - has all permissions
  [Role.ADMIN]: [Role.MANAGER, Role.VIEWER],
  [Role.MANAGER]: [Role.VIEWER],
  [Role.VIEWER]: [],
  [Role.OPERATOR]: []
};

export function getRolePermissions(role: Role): Permission[] {
  const directPermissions = ROLE_PERMISSIONS[role] || [];
  const inheritedRoles = ROLE_HIERARCHY[role] || [];
  
  const inheritedPermissions = inheritedRoles.reduce((acc, inheritedRole) => {
    return [...acc, ...getRolePermissions(inheritedRole)];
  }, [] as Permission[]);
  
  // Remove duplicates
  return Array.from(new Set([...directPermissions, ...inheritedPermissions]));
}

export function hasPermission(userRoles: Role[], requiredPermission: Permission): boolean {
  for (const role of userRoles) {
    const rolePermissions = getRolePermissions(role);
    if (rolePermissions.includes(requiredPermission)) {
      return true;
    }
  }
  return false;
}

export function hasAnyPermission(userRoles: Role[], requiredPermissions: Permission[]): boolean {
  return requiredPermissions.some(permission => hasPermission(userRoles, permission));
}

export function hasAllPermissions(userRoles: Role[], requiredPermissions: Permission[]): boolean {
  return requiredPermissions.every(permission => hasPermission(userRoles, permission));
}