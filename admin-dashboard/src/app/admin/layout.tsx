import { Suspense } from 'react';
import { AdminNavigation } from './_components/AdminNavigation';
import { AuthGuard } from '@/components/auth/AuthGuard';

export default function AdminLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <AuthGuard requireAdmin={true}>
      <div className="min-h-screen bg-[#111111] text-white">
        <AdminNavigation />
        <Suspense fallback={
          <div className="flex items-center justify-center p-8 sm:p-12 min-h-[50vh]">
            <div className="flex flex-col items-center gap-3">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-orange-500"></div>
              <div className="text-gray-400 text-sm">Loading...</div>
            </div>
          </div>
        }>
          <main className="pb-6 sm:pb-8">
            {children}
          </main>
        </Suspense>
      </div>
    </AuthGuard>
  );
}