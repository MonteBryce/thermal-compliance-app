'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';

export default function SimpleAdminRedirect() {
  const router = useRouter();

  useEffect(() => {
    // Redirect to the new unified project portal
    router.replace('/admin/PROJ-001');
  }, [router]);

  return (
    <div className="min-h-screen bg-[#111111] flex items-center justify-center">
      <div className="text-center">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-orange-500 mx-auto mb-4"></div>
        <p className="text-gray-300">Redirecting to Project Portal...</p>
      </div>
    </div>
  );
}