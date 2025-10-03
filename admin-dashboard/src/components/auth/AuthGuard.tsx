'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@/lib/contexts/AuthContext';
import { Loader2 } from 'lucide-react';

interface AuthGuardProps {
  children: React.ReactNode;
  requireAdmin?: boolean;
  fallbackPath?: string;
}

export function AuthGuard({ 
  children, 
  requireAdmin = false,
  fallbackPath = '/login'
}: AuthGuardProps) {
  const { user, isAdmin, isLoading } = useAuth();
  const router = useRouter();
  const [isAuthorized, setIsAuthorized] = useState(false);

  // Development bypass - check for localhost or dev environment
  const isDevelopment = process.env.NODE_ENV === 'development' || 
                       (typeof window !== 'undefined' && 
                        (window.location.hostname === 'localhost' || 
                         window.location.hostname === '127.0.0.1'));

  useEffect(() => {
    // Skip authentication in development mode
    if (isDevelopment) {
      setIsAuthorized(true);
      return;
    }

    if (!isLoading) {
      if (!user) {
        router.push(fallbackPath);
      } else if (requireAdmin && !isAdmin) {
        router.push('/unauthorized');
      } else {
        setIsAuthorized(true);
      }
    }
  }, [user, isAdmin, isLoading, requireAdmin, router, fallbackPath, isDevelopment]);

  if (isLoading && !isDevelopment) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[#111111]">
        <div className="text-center">
          <Loader2 className="h-12 w-12 animate-spin text-orange-500 mx-auto" />
          <p className="mt-4 text-gray-400">Verifying authentication...</p>
        </div>
      </div>
    );
  }

  if (!isAuthorized) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[#111111]">
        <div className="text-center">
          <Loader2 className="h-12 w-12 animate-spin text-orange-500 mx-auto" />
          <p className="mt-4 text-gray-400">Redirecting...</p>
        </div>
      </div>
    );
  }

  return (
    <>
      {isDevelopment && (
        <div className="bg-yellow-600 text-yellow-50 px-4 py-2 text-center text-sm">
          🚧 Development Mode - Authentication Bypassed
        </div>
      )}
      {children}
    </>
  );
}