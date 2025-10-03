'use client';

import { useState, useEffect } from 'react';
import { useAuth } from '@/lib/contexts/AuthContext';
import { Permission, Role } from '@/lib/types/permissions';
import { PermissionGuard, SuperAdminOnly } from '@/components/auth/PermissionGuard';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Users, Shield, Settings, Eye } from 'lucide-react';

interface UserData {
  uid: string;
  email: string;
  displayName?: string;
  disabled: boolean;
  emailVerified: boolean;
  customClaims: any;
  metadata: {
    creationTime: string;
    lastSignInTime?: string;
  };
}

export default function UsersPage() {
  const { canAccess, roles, permissions } = useAuth();
  const [users, setUsers] = useState<UserData[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    // Simulate loading demo users for permission testing
    setLoading(false);
    setUsers([
      {
        uid: 'demo-1',
        email: 'admin@example.com',
        displayName: 'Admin User',
        disabled: false,
        emailVerified: true,
        customClaims: { role: Role.ADMIN },
        metadata: {
          creationTime: new Date().toISOString(),
          lastSignInTime: new Date().toISOString()
        }
      },
      {
        uid: 'demo-2',
        email: 'manager@example.com',
        displayName: 'Manager User',
        disabled: false,
        emailVerified: true,
        customClaims: { role: Role.MANAGER },
        metadata: {
          creationTime: new Date().toISOString(),
        }
      }
    ]);
  }, []);

  const getRoleBadgeColor = (role: string) => {
    switch (role) {
      case Role.SUPER_ADMIN: return 'bg-red-600';
      case Role.ADMIN: return 'bg-blue-600';
      case Role.MANAGER: return 'bg-green-600';
      case Role.VIEWER: return 'bg-gray-600';
      case Role.OPERATOR: return 'bg-yellow-600';
      default: return 'bg-gray-500';
    }
  };

  if (!canAccess(Permission.USER_VIEW)) {
    return (
      <div className="p-8">
        <Card>
          <CardHeader>
            <CardTitle className="text-red-400">Access Denied</CardTitle>
            <CardDescription>
              You don't have permission to view user management.
            </CardDescription>
          </CardHeader>
          <CardContent>
            <p className="text-gray-400">Current permissions: {permissions.length}</p>
            <p className="text-gray-400">Current roles: {roles.join(', ')}</p>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="p-8">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-white">User Management</h1>
        <p className="text-gray-400 mt-2">
          Manage user accounts and permissions
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        {/* Current User Info */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Eye className="h-5 w-5" />
              Your Access Level
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              <div>
                <span className="text-sm text-gray-400">Roles:</span>
                <div className="flex gap-1 mt-1">
                  {roles.map(role => (
                    <Badge key={role} className={getRoleBadgeColor(role)}>
                      {role.replace('_', ' ')}
                    </Badge>
                  ))}
                </div>
              </div>
              <div>
                <span className="text-sm text-gray-400">Permissions:</span>
                <span className="ml-2 text-white">{permissions.length}</span>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Permission Checks */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Shield className="h-5 w-5" />
              Your Capabilities
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-1 text-sm">
              <div className="flex justify-between">
                <span>View Users:</span>
                <span className={canAccess(Permission.USER_VIEW) ? 'text-green-400' : 'text-red-400'}>
                  {canAccess(Permission.USER_VIEW) ? '✓' : '✗'}
                </span>
              </div>
              <div className="flex justify-between">
                <span>Create Users:</span>
                <span className={canAccess(Permission.USER_CREATE) ? 'text-green-400' : 'text-red-400'}>
                  {canAccess(Permission.USER_CREATE) ? '✓' : '✗'}
                </span>
              </div>
              <div className="flex justify-between">
                <span>Edit Users:</span>
                <span className={canAccess(Permission.USER_EDIT) ? 'text-green-400' : 'text-red-400'}>
                  {canAccess(Permission.USER_EDIT) ? '✓' : '✗'}
                </span>
              </div>
              <div className="flex justify-between">
                <span>Assign Roles:</span>
                <span className={canAccess(Permission.USER_ASSIGN_ROLES) ? 'text-green-400' : 'text-red-400'}>
                  {canAccess(Permission.USER_ASSIGN_ROLES) ? '✓' : '✗'}
                </span>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Actions */}
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Settings className="h-5 w-5" />
              Actions
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              <PermissionGuard permissions={Permission.USER_CREATE}>
                <Button className="w-full" size="sm">
                  Create User
                </Button>
              </PermissionGuard>
              <SuperAdminOnly>
                <Button variant="outline" className="w-full" size="sm">
                  System Settings
                </Button>
              </SuperAdminOnly>
              <Button 
                variant="outline" 
                className="w-full" 
                size="sm"
                disabled={true}
              >
                Demo Mode
              </Button>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Users List */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Users className="h-5 w-5" />
            Users ({users.length})
          </CardTitle>
          <CardDescription>
            All users in the system
          </CardDescription>
        </CardHeader>
        <CardContent>
          {loading ? (
            <p className="text-gray-400">Loading users...</p>
          ) : error ? (
            <p className="text-red-400">Error: {error}</p>
          ) : (
            <div className="space-y-4">
              {users.map(user => (
                <div key={user.uid} className="flex items-center justify-between p-4 bg-gray-800 rounded-lg">
                  <div className="flex-1">
                    <div className="flex items-center gap-3">
                      <div>
                        <p className="font-medium text-white">{user.email}</p>
                        {user.displayName && (
                          <p className="text-sm text-gray-400">{user.displayName}</p>
                        )}
                      </div>
                      <div className="flex gap-1">
                        {user.customClaims?.roles?.map((role: string) => (
                          <Badge key={role} className={getRoleBadgeColor(role)} variant="secondary">
                            {role.replace('_', ' ')}
                          </Badge>
                        )) || (
                          user.customClaims?.role && (
                            <Badge className={getRoleBadgeColor(user.customClaims.role)} variant="secondary">
                              {user.customClaims.role.replace('_', ' ')}
                            </Badge>
                          )
                        )}
                      </div>
                    </div>
                    <div className="flex gap-4 text-xs text-gray-500 mt-1">
                      <span>Created: {new Date(user.metadata.creationTime).toLocaleDateString()}</span>
                      {user.metadata.lastSignInTime && (
                        <span>Last Sign In: {new Date(user.metadata.lastSignInTime).toLocaleDateString()}</span>
                      )}
                      <span className={user.emailVerified ? 'text-green-400' : 'text-yellow-400'}>
                        {user.emailVerified ? 'Verified' : 'Unverified'}
                      </span>
                      {user.disabled && <span className="text-red-400">Disabled</span>}
                    </div>
                  </div>
                  <div className="flex gap-2">
                    <PermissionGuard permissions={Permission.USER_EDIT}>
                      <Button variant="outline" size="sm">
                        Edit
                      </Button>
                    </PermissionGuard>
                    <PermissionGuard permissions={Permission.USER_ASSIGN_ROLES}>
                      <Button variant="outline" size="sm">
                        Roles
                      </Button>
                    </PermissionGuard>
                  </div>
                </div>
              ))}
              {users.length === 0 && !loading && (
                <p className="text-gray-400 text-center py-8">No users found</p>
              )}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}