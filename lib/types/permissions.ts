export enum Role {
  SUPER_ADMIN = 'super_admin',
  ADMIN = 'admin',
  MANAGER = 'manager',
  VIEWER = 'viewer',
  OPERATOR = 'operator'
}

export enum Permission {
  // Template Management
  TEMPLATE_CREATE = 'template:create',
  TEMPLATE_EDIT = 'template:edit',
  TEMPLATE_DELETE = 'template:delete',
  TEMPLATE_PUBLISH = 'template:publish',
  TEMPLATE_VIEW = 'template:view',
  
  // Project Management
  PROJECT_CREATE = 'project:create',
  PROJECT_EDIT = 'project:edit',
  PROJECT_DELETE = 'project:delete',
  PROJECT_VIEW = 'project:view',
  PROJECT_ASSIGN_OPERATORS = 'project:assign_operators',
  
  // Compliance & Analytics
  COMPLIANCE_VIEW = 'compliance:view',
  COMPLIANCE_EDIT = 'compliance:edit',
  ANALYTICS_VIEW = 'analytics:view',
  ANALYTICS_EXPORT = 'analytics:export',
  
  // User Management
  USER_CREATE = 'user:create',
  USER_EDIT = 'user:edit',
  USER_DELETE = 'user:delete',
  USER_VIEW = 'user:view',
  USER_ASSIGN_ROLES = 'user:assign_roles',
  
  // System Administration
  SYSTEM_SETTINGS = 'system:settings',
  SYSTEM_BACKUP = 'system:backup',
  SYSTEM_LOGS = 'system:logs',
  
  // Data Management
  DATA_EXPORT = 'data:export',
  DATA_IMPORT = 'data:import',
  DATA_DELETE = 'data:delete',
  
  // Log Operations (for operators)
  LOG_CREATE = 'log:create',
  LOG_EDIT = 'log:edit',
  LOG_VIEW = 'log:view',
  LOG_SUBMIT = 'log:submit'
}

export interface UserRole {
  role: Role;
  permissions: Permission[];
  inheritedRoles?: Role[];
}

export interface UserPermissions {
  userId: string;
  email: string;
  roles: Role[];
  permissions: Permission[];
  customPermissions?: Permission[];
  deniedPermissions?: Permission[];
}