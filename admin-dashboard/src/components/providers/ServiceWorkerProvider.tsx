'use client';

import { useEffect } from 'react';
import { registerServiceWorker } from '@/lib/cache/service-worker-registration';

export function ServiceWorkerProvider({ children }: { children: React.ReactNode }) {
  useEffect(() => {
    if (process.env.NODE_ENV === 'production') {
      registerServiceWorker();
    }
  }, []);

  return <>{children}</>;
}