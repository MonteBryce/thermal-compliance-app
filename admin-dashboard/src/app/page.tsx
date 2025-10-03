'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { onAuthStateChanged } from 'firebase/auth';
import { auth } from '@/lib/firebase';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Thermometer, Settings, FileText, Loader2 } from 'lucide-react';
import Link from 'next/link';

export default function Home() {
  const router = useRouter();
  
  // Development bypass
  const isDevelopment = process.env.NODE_ENV === 'development';

  useEffect(() => {
    // Skip Firebase auth in development
    if (isDevelopment) {
      return;
    }

    try {
      const unsubscribe = onAuthStateChanged(auth, (user) => {
        if (user) {
          // User is signed in, redirect to admin
          router.push('/admin/jobs');
        }
      });

      return () => unsubscribe();
    } catch (error) {
      console.error('Firebase auth error:', error);
    }
  }, [router, isDevelopment]);

  return (
    <div className="min-h-screen bg-[#111111]">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16">
        {/* Header */}
        <div className="text-center mb-16">
          <div className="flex justify-center mb-6">
            <Thermometer className="h-16 w-16 text-blue-400" />
          </div>
          <h1 className="text-4xl font-bold text-white mb-4">
            Thermal Log Compliance System
          </h1>
          <p className="text-xl text-gray-300 max-w-3xl mx-auto">
            Comprehensive thermal logging management platform for marine operations
          </p>
        </div>

        {/* Features */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mb-12">
          <Card className="bg-[#1E1E1E] border-gray-800">
            <CardHeader>
              <Settings className="h-8 w-8 text-blue-400 mb-2" />
              <CardTitle className="text-white">Job Management</CardTitle>
              <CardDescription className="text-gray-300">
                Create and manage thermal logging jobs with template assignments
              </CardDescription>
            </CardHeader>
            <CardContent>
              <ul className="text-sm text-gray-300 space-y-1">
                <li>• Project setup and configuration</li>
                <li>• Template assignment workflow</li>
                <li>• Status tracking and monitoring</li>
              </ul>
            </CardContent>
          </Card>

          <Card className="bg-[#1E1E1E] border-gray-800">
            <CardHeader>
              <FileText className="h-8 w-8 text-green-400 mb-2" />
              <CardTitle className="text-white">Log Builder</CardTitle>
              <CardDescription className="text-gray-300">
                Advanced template system with Excel integration
              </CardDescription>
            </CardHeader>
            <CardContent>
              <ul className="text-sm text-gray-300 space-y-1">
                <li>• 16 thermal logging templates</li>
                <li>• Dynamic field configuration</li>
                <li>• Version control and audit trail</li>
              </ul>
            </CardContent>
          </Card>

          <Card className="bg-[#1E1E1E] border-gray-800">
            <CardHeader>
              <Thermometer className="h-8 w-8 text-orange-500 mb-2" />
              <CardTitle className="text-white">Compliance</CardTitle>
              <CardDescription className="text-gray-300">
                Ensure regulatory compliance with automated reporting
              </CardDescription>
            </CardHeader>
            <CardContent>
              <ul className="text-sm text-gray-300 space-y-1">
                <li>• Automated compliance checking</li>
                <li>• Export capabilities</li>
                <li>• Historical data analysis</li>
              </ul>
            </CardContent>
          </Card>
        </div>

        {/* Call to Action */}
        <div className="text-center">
          <Card className="max-w-lg mx-auto bg-[#1E1E1E] border-gray-800">
            <CardHeader>
              <CardTitle className="text-white">Access Admin Dashboard</CardTitle>
              <CardDescription className="text-gray-300">
                Sign in to manage thermal logging operations
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <Button asChild className="w-full bg-orange-600 hover:bg-orange-700 text-white border-0" size="lg">
                <Link href="/login">
                  Sign In to Dashboard
                </Link>
              </Button>
              
              {isDevelopment && (
                <Button asChild variant="secondary" className="w-full" size="lg">
                  <Link href="/admin">
                    🚧 Skip to Admin (Development)
                  </Link>
                </Button>
              )}
              
              <div className="text-sm text-gray-400">
                <p>Demo Credentials Available</p>
              </div>
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}