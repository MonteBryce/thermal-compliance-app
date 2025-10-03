'use client';

import React, { createContext, useContext, useEffect, useState } from 'react';
import { User } from 'firebase/auth';
import { 
  onAuthStateChange, 
  signIn as authSignIn, 
  signOut as authSignOut, 
  signUp as authSignUp,
  resetPassword as authResetPassword,
  isAdmin as checkIsAdmin 
} from '@/lib/auth';
import { 
  getUserRoles, 
  getUserPermissions, 
  canAccessAdminPanel,
  isAdmin as checkIsAdminNew
} from '@/lib/auth/permissions';
import { Role, Permission } from '@/lib/types/permissions';
import { useRouter } from 'next/navigation';

interface AuthContextType {
  user: User | null;
  isLoading: boolean;
  isAdmin: boolean;
  roles: Role[];
  permissions: Permission[];
  canAccess: (permission: Permission) => boolean;
  hasRole: (role: Role) => boolean;
  signIn: (email: string, password: string) => Promise<void>;
  signUp: (email: string, password: string, displayName?: string) => Promise<void>;
  signOut: () => Promise<void>;
  resetPassword: (email: string) => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isAdmin, setIsAdmin] = useState(false);
  const [roles, setRoles] = useState<Role[]>([]);
  const [permissions, setPermissions] = useState<Permission[]>([]);
  const router = useRouter();

  useEffect(() => {
    const unsubscribe = onAuthStateChange(async (user) => {
      setUser(user);
      
      if (user) {
        // Load custom claims for permissions
        try {
          const idTokenResult = await user.getIdTokenResult();
          (user as any).customClaims = idTokenResult.claims;
        } catch (error) {
          console.error('Error loading custom claims:', error);
        }
        
        const userRoles = getUserRoles(user);
        const userPermissions = getUserPermissions(user);
        const adminStatus = checkIsAdminNew(user);
        
        setRoles(userRoles);
        setPermissions(userPermissions);
        setIsAdmin(adminStatus);
      } else {
        setRoles([]);
        setPermissions([]);
        setIsAdmin(false);
      }
      
      setIsLoading(false);
    });

    return () => unsubscribe();
  }, []);

  const signIn = async (email: string, password: string) => {
    try {
      await authSignIn(email, password);
    } catch (error) {
      console.error('Sign in error:', error);
      throw error;
    }
  };

  const signUp = async (email: string, password: string, displayName?: string) => {
    try {
      await authSignUp(email, password, displayName);
    } catch (error) {
      console.error('Sign up error:', error);
      throw error;
    }
  };

  const signOut = async () => {
    try {
      await authSignOut();
      router.push('/login');
    } catch (error) {
      console.error('Sign out error:', error);
      throw error;
    }
  };

  const resetPassword = async (email: string) => {
    try {
      await authResetPassword(email);
    } catch (error) {
      console.error('Reset password error:', error);
      throw error;
    }
  };

  const canAccess = (permission: Permission): boolean => {
    return permissions.includes(permission);
  };

  const hasRole = (role: Role): boolean => {
    return roles.includes(role);
  };

  const value: AuthContextType = {
    user,
    isLoading,
    isAdmin,
    roles,
    permissions,
    canAccess,
    hasRole,
    signIn,
    signUp,
    signOut,
    resetPassword,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}

export function useRequireAuth(redirectTo = '/login') {
  const { user, isLoading } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (!isLoading && !user) {
      router.push(redirectTo);
    }
  }, [user, isLoading, router, redirectTo]);

  return { user, isLoading };
}

export function useRequireAdmin(redirectTo = '/unauthorized') {
  const { user, isAdmin, isLoading } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (!isLoading) {
      if (!user) {
        router.push('/login');
      } else if (!isAdmin) {
        router.push(redirectTo);
      }
    }
  }, [user, isAdmin, isLoading, router, redirectTo]);

  return { user, isAdmin, isLoading };
}